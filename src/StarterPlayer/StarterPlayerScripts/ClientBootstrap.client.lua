local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local combatRemote = remotes:WaitForChild("CombatRequest")
local crystalChanged = remotes:WaitForChild("CrystalChanged")
local inventoryRequest = remotes:WaitForChild("InventoryRequest")
local getQuestData = remotes:WaitForChild("GetQuestData")
local xpChanged = remotes:WaitForChild("XPChanged")
local moneyChanged = remotes:WaitForChild("MoneyChanged")
local crystalMasteryChanged = remotes:WaitForChild("CrystalMasteryChanged")
local levelUp = remotes:WaitForChild("LevelUp")
local inventoryChanged = remotes:WaitForChild("InventoryChanged")
local crystalUpgradeRequest = remotes:WaitForChild("CrystalUpgradeRequest")
local crystalConfig = require(ReplicatedStorage.Config.CrystalConfig)
local shopConfig = require(ReplicatedStorage.Config.ShopConfig)
local crystalAnimationController = require(script.Parent:WaitForChild("CrystalAnimationController"))
local crystalVFXController = require(script.Parent:WaitForChild("CrystalVFXController"))

local crystalOrder = {}
for crystalId in pairs(crystalConfig.Definitions or {}) do
	table.insert(crystalOrder, crystalId)
end
table.sort(crystalOrder, function(left, right)
	return (tonumber(crystalConfig.UnlockLevels[left]) or math.huge) < (tonumber(crystalConfig.UnlockLevels[right]) or math.huge)
end)
local sellOrder = shopConfig.SellOrder or {}
local inventory = {}
local questRefreshBusy = false
local questRefreshQueued = false
local questRefreshGeneration = 0
local lastBossRefresh = 0
local BOSS_REFRESH_INTERVAL = 0.1
local localAbilityReadyAt = 0

local function ensureHud()
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = playerGui:FindFirstChild("CrystalBoundHUD")
	if gui then return gui end

	gui = Instance.new("ScreenGui")
	gui.Name = "CrystalBoundHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0, 0)
	panel.Position = UDim2.fromOffset(18, 18)
	panel.Size = UDim2.fromOffset(330, 160)
	panel.BackgroundTransparency = 0.18
	panel.Parent = gui
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

	local function label(name, position, size)
		local item = Instance.new("TextLabel")
		item.Name = name
		item.Position = position
		item.Size = size
		item.BackgroundTransparency = 1
		item.Font = Enum.Font.GothamBold
		item.TextSize = 14
		item.TextXAlignment = Enum.TextXAlignment.Left
		item.Parent = panel
		return item
	end

	label("Stats", UDim2.fromOffset(12, 10), UDim2.fromOffset(306, 62))
	label("Mastery", UDim2.fromOffset(12, 74), UDim2.fromOffset(306, 26))
	label("Progress", UDim2.fromOffset(12, 102), UDim2.fromOffset(306, 22))
	label("Cooldown", UDim2.fromOffset(12, 126), UDim2.fromOffset(306, 22))
	label("Inventory", UDim2.fromOffset(360, 10), UDim2.fromOffset(260, 140))
	label("Quest", UDim2.new(0, 18, 1, -80), UDim2.fromOffset(480, 44))

	local boss = Instance.new("Frame")
	boss.Name = "BossBar"
	boss.AnchorPoint = Vector2.new(0.5, 0)
	boss.Position = UDim2.new(0.5, 0, 0, 18)
	boss.Size = UDim2.fromOffset(420, 58)
	boss.BackgroundTransparency = 0.2
	boss.Visible = false
	boss.Parent = gui
	Instance.new("UICorner", boss).CornerRadius = UDim.new(0, 10)

	local bossName = Instance.new("TextLabel")
	bossName.Name = "Name"
	bossName.Position = UDim2.fromOffset(10, 5)
	bossName.Size = UDim2.new(1, -20, 0, 20)
	bossName.BackgroundTransparency = 1
	bossName.Font = Enum.Font.GothamBold
	bossName.TextSize = 15
	bossName.Parent = boss

	local hpBack = Instance.new("Frame")
	hpBack.Name = "HPBack"
	hpBack.Position = UDim2.fromOffset(10, 29)
	hpBack.Size = UDim2.new(1, -20, 0, 20)
	hpBack.Parent = boss
	Instance.new("UICorner", hpBack).CornerRadius = UDim.new(0, 6)

	local hpFill = Instance.new("Frame")
	hpFill.Name = "HPFill"
	hpFill.Size = UDim2.fromScale(1, 1)
	hpFill.Parent = hpBack
	Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0, 6)

	local hpText = Instance.new("TextLabel")
	hpText.Name = "HPText"
	hpText.Size = UDim2.fromScale(1, 1)
	hpText.BackgroundTransparency = 1
	hpText.Font = Enum.Font.GothamBold
	hpText.TextSize = 12
	hpText.Parent = hpBack

	return gui
end

local function getEquippedCrystal()
	local crystalId = player:GetAttribute("EquippedCrystal")
	if type(crystalId) ~= "string" or not crystalConfig.Abilities[crystalId] then return "EMBER" end
	return crystalId
