local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local DamageService = require(script.Parent.DamageService)
local PlayerService = require(script.Parent.PlayerService)
local XPService = require(script.Parent.XPService)
local EconomyService = require(script.Parent.EconomyService)
local InventoryService = require(script.Parent.InventoryService)
local QuestSystem = require(ReplicatedStorage.Modules.QuestSystem)
local QuestService = require(script.Parent.QuestService)
local CrystalSystem = require(ReplicatedStorage.Modules.CrystalSystem)
local CrystalMastery = require(ReplicatedStorage.Modules.CrystalMastery)
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local BossService = require(script.Parent.BossService)

local CombatService = {}
local cooldowns = {}

local function getCharacter(instance)
	if instance:IsA("Player") then return instance.Character end
	if instance:IsA("Model") then return instance end
	return nil
end

local function isPlayerTarget(target)
	return target:IsA("Player") or (target:IsA("Model") and Players:GetPlayerFromCharacter(target) ~= nil)
end

local function emitCombatEffect(crystalId, targetModel, ability)
	local root = targetModel:FindFirstChild("HumanoidRootPart") or targetModel.PrimaryPart
	if not root then return end
	local effect = Instance.new("Part")
	effect.Name = ability and "CrystalAbilityEffect" or "CrystalHitEffect"
	effect.Anchored = true
	effect.CanCollide = false
	effect.CanQuery = false
	effect.CanTouch = false
	effect.Shape = Enum.PartType.Ball
	effect.Material = Enum.Material.Neon
	effect.Size = ability and Vector3.new(5, 5, 5) or Vector3.new(2, 2, 2)
	effect.CFrame = root.CFrame
	effect.Transparency = 0.15
	local color = crystalId == "EMBER" and Color3.fromRGB(255, 90, 35)
		or crystalId == "TIDE" and Color3.fromRGB(45, 150, 255)
		or Color3.fromRGB(170, 120, 255)
	effect.Color = color
	effect.Parent = workspace
	local goal = { Size = ability and Vector3.new(11, 11, 11) or Vector3.new(4, 4, 4), Transparency = 1 }
	TweenService:Create(effect, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
	Debris:AddItem(effect, 0.25)
end

local function fireProgress(player, levelsGained, moneyChanged, inventoryChanged)
	local profile = PlayerService.GetProfile(player)
	if not profile then return end
	PlayerService.Sync(player)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then return end
	if remotes:FindFirstChild("XPChanged") then remotes.XPChanged:FireClient(player, profile.Experience, profile.Level) end
	if moneyChanged and remotes:FindFirstChild("MoneyChanged") then remotes.MoneyChanged:FireClient(player, profile.Money) end
	if inventoryChanged and remotes:FindFirstChild("InventoryChanged") then remotes.InventoryChanged:FireClient(player, profile.Inventory) end
	if levelsGained > 0 and remotes:FindFirstChild("LevelUp") then remotes.LevelUp:FireClient(player, profile.Level) end
	if remotes:FindFirstChild("CrystalMasteryChanged") then
		local mastery = CrystalMastery.Get(profile, profile.Crystals.Equipped)
		remotes.CrystalMasteryChanged:FireClient(player, profile.Crystals.Equipped, mastery.Level, mastery.XP)
	end
end

local function startNextQuest(player, profile)
	local candidates = {}
	if profile.Level >= 3 then table.insert(candidates, "HUNT_EMBERLINGS") end
	if profile.Level >= 6 then table.insert(candidates, "TIDE_EXPEDITION") end
	if profile.Level >= 10 then table.insert(candidates, "WIND_TRIAL") end
	if profile.Level >= 15 then table.insert(candidates, "GUARDIAN_TRIAL") end
	for _, questId in ipairs(candidates) do
		if not QuestSystem.IsActive(profile, questId) and not QuestSystem.IsCompleted(profile, questId) then
			if QuestService.Start(player, profile, questId) then
				player:SetAttribute("QuestMessage", "New quest: " .. QuestSystem.GetDefinition(questId).Name)
				return
			end
		end
	end
end

local function completeQuest(player, profile, questId, message)
	local definition = QuestSystem.GetDefinition(questId)
	if not definition or not QuestSystem.IsActive(profile, questId) then return false end
	if not QuestSystem.Complete(profile, questId) then return false end
	XPService.AddXP(profile, definition.XP)
	EconomyService.AddMoney(profile, definition.Money)
	PlayerService.Sync(player)
	player:SetAttribute("QuestMessage", message or (definition.Name .. " complete!"))
	startNextQuest(player, profile)
	return true
end

local function advanceEnemyQuest(player, profile, enemyType)
	for questId, definition in pairs(QuestSystem.GetDefinitions()) do
		if definition.EnemyType == enemyType and QuestSystem.IsActive(profile, questId) then
			local complete, progress, goal = QuestSystem.Advance(profile, questId, 1)
			player:SetAttribute("QuestProgress", string.format("%s: %d/%d", definition.Name, progress, goal))
			if complete then completeQuest(player, profile, questId, definition.Name .. " complete!") end
		end
	end
end

local function giveLoot(profile, targetModel, crystalId)
	local enemyType = targetModel:GetAttribute("EnemyType")
	local enemyConfig = enemyType and EnemyConfig.Get(enemyType) or nil
	local itemId = enemyConfig and enemyConfig.Drop
	if not itemId then itemId = ({ EMBER = "EmberShard", TIDE = "TidePearl", GALE = "GaleFeather" })[crystalId] end
	if itemId then return InventoryService.AddItem(profile, itemId, 1) end
	return 0
end

local function rewardDefeat(player, profile, targetModel, action, crystalId)
	if targetModel:GetAttribute("Enemy") ~= true then return end
	if targetModel:GetAttribute("DeathRewarded") == true then return end
	targetModel:SetAttribute("DeathRewarded", true)
	local enemyType = targetModel:GetAttribute("EnemyType")
	local enemyConfig = enemyType and EnemyConfig.Get(enemyType) or nil
	local xpGain = enemyConfig and enemyConfig.XP or (action == "Ability" and 40 or 25)
	local moneyGain = enemyConfig and enemyConfig.Money or (action == "Ability" and 20 or 10)
	local _, _, levelsGained = XPService.AddXP(profile, xpGain)
	EconomyService.AddMoney(profile, moneyGain)
	giveLoot(profile, targetModel, crystalId)
	profile.Stats = profile.Stats or {}
	profile.Stats.EnemiesDefeated = (profile.Stats.EnemiesDefeated or 0) + 1

	local masteryLevel, masteryXP, masteryLevels = CrystalMastery.AddXP(profile, crystalId, math.max(10, math.floor(xpGain * 0.5)))
	advanceEnemyQuest(player, profile, enemyType)
	if targetModel.Name == "TrainingDummy" then completeQuest(player, profile, "FIRST_FIGHT", "First Trial complete!") end
	if enemyType == "CrystalGuardian" then
		profile.Stats.BossesDefeated = (profile.Stats.BossesDefeated or 0) + 1
		BossService.RewardDefeat(player, targetModel, EconomyService, XPService, PlayerService)
		completeQuest(player, profile, "GUARDIAN_TRIAL", "Guardian Trial complete!")
	end

	PlayerService.Sync(player)
	if masteryLevels > 0 then
		player:SetAttribute("QuestMessage", crystalId .. " Mastery Lv. " .. masteryLevel)
	end
	fireProgress(player, levelsGained or 0, true, true)
end

local function applyGaleSplash(player, centerModel, damage)
	local centerRoot = centerModel:FindFirstChild("HumanoidRootPart") or centerModel.PrimaryPart
	if not centerRoot then return end
	local folder = workspace:FindFirstChild("NPCs")
	if not folder then return end
	local profile = PlayerService.GetProfile(player)
	for _, enemy in ipairs(folder:GetChildren()) do
		if enemy ~= centerModel and enemy:IsA("Model") and enemy:GetAttribute("Enemy") == true then
			local humanoid = enemy:FindFirstChildOfClass("Humanoid")
			local root = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
			if humanoid and humanoid.Health > 0 and root and (root.Position - centerRoot.Position).Magnitude <= 12 then
				humanoid:TakeDamage(math.max(1, damage * 0.45))
				if humanoid.Health <= 0 and profile then rewardDefeat(player, profile, enemy, "Ability", "GALE") end
			end
		end
	end
end

local function applyAbilitySpecial(player, profile, crystalId, targetModel, abilityDamage)
	if crystalId == "TIDE" then
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 30)
			player:SetAttribute("QuestMessage", "Tidal Pulse restored health.")
		end
	elseif crystalId == "GALE" then
		applyGaleSplash(player, targetModel, abilityDamage)
	end
