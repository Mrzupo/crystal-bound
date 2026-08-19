local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DamageService = require(script.Parent.DamageService)
local PlayerService = require(script.Parent.PlayerService)
local XPService = require(script.Parent.XPService)
local EconomyService = require(script.Parent.EconomyService)
local InventoryService = require(script.Parent.InventoryService)
local QuestSystem = require(ReplicatedStorage.Modules.QuestSystem)
local QuestService = require(script.Parent.QuestService)
local CrystalSystem = require(ReplicatedStorage.Modules.CrystalSystem)
local CrystalMastery = require(ReplicatedStorage.Modules.CrystalMastery)
local CombatModifierService = require(script.Parent.CombatModifierService)
local CrystalAbilityService = require(script.Parent.CrystalAbilityService)
local DailyBountyService = require(script.Parent.DailyBountyService)
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)

local CombatService = {}
local cooldowns = setmetatable({}, { __mode = "k" })
local nextRequest = setmetatable({}, { __mode = "k" })

local REQUEST_INTERVAL = 0.03
local VALID_ACTIONS = { Basic = true, Ability = true }

local function finiteNumber(value)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return nil end
	return number
end

local function getCharacter(instance)
	if instance:IsA("Player") then return instance.Character end
	if instance:IsA("Model") then return instance end
	return nil
end

local function isPlayerTarget(target)
	return target:IsA("Player") or (target:IsA("Model") and Players:GetPlayerFromCharacter(target) ~= nil)
end

local function fireCombatFeedback(targetModel, attacker, action, crystalId, critical, amount)
	local numericAmount = finiteNumber(amount)
	if not numericAmount or numericAmount <= 0 then return end
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local feedback = remotes and remotes:FindFirstChild("CombatFeedback")
	if not feedback or not feedback:IsA("RemoteEvent") then return end
	feedback:FireAllClients(targetModel, attacker.UserId, action, crystalId, critical == true, numericAmount)
end

local function fireProgress(player, levelsGained, mastery)
	local profile = PlayerService.GetProfile(player)
	if not profile then return end
	PlayerService.Sync(player)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then return end
	if remotes:FindFirstChild("XPChanged") then remotes.XPChanged:FireClient(player, profile.Experience, profile.Level) end
	if remotes:FindFirstChild("MoneyChanged") then remotes.MoneyChanged:FireClient(player, profile.Money) end
	if remotes:FindFirstChild("InventoryChanged") then remotes.InventoryChanged:FireClient(player, profile.Inventory) end
	if levelsGained > 0 and remotes:FindFirstChild("LevelUp") then remotes.LevelUp:FireClient(player, profile.Level) end
	if mastery and remotes:FindFirstChild("CrystalMasteryChanged") then remotes.CrystalMasteryChanged:FireClient(player, mastery.Crystal, mastery.Level, mastery.XP) end
end

local function completeQuest(player, profile, questId, message)
	return QuestService.Complete(player, profile, questId, message)
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

local function advanceAbilityQuest(player, profile)
	if not QuestSystem.IsActive(profile, "CRYSTAL_POWER") then return end
	local complete, progress, goal = QuestSystem.Advance(profile, "CRYSTAL_POWER", 1)
	player:SetAttribute("QuestProgress", string.format("Crystal Power: %d/%d", progress, goal))
	if complete then completeQuest(player, profile, "CRYSTAL_POWER", "Crystal Power complete!") end
end

local function giveLoot(player, profile, targetModel, enemyConfig)
	local itemId = enemyConfig and enemyConfig.Drop
	if not itemId then return false end
	local chance = math.clamp(finiteNumber(enemyConfig.DropChance) or 0, 0, 1)
	if chance <= 0 or (chance < 1 and math.random() > chance) then return false end
	local added = InventoryService.AddItem(profile, itemId, 1)
	if added > 0 then
		player:SetAttribute("LootMessage", "Loot: " .. itemId)
		return true
	end
	player:SetAttribute("LootMessage", "Inventory full: " .. itemId)
	return false
end