end

local function getTargetRange(action)
	local crystalId = getEquippedCrystal()
	local config = action == "Ability" and crystalConfig.Abilities[crystalId] or crystalConfig.BasicAttack[crystalId]
	return config and tonumber(config.Range) or nil
end

local function getTargetFromMouse()
	local mouse = player:GetMouse()
	local target = mouse.Target
	if not target then return nil end
	local model = target:FindFirstAncestorOfClass("Model")
	if not model or model:GetAttribute("Enemy") ~= true then return nil end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return nil end
	return model
end

local function canPresentCombat(action, target)
	local crystalId = getEquippedCrystal()
	if action == "Ability" and crystalId == "TIDE" then
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 or humanoid.Health >= humanoid.MaxHealth then return false end
	else
		local range = getTargetRange(action)
		if not target or not range or range <= 0 then return false end
		local character = player.Character
		local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
		local targetRoot = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
		if not playerRoot or not targetRoot then return false end
		if (playerRoot.Position - targetRoot.Position).Magnitude > range then return false end
	end

	if action == "Ability" then
		local now = os.clock()
		local cooldownEnd = tonumber(player:GetAttribute("AbilityCooldownEnd")) or 0
		if now < math.max(cooldownEnd, localAbilityReadyAt) then return false end
		local cooldown = tonumber(crystalConfig.Abilities[crystalId].Cooldown) or 0
		localAbilityReadyAt = now + math.max(0, cooldown)
	end
	return true
end

local function refreshHud()
	local gui = ensureHud()
	local panel = gui:FindFirstChild("Panel")
	if not panel then return end
	local level = player:GetAttribute("Level") or 1
	local money = player:GetAttribute("Money") or 0
	local crystal = getEquippedCrystal()
	local masteryLevel = player:GetAttribute("CrystalMasteryLevel") or 1
	local masteryXP = player:GetAttribute("CrystalMasteryXP") or 0
	local achievementCount = player:GetAttribute("AchievementCount") or 0
	local title = player:GetAttribute("Title") or ""
	local crystalConfigEntry = crystalConfig.Abilities[crystal]
	panel.Stats.Text = string.format("Level %d  •  Money %d\nCrystal: %s\nMastery: Lv.%d  XP %d\nAchievements: %d  •  Title: %s", level, money, crystal, masteryLevel, masteryXP, achievementCount, title ~= "" and title or "None")
	panel.Mastery.Text = string.format("Ability: %s  •  Cooldown baseline %.1fs", crystalConfigEntry and crystalConfigEntry.Name or "Ability", crystalConfigEntry and crystalConfigEntry.Cooldown or 0)
	panel.Progress.Text = string.format("Inventory items: %d", inventory and (function()
		local count = 0
		for _, amount in pairs(inventory) do count += tonumber(amount) or 0 end
		return count
	end)() or 0)
	local cooldownLabel = panel:FindFirstChild("Cooldown")
	if cooldownLabel then
		local endTime = tonumber(player:GetAttribute("AbilityCooldownEnd")) or 0
		local remaining = math.max(0, endTime - os.clock())
		cooldownLabel.Text = remaining > 0 and string.format("Q Ability: %.1fs", remaining) or string.format("Q Ability: READY • %s", crystalConfigEntry and crystalConfigEntry.Name or "Ability")
	end
	local inv = panel:FindFirstChild("Inventory")
	if inv then
		local lines = {}
		for _, itemId in ipairs(sellOrder) do
			local amount = tonumber(inventory[itemId]) or 0
			table.insert(lines, itemId .. ": " .. tostring(amount))
		end
		inv.Text = table.concat(lines, "\n")
	end
end

local function refreshQuests()
	if questRefreshBusy then return end
	questRefreshBusy = true
	local requestGeneration = questRefreshGeneration
	local requestCharacter = player.Character
	local ok, result = pcall(function() return getQuestData:InvokeServer() end)
	questRefreshBusy = false
	if not ok or type(result) ~= "table" then return end
	if not player.Parent or questRefreshGeneration ~= requestGeneration or player.Character ~= requestCharacter then return end
	if player:GetAttribute("ProfileLoaded") ~= true then return end
	local gui = ensureHud()
	local quest = gui:FindFirstChild("Quest")
	if not quest then return end

	local active = type(result.Active) == "table" and result.Active or {}
	local activeQuestId = active[1]
	if type(activeQuestId) ~= "string" then
		quest.Text = "Quest: none active"
		return
	end
	local definitions = type(result.Definitions) == "table" and result.Definitions or {}
	local definition = definitions[activeQuestId]
	local progressTable = type(result.Progress) == "table" and result.Progress or {}
	local progress = math.max(0, math.floor(tonumber(progressTable[activeQuestId]) or 0))
	local goal = definition and math.max(1, math.floor(tonumber(definition.Goal) or 1)) or math.max(1, progress)
	local name = definition and definition.Name or activeQuestId
	quest.Text = string.format("Quest: %s  •  %d/%d", name, progress, goal)
end

