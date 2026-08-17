local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DamageService = require(script.Parent.DamageService)
local PlayerService = require(script.Parent.PlayerService)
local XPService = require(script.Parent.XPService)
local EconomyService = require(script.Parent.EconomyService)
local InventoryService = require(script.Parent.InventoryService)
local QuestSystem = require(ReplicatedStorage.Modules.QuestSystem)
local CrystalSystem = require(ReplicatedStorage.Modules.CrystalSystem)

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

local function fireProgress(player, levelsGained, moneyChanged)
	local profile = PlayerService.GetProfile(player)
	if not profile then return end
	PlayerService.Sync(player)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then return end
	local xpChanged = remotes:FindFirstChild("XPChanged")
	local levelUp = remotes:FindFirstChild("LevelUp")
	local moneyRemote = remotes:FindFirstChild("MoneyChanged")
	local inventoryRemote = remotes:FindFirstChild("InventoryChanged")
	if xpChanged then xpChanged:FireClient(player, profile.Experience, profile.Level) end
	if moneyRemote and moneyChanged then moneyRemote:FireClient(player, profile.Money) end
	if inventoryRemote then inventoryRemote:FireClient(player, profile.Inventory) end
	if levelUp and levelsGained > 0 then levelUp:FireClient(player, profile.Level) end
end

local function completeQuest(player, profile, questId, xp, money, message)
	if QuestSystem.IsActive(profile, questId) and not QuestSystem.IsCompleted(profile, questId) then
		QuestSystem.Complete(profile, questId)
		XPService.AddXP(profile, xp)
		EconomyService.AddMoney(profile, money)
		player:SetAttribute("QuestMessage", message)
	end
end

local function giveLoot(profile, crystalId)
	local loot = ({
		EMBER = "EmberShard",
		TIDE = "TidePearl",
		GALE = "GaleFeather",
	})[crystalId]
	if loot then
		return InventoryService.AddItem(profile, loot, 1)
	end
	return 0
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
	local request = {
		Attacker = player,
		Target = targetModel,
		Amount = config.Damage + math.max(0, (profile.Stats.Damage or 0) - 10),
		Range = config.Range,
		DamageType = "Crystal",
	}

	local result = DamageService.ProcessDamage(request)
	if not result.Success or not targetModel then return end

	local humanoid = targetModel:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health <= 0 then
		local levelsGained = 0
		local xpGain = action == "Ability" and 40 or 25
		local moneyGain = action == "Ability" and 20 or 10
		local _, _, gained = XPService.AddXP(profile, xpGain)
		levelsGained = gained or 0
		EconomyService.AddMoney(profile, moneyGain)
		giveLoot(profile, crystalId)
		fireProgress(player, levelsGained, true)
		completeQuest(player, profile, "FIRST_FIGHT", 100, 50, "First Trial complete!")
	end

	if action == "Ability" then
		completeQuest(player, profile, "CRYSTAL_POWER", 150, 75, "Crystal Power complete!")
	end
end

return CombatService