local function rewardDefeat(player, profile, targetModel, action, crystalId)
	if targetModel:GetAttribute("BossId") ~= nil or targetModel:GetAttribute("Enemy") ~= true or targetModel:GetAttribute("DeathRewarded") == true then return end
	local enemyType = targetModel:GetAttribute("EnemyType")
	if type(enemyType) ~= "string" then return end
	local enemyConfig = EnemyConfig.Types[enemyType]
	if type(enemyConfig) ~= "table" then return end
	targetModel:SetAttribute("DeathRewarded", true)

	local xpGain = enemyConfig.XP
	local moneyGain = enemyConfig.Money
	local _, _, levelsGained = XPService.AddXP(profile, xpGain)
	EconomyService.AddMoney(profile, moneyGain)
	giveLoot(player, profile, targetModel, enemyConfig)
	profile.Stats.EnemiesDefeated = (finiteNumber(profile.Stats.EnemiesDefeated) or 0) + 1
	if enemyType == "AncientGolem" then
		profile.Stats.AncientGolemsDefeated = (finiteNumber(profile.Stats.AncientGolemsDefeated) or 0) + 1
	elseif enemyType == "CrystalBat" then
		profile.Stats.CrystalBatsDefeated = (finiteNumber(profile.Stats.CrystalBatsDefeated) or 0) + 1
	end
	DailyBountyService.AddProgress(player, profile, enemyType, EconomyService, PlayerService)
	local masteryLevel, masteryXP, masteryLevels = CrystalMastery.AddXP(profile, crystalId, math.max(10, math.floor((finiteNumber(xpGain) or 0) * 0.5)))
	advanceEnemyQuest(player, profile, enemyType)
	if targetModel.Name == "TrainingDummy" then completeQuest(player, profile, "FIRST_FIGHT", "First Trial complete!") end
	if levelsGained > 0 and #QuestService.GetActive(profile) == 0 then QuestService.TryStartNext(player, profile) end
	if masteryLevels > 0 then player:SetAttribute("CrystalMessage", string.format("%s mastery reached Lv. %d", crystalId, masteryLevel)) end
	fireProgress(player, levelsGained or 0, { Crystal = crystalId, Level = masteryLevel, XP = masteryXP })
	DamageService.ClearTarget(targetModel)
end

function CombatService.HandleRequest(player, action, target)
	if not player:IsA("Player") or not VALID_ACTIONS[action] then return end
	local requestNow = os.clock()
	if requestNow < (nextRequest[player] or 0) then return end
	nextRequest[player] = requestNow + REQUEST_INTERVAL

	local profile = PlayerService.GetProfile(player)
	if not profile or not profile.Crystals then return end
	if typeof(target) ~= "Instance" or target == player or isPlayerTarget(target) then return end

	local crystalId = profile.Crystals.Equipped
	local config = action == "Ability" and CrystalSystem.GetAbility(crystalId) or CrystalSystem.GetBasicAttack(crystalId)
	if not config then return end

	cooldowns[player] = cooldowns[player] or {}
	local now = requestNow
	if now < (cooldowns[player][action] or 0) then return end

	local targetModel = getCharacter(target)
	if not targetModel then return end
	local humanoid = targetModel:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	local passive = CrystalSystem.GetPassive(crystalId)
	local mastery = CrystalMastery.GetBonuses(profile, crystalId)
	local multiplier = math.max(0.1, finiteNumber(passive.DamageMultiplier) or 1) * mastery.DamageMultiplier
	if action == "Ability" then multiplier *= mastery.AbilityDamageMultiplier end
	local critical, criticalMultiplier = CombatModifierService.RollCritical(profile, crystalId)
	multiplier *= criticalMultiplier
	local baseStatsDamage = math.max(0, finiteNumber(profile.Stats and profile.Stats.Damage) or 0)
	local damage = (config.Damage + math.max(0, baseStatsDamage - 10)) * multiplier

	local result = DamageService.ProcessDamage({
		Attacker = player,
		Target = targetModel,
		Amount = damage,
		Range = config.Range,
		DamageType = "Crystal",
	})
	if not result.Success then return end

	fireCombatFeedback(targetModel, player, action, crystalId, critical, result.Amount)
	cooldowns[player][action] = now + config.Cooldown
	if action == "Ability" then player:SetAttribute("AbilityCooldownEnd", now + config.Cooldown) end

	if critical and result.Amount > 0 then player:SetAttribute("CrystalMessage", "CRITICAL HIT!") end
	if action == "Ability" then
		local abilityResult = CrystalAbilityService.Execute(player, profile, crystalId, targetModel, damage, config.Range)
		if abilityResult.Message then player:SetAttribute("CrystalMessage", abilityResult.Message) end
		for _, hit in ipairs(abilityResult.Hits or {}) do
			fireCombatFeedback(hit.Target, player, "Ability", crystalId, false, hit.Amount)
			if hit.Defeated then rewardDefeat(player, profile, hit.Target, "Ability", crystalId) end
		end
		advanceAbilityQuest(player, profile)
	end
	if result.Amount > 0 and humanoid.Health <= 0 then rewardDefeat(player, profile, targetModel, action, crystalId) end
end

function CombatService.CleanupPlayer(player)
	cooldowns[player] = nil
	nextRequest[player] = nil
end

return CombatService