local function scheduleQuestRefresh()
	if questRefreshQueued or questRefreshBusy then return end
	questRefreshQueued = true
	local queuedGeneration = questRefreshGeneration
	task.delay(0.1, function()
		questRefreshQueued = false
		if player.Parent and questRefreshGeneration == queuedGeneration then refreshQuests() end
	end)
end

local function refreshBoss()
	local now = os.clock()
	if now - lastBossRefresh < BOSS_REFRESH_INTERVAL then return end
	lastBossRefresh = now
	local gui = ensureHud()
	local bossBar = gui:FindFirstChild("BossBar")
	if not bossBar then return end
	local npcFolder = workspace:FindFirstChild("NPCs")
	local boss = npcFolder and npcFolder:FindFirstChild("CrystalGuardian")
	if not boss then bossBar.Visible = false return end
	local humanoid = boss:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then bossBar.Visible = false return end
	bossBar.Visible = true
	local phase = boss:GetAttribute("BossPhase") or 1
	bossBar.Name.Text = string.format("Crystal Guardian  •  Phase %d", phase)
	local ratio = math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1)
	bossBar.HPBack.HPFill.Size = UDim2.fromScale(ratio, 1)
	bossBar.HPBack.HPText.Text = string.format("%d / %d HP", math.max(0, math.floor(humanoid.Health)), math.floor(humanoid.MaxHealth))
end

for _, attribute in ipairs({ "ProfileLoaded", "Level", "Experience", "Money", "EquippedCrystal", "CrystalMasteryLevel", "CrystalMasteryXP", "AchievementCount", "Title" }) do
	player:GetAttributeChangedSignal(attribute):Connect(function()
		refreshHud()
		scheduleQuestRefresh()
	end)
end

xpChanged.OnClientEvent:Connect(function() refreshHud(); scheduleQuestRefresh() end)
moneyChanged.OnClientEvent:Connect(function() refreshHud(); scheduleQuestRefresh() end)
crystalMasteryChanged.OnClientEvent:Connect(function(crystalId, level, xp)
	if crystalId == player:GetAttribute("EquippedCrystal") then
		player:SetAttribute("CrystalMasteryLevel", level or 1)
		player:SetAttribute("CrystalMasteryXP", xp or 0)
	end
	refreshHud()
end)
levelUp.OnClientEvent:Connect(function(level)
	player:SetAttribute("QuestMessage", string.format("Level Up! Level %d", tonumber(level) or (player:GetAttribute("Level") or 1)))
	refreshHud(); scheduleQuestRefresh()
end)
inventoryChanged.OnClientEvent:Connect(function(data) inventory = type(data) == "table" and data or {}; refreshHud() end)

player.CharacterAdded:Connect(function()
	questRefreshGeneration += 1
	questRefreshQueued = false
	task.defer(function()
		if player.Parent then refreshQuests() end
	end)
end)

refreshHud()
refreshQuests()
inventoryRequest:FireServer()

player:GetMouse().Button1Down:Connect(function()
	local target = getTargetFromMouse()
	if target and canPresentCombat("Basic", target) then
		local crystal = getEquippedCrystal()
		crystalAnimationController.Play("Basic", crystal)
		crystalVFXController.Play("Basic", crystal)
		combatRemote:FireServer("Basic", target)
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Q then
		local crystal = getEquippedCrystal()
		local target = getTargetFromMouse()
		if crystal == "TIDE" then
			if canPresentCombat("Ability", nil) then
				crystalAnimationController.Play("Ability", crystal)
				crystalVFXController.Play("Ability", crystal)
				combatRemote:FireServer("Ability", nil)
			end
		elseif target and canPresentCombat("Ability", target) then
			crystalAnimationController.Play("Ability", crystal)
			crystalVFXController.Play("Ability", crystal)
			combatRemote:FireServer("Ability", target)
		end
	elseif input.KeyCode == Enum.KeyCode.Z then crystalChanged:FireServer(crystalOrder[1])
	elseif input.KeyCode == Enum.KeyCode.X then crystalChanged:FireServer(crystalOrder[2])
	elseif input.KeyCode == Enum.KeyCode.C then crystalChanged:FireServer(crystalOrder[3])
	elseif input.KeyCode == Enum.KeyCode.E then inventoryRequest:FireServer(); refreshQuests()
	elseif input.KeyCode == Enum.KeyCode.Four then inventoryRequest:FireServer("Sell", sellOrder[1], 1)
	elseif input.KeyCode == Enum.KeyCode.Five then inventoryRequest:FireServer("Sell", sellOrder[2], 1)
	elseif input.KeyCode == Enum.KeyCode.Six then inventoryRequest:FireServer("Sell", sellOrder[3], 1)
	elseif input.KeyCode == Enum.KeyCode.Seven then inventoryRequest:FireServer("Sell", sellOrder[4], 1)
	elseif input.KeyCode == Enum.KeyCode.Eight then inventoryRequest:FireServer("Sell", sellOrder[5], 1)
	elseif input.KeyCode == Enum.KeyCode.U then crystalUpgradeRequest:FireServer(player:GetAttribute("EquippedCrystal") or "EMBER")
	end
end)

RunService.RenderStepped:Connect(refreshBoss)
print("Crystal Bound client ready")