end

function CombatService.HandleRequest(player, action, target)
	if not player:IsA("Player") then return end
	local profile = PlayerService.GetProfile(player)
	if not profile or not profile.Crystals then return end
	if typeof(target) ~= "Instance" or target == player or isPlayerTarget(target) then return end

	local crystalId = profile.Crystals.Equipped
	local config = action == "Ability" and CrystalSystem.GetAbility(crystalId) or CrystalSystem.GetBasicAttack(crystalId)
	if not config then return end
	cooldowns[player] = cooldowns[player] or {}
	local now = os.clock()
	if now < (cooldowns[player][action] or 0) then return end
	cooldowns[player][action] = now + config.Cooldown

	local targetModel = getCharacter(target)
	if not targetModel then return end
	local passive = CrystalSystem.GetPassive(crystalId)
	local mastery = CrystalMastery.GetBonuses(profile, crystalId)
	local damageMultiplier = math.max(0.1, tonumber(passive.DamageMultiplier) or 1) * mastery.DamageMultiplier
	if action == "Ability" then damageMultiplier *= mastery.AbilityDamageMultiplier end
	local damage = (config.Damage + math.max(0, (profile.Stats.Damage or 10) - 10)) * damageMultiplier
	local result = DamageService.ProcessDamage({
		Attacker = player,
		Target = targetModel,
		Amount = damage,
		Range = config.Range,
		DamageType = "Crystal",
	})
	if not result.Success then return end
	emitCombatEffect(crystalId, targetModel, action == "Ability")

	if action == "Ability" then
		applyAbilitySpecial(player, profile, crystalId, targetModel, damage)
		completeQuest(player, profile, "CRYSTAL_POWER", "Crystal Power complete!")
	end

	local humanoid = targetModel:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health <= 0 then rewardDefeat(player, profile, targetModel, action, crystalId) end
end

return CombatService
