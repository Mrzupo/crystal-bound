local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local combatRemote = remotes:WaitForChild("CombatRequest")
local crystalAnimationController = require(script.Parent:WaitForChild("CrystalAnimationController"))
local crystalVFXController = require(script.Parent:WaitForChild("CrystalVFXController"))
local crystalConfig = require(ReplicatedStorage.Config.CrystalConfig)
xpChanged = remotes:WaitForChild("XPChanged")
local levelUp = remotes:WaitForChild("LevelUp")
local moneyChanged = remotes:WaitForChild("MoneyChanged")
local inventoryChanged = remotes:WaitForChild("InventoryChanged")
local inventoryRequest = remotes:WaitForChild("InventoryRequest")
local crystalChanged = remotes:WaitForChild("CrystalChanged")
local crystalMasteryChanged = remotes:WaitForChild("CrystalMasteryChanged")
local crystalUpgradeRequest = remotes:WaitForChild("CrystalUpgradeRequest")
local getQuestData = remotes:WaitForChild("GetQuestData")

local inventory = {}
local crystalOrder = { "EMBER", "TIDE", "GALE" }
local sellOrder = { "EmberShard", "TidePearl", "GaleFeather", "GuardianCore", "AncientShard" }
local questRefreshQueued = false
local questRefreshBusy = false
local lastBossRefresh = 0
local BOSS_REFRESH_INTERVAL = 0.1
local localAbilityReadyAt = 0

local function getTargetFromMouse()
	local hit = player:GetMouse().Target
	if not hit then return nil end
	local target = hit:FindFirstAncestorOfClass("Model")
	if not target or target:GetAttribute("Enemy") ~= true then return nil end
	local humanoid = target:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return nil end
	return target
end

local function getEquippedCrystal()
	local crystalId = player:GetAttribute("EquippedCrystal")
	if type(crystalId) ~= "string" or not crystalConfig.Abilities[crystalId] then
		return "EMBER"
	end
	return crystalId
end

local function getCombatConfig(action)
	local crystalId = getEquippedCrystal()
	local group = action == "Ability" and crystalConfig.Abilities or crystalConfig.BasicAttacks
	return crystalId, group and group[crystalId]
end

local function canPresentCombat(action, target)
	if not target then return false end
	local crystalId, config = getCombatConfig(action)
	if not config then return false end
	local character = player.Character
	local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
	local targetRoot = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
	if not playerRoot or not targetRoot then return false end
	local range = tonumber(config.Range)
	if not range or range <= 0 then return false end
	if (playerRoot.Position - targetRoot.Position).Magnitude > range then return false end
	if action == "Ability" then
		local now = os.clock()
		local cooldownEnd = tonumber(player:GetAttribute("AbilityCooldownEnd")) or 0
		if now < math.max(cooldownEnd, localAbilityReadyAt) then return false end
		local cooldown = tonumber(config.Cooldown) or 0
		localAbilityReadyAt = now + math.max(0, cooldown)
	end
	return true
end

