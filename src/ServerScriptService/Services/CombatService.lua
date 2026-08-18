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
local DailyBountyService = require(script.Parent.DailyBountyService)
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local HitboxService = require(ReplicatedStorage.Modules.Combat.HitboxService)

local CombatService = {}
local cooldowns = {}
local nextRequest = {}

local REQUEST_INTERVAL = 0.03
local VALID_ACTIONS = { Basic = true, Ability = true }

local function getCharacter(instance)
	if instance:IsA("Player") then return instance.Character end
	if instance:IsA("Model") then return instance end
	return nil
end

local function isPlayerTarget(target)
	return target:IsA("Player") or (target:IsA("Model") and Players:GetPlayerFromCharacter(target) ~= nil)
end

local function fireCombatFeedback(targetModel, attacker, action, crystalId, critical, amount)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local feedback = remotes and remotes:FindFirstChild("CombatFeedback")
	if not feedback or not feedback:IsA("RemoteEvent") then return end
	feedback:FireAllClients(targetModel, attacker.UserId, action, crystalId, critical == true, amount)
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

local function giveLoot(player, profile, targetModel, crystalId)
	local enemyType = targetModel:GetAttribute("EnemyType")
	local enemyConfig = enemyType and EnemyConfig.Get(enemyType) or nil
	local itemId = enemyConfig and enemyConfig.Drop
	if not itemId then itemId = ({ EMBER = "EmberShard", TIDE = "TidePearl", GALE = "GaleFeather" })[crystalId] end
	if not itemId then return false end
	local chance = enemyConfig and tonumber(enemyConfig.DropChance) or 1
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
	targetModel:SetAttribute("DeathRewarded", true)
	local enemyType = targetModel:GetAttribute("EnemyType")
	local enemyConfig = enemyType and EnemyConfig.Get(enemyType) or nil
	local xpGain = enemyConfig and enemyConfig.XP or (action == "Ability" and 40 or 25)
	local moneyGain = enemyConfig and enemyConfig.Money or (action == "Ability" and 20 or 10)
	local _, _, levelsGained = XPService.AddXP(profile, xpGain)
	EconomyService.AddMoney(profile, moneyGain)
	giveLoot(player, profile, targetModel, crystalId)
	profile.Stats.EnemiesDefeated = (profile.Stats.EnemiesDefeated or 0) + 1
	if enemyType == "AncientGolem" then
		profile.Stats.AncientGolemsDefeated = (profile.Stats.AncientGolemsDefeated or 0) + 1
	elseif enemyType == "CrystalBat" then
		profile.Stats.CrystalBatsDefeated = (profile.Stats.CrystalBatsDefeated or 0) + 1
	end
	DailyBountyService.AddProgress(player, profile, enemyType, EconomyService, PlayerService)
	local masteryLevel, masteryXP, masteryLevels = CrystalMastery.AddXP(profile, crystalId, math.max(10, math.floor(xpGain * 0.5)))
	advanceEnemyQuest(player, profile, enemyType)
	if targetModel.Name == "TrainingDummy" then completeQuest(player, profile, "FIRST_FIGHT", "First Trial complete!") end
	if levelsGained > 0 and #QuestService.GetActive(profile) == 0 then QuestService.TryStartNext(player, profile) end
	if masteryLevels > 0 then player:SetAttribute("CrystalMessage", string.format("%s mastery reached Lv. %d", crystalId, masteryLevel)) end
	fireProgress(player, levelsGained or 0, { Crystal = crystalId, Level = masteryLevel, XP = masteryXP })
end

local function applyGaleSplash(player, centerModel, damage, range)
	local centerRoot = centerModel:FindFirstChild("HumanoidRootPart") or centerModel.PrimaryPart
	if not centerRoot then return end
	local profile = PlayerService.GetProfile(player)
	for _, enemy in ipairs(HitboxService.GetEnemyModels(centerRoot.Position, 12, centerModel)) do
		local humanoid = enemy:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			local result = DamageService.ProcessDamage({
				Attacker = player,
				Target = enemy,
				Amount = math.max(1, damage * 0.45),
				Range = range,
				DamageType = "CrystalAbilitySplash",
			})
			if result.Success then
				fireCombatFeedback(enemy, player, "Ability", "GALE", false, result.Amount)
				if humanoid.Health <= 0 and profile then
					rewardDefeat(player, profile, enemy, "Ability", "GALE")
				end
			end
		end
	end
end

local function applyAbilitySpecial(player, profile, crystalId, targetModel, abilityDamage, abilityRange)
	if crystalId == "TIDE" then
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 30)
			player:SetAttribute("CrystalMessage", "Tidal Pulse restored health.")
		end
	elseif crystalId == "GALE" then
		applyGaleSplash(player, targetModel, abilityDamage, abilityRange)
	end
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
	if not HitboxService.IsWithinRange(player, targetModel, config.Range) then return end

	local humanoid = targetModel:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	local passive = CrystalSystem.GetPassive(crystalId)
	local mastery = CrystalMastery.GetBonuses(profile, crystalId)
	local multiplier = math.max(0.1, tonumber(passive.DamageMultiplier) or 1) * mastery.DamageMultiplier
	if action == "Ability" then multiplier *= mastery.AbilityDamageMultiplier end
	local critical, criticalMultiplier = CombatModifierService.RollCritical(profile, crystalId)
	multiplier *= criticalMultiplier
	local damage = (config.Damage + math.max(0, (profile.Stats.Damage or 0) - 10)) * multiplier

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

	if critical then player:SetAttribute("CrystalMessage", "CRITICAL HIT!") end
	if action == "Ability" then
		applyAbilitySpecial(player, profile, crystalId, targetModel, damage, config.Range)
		completeQuest(player, profile, "CRYSTAL_POWER", "Crystal Power complete!")
	end
	if humanoid.Health <= 0 then rewardDefeat(player, profile, targetModel, action, crystalId) end
end

function CombatService.CleanupPlayer(player)
	cooldowns[player] = nil
	nextRequest[player] = nil
end

return CombatService