local function ensureHud()
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = playerGui:FindFirstChild("MainUI")
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "MainUI"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.Parent = playerGui
	end
	local panel = gui:FindFirstChild("Info")
	if not panel then
		panel = Instance.new("Frame")
		panel.Name = "Info"
		panel.Position = UDim2.fromOffset(16, 16)
		panel.Size = UDim2.fromOffset(430, 336)
		panel.BackgroundTransparency = 0.15
		panel.Parent = gui
		Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

		local stats = Instance.new("TextLabel")
		stats.Name = "Stats"
		stats.Position = UDim2.fromOffset(12, 10)
		stats.Size = UDim2.fromOffset(406, 95)
		stats.BackgroundTransparency = 1
		stats.TextXAlignment = Enum.TextXAlignment.Left
		stats.TextYAlignment = Enum.TextYAlignment.Top
		stats.TextWrapped = true
		stats.Font = Enum.Font.GothamMedium
		stats.TextSize = 18
		stats.Parent = panel

		local mastery = Instance.new("TextLabel")
		mastery.Name = "Mastery"
		mastery.Position = UDim2.fromOffset(12, 103)
		mastery.Size = UDim2.fromOffset(406, 42)
		mastery.BackgroundTransparency = 1
		mastery.TextXAlignment = Enum.TextXAlignment.Left
		mastery.TextYAlignment = Enum.TextYAlignment.Top
		mastery.TextWrapped = true
		mastery.Font = Enum.Font.GothamBold
		mastery.TextSize = 15
		mastery.Parent = panel

		local progress = Instance.new("TextLabel")
		progress.Name = "Progress"
		progress.Position = UDim2.fromOffset(12, 146)
		progress.Size = UDim2.fromOffset(406, 32)
		progress.BackgroundTransparency = 1
		progress.TextXAlignment = Enum.TextXAlignment.Left
		progress.Font = Enum.Font.Gotham
		progress.TextSize = 14
		progress.Parent = panel

		local cooldown = Instance.new("TextLabel")
		cooldown.Name = "Cooldown"
		cooldown.Position = UDim2.fromOffset(12, 178)
		cooldown.Size = UDim2.fromOffset(406, 34)
		cooldown.BackgroundTransparency = 1
		cooldown.TextXAlignment = Enum.TextXAlignment.Left
		cooldown.Font = Enum.Font.GothamBold
		cooldown.TextSize = 15
		cooldown.Parent = panel

		local inv = Instance.new("TextLabel")
		inv.Name = "Inventory"
		inv.Position = UDim2.fromOffset(12, 213)
		inv.Size = UDim2.fromOffset(406, 110)
		inv.BackgroundTransparency = 1
		inv.TextXAlignment = Enum.TextXAlignment.Left
		inv.TextYAlignment = Enum.TextYAlignment.Top
		inv.TextWrapped = true
		inv.Font = Enum.Font.Gotham
		inv.TextSize = 14
		inv.Parent = panel

		local quest = Instance.new("TextLabel")
		quest.Name = "Quest"
		quest.Position = UDim2.fromOffset(16, 350)
		quest.Size = UDim2.fromOffset(700, 160)
		quest.BackgroundTransparency = 0.15
		quest.TextXAlignment = Enum.TextXAlignment.Left
		quest.TextYAlignment = Enum.TextYAlignment.Top
		quest.TextWrapped = true
		quest.Font = Enum.Font.GothamMedium
		quest.TextSize = 16
		quest.Parent = gui
		Instance.new("UICorner", quest).CornerRadius = UDim.new(0, 10)

		local boss = Instance.new("Frame")
		boss.Name = "BossBar"
		boss.AnchorPoint = Vector2.new(0.5, 0)
		boss.Position = UDim2.new(0.5, 0, 0, 78)
		boss.Size = UDim2.fromOffset(620, 72)
		boss.BackgroundTransparency = 0.12
		boss.Visible = false
		boss.Parent = gui
		Instance.new("UICorner", boss).CornerRadius = UDim.new(0, 10)

		local bossName = Instance.new("TextLabel")
		bossName.Name = "Name"
		bossName.Position = UDim2.fromOffset(12, 6)
		bossName.Size = UDim2.fromOffset(596, 24)
		bossName.BackgroundTransparency = 1
		bossName.Font = Enum.Font.GothamBold
		bossName.TextSize = 18
		bossName.Parent = boss

		local hpBack = Instance.new("Frame")
		hpBack.Name = "HPBack"
		hpBack.Position = UDim2.fromOffset(12, 38)
		hpBack.Size = UDim2.fromOffset(596, 22)
		hpBack.BackgroundTransparency = 0.12
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
		hpText.TextSize = 13
		hpText.Parent = hpBack
	end
	return gui
end

local function refreshHud()
	local gui = ensureHud()
	local panel = gui:FindFirstChild("Info")
	if not panel then return end
	local level = player:GetAttribute("Level") or 1
	local money = player:GetAttribute("Money") or 0
	local crystal = player:GetAttribute("EquippedCrystal") or "EMBER"
	local masteryLevel = player:GetAttribute("CrystalMasteryLevel") or 1
	local masteryXP = player:GetAttribute("CrystalMasteryXP") or 0
	local achievementCount = player:GetAttribute("AchievementCount") or 0
	local title = player:GetAttribute("Title") or ""
	local required = 100
	local crystalConfigEntry = crystalConfig.Abilities[crystal]
	if crystalConfigEntry and crystalConfigEntry.Cooldown then required = math.floor(crystalConfigEntry.Cooldown * 100) end
	panel.Stats.Text = string.format("Level %d  •  Money %d\nCrystal: %s\nMastery: Lv.%d  XP %d\nAchievements: %d  •  Title: %s", level, money, crystal, masteryLevel, masteryXP, achievementCount, title ~= "" and title or "None")
	panel.Mastery.Text = string.format("Ability: %s  •  Cooldown baseline %.1fs", crystalConfigEntry and crystalConfigEntry.Name or "Ability", required / 100)
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
		for _, itemId in ipairs({ "EmberShard", "TidePearl", "GaleFeather", "GuardianCore", "AncientShard" }) do
			local amount = tonumber(inventory[itemId]) or 0
			table.insert(lines, itemId .. ": " .. tostring(amount))
		end
		inv.Text = table.concat(lines, "\n")
	end
end

local function scheduleQuestRefresh()
	if questRefreshQueued or questRefreshBusy then return end
	questRefreshQueued = true
	task.delay(0.1, function()
		questRefreshQueued = false
		if player.Parent then refreshQuests() end
	end)
end

function refreshQuests()
	if questRefreshBusy then return end
	questRefreshBusy = true
	local ok, result = pcall(function()
		return getQuestData:InvokeServer()
	end)
	questRefreshBusy = false
	if not ok or type(result) ~= "table" then return end
	local gui = ensureHud()
	local quest = gui:FindFirstChild("Quest")
	if quest then
		quest.Text = result.Text or ""
	end
end

local function refreshBoss()
	local now = os.clock()
	if now - lastBossRefresh < BOSS_REFRESH_INTERVAL then return end
	lastBossRefresh = now
	local gui = ensureHud()
	local bossBar = gui:FindFirstChild("BossBar")
	if not bossBar then return end
	local npcFolder = workspace:FindFirstChild("NPCs")
	local boss = npcFolder and npcFolder:FindFirstChild("Crystal Guardian")
	if not boss then bossBar.Visible = false return end
	local humanoid = boss:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		bossBar.Visible = false
		return
	end
	bossBar.Visible = true
	local phase = boss:GetAttribute("BossPhase") or 1
	bossBar.Name.Text = string.format("Crystal Guardian  •  Phase %d", phase)
	local ratio = math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1)
	bossBar.HPBack.HPFill.Size = UDim2.fromScale(ratio, 1)
	bossBar.HPBack.HPText.Text = string.format("%d / %d HP", math.max(0, math.floor(humanoid.Health)), math.floor(humanoid.MaxHealth))
end

for _, attribute in ipairs({ "Level", "Experience", "Money", "EquippedCrystal", "CrystalMasteryLevel", "CrystalMasteryXP", "AchievementCount", "Title" }) do
	player:GetAttributeChangedSignal(attribute):Connect(function()
		refreshHud()
		scheduleQuestRefresh()
	end)
end

xpChanged.OnClientEvent:Connect(function()
	refreshHud()
	scheduleQuestRefresh()
end)

moneyChanged.OnClientEvent:Connect(function()
	refreshHud()
	scheduleQuestRefresh()
end)

crystalMasteryChanged.OnClientEvent:Connect(function(crystalId, level, xp)
	if crystalId == player:GetAttribute("EquippedCrystal") then
		player:SetAttribute("CrystalMasteryLevel", level or 1)
		player:SetAttribute("CrystalMasteryXP", xp or 0)
	end
	refreshHud()
end)

levelUp.OnClientEvent:Connect(function(level)
	player:SetAttribute("QuestMessage", string.format("Level Up! Level %d", tonumber(level) or (player:GetAttribute("Level") or 1)))
	refreshHud()
	scheduleQuestRefresh()
end)

inventoryChanged.OnClientEvent:Connect(function(data)
	inventory = type(data) == "table" and data or {}
	refreshHud()
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
		local target = getTargetFromMouse()
		if target and canPresentCombat("Ability", target) then
			local crystal = getEquippedCrystal()
			crystalAnimationController.Play("Ability", crystal)
			crystalVFXController.Play("Ability", crystal)
			combatRemote:FireServer("Ability", target)
		end
	elseif input.KeyCode == Enum.KeyCode.Z then
		crystalChanged:FireServer(crystalOrder[1])
	elseif input.KeyCode == Enum.KeyCode.X then
		crystalChanged:FireServer(crystalOrder[2])
	elseif input.KeyCode == Enum.KeyCode.C then
		crystalChanged:FireServer(crystalOrder[3])
	elseif input.KeyCode == Enum.KeyCode.E then
		inventoryRequest:FireServer()
		refreshQuests()
	elseif input.KeyCode == Enum.KeyCode.Four then
		inventoryRequest:FireServer("Sell", sellOrder[1], 1)
	elseif input.KeyCode == Enum.KeyCode.Five then
		inventoryRequest:FireServer("Sell", sellOrder[2], 1)
	elseif input.KeyCode == Enum.KeyCode.Six then
		inventoryRequest:FireServer("Sell", sellOrder[3], 1)
	elseif input.KeyCode == Enum.KeyCode.Seven then
		inventoryRequest:FireServer("Sell", sellOrder[4], 1)
	elseif input.KeyCode == Enum.KeyCode.Eight then
		inventoryRequest:FireServer("Sell", sellOrder[5], 1)
	elseif input.KeyCode == Enum.KeyCode.U then
		crystalUpgradeRequest:FireServer(player:GetAttribute("EquippedCrystal") or "EMBER")
	end
end)

RunService.RenderStepped:Connect(refreshBoss)

print("Crystal Bound client ready")
