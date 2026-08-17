local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DamageService = require(script.Parent.DamageService)
local PlayerService = require(script.Parent.PlayerService)
local XPService = require(script.Parent.XPService)
local EconomyService = require(script.Parent.EconomyService)
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
	if xpChanged then xpChanged:FireClient(player, profile.Experience, profile.Level) end
	if moneyRemote and moneyChanged then moneyRemote:FireClient(player, profile.Money) end
	if levelUp and levelsGained > 0 then levelUp:FireClient(player, profile.Level) end
end

local function completeFirstFight(player, profile)
	if not QuestSystem.IsActive(profile, "FIRST_FIGHT") or QuestSystem.IsCompleted(profile, "FIRST_FIGHT") then return end
	QuestSystem.Complete(profile, "FIRST_FIGHT")
	XPService.AddXP(profile, 100)
	EconomyService.AddMoney(profile, 50)
	PlayerService.Sync(player)
	player:SetAttribute("QuestMessage", "First Trial complete!")
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
		local _, _, levelsGained = XPService.AddXP(profile, action == "Ability" and 40 or 25)
		EconomyService.AddMoney(profile, action == "Ability" and 20 or 10)
		fireProgress(player, levelsGained, true)
		completeFirstFight(player, profile)
	end

	if action == "Ability" and QuestSystem.IsActive(profile, "CRYSTAL_POWER") then
		QuestSystem.Complete(profile, "CRYSTAL_POWER")
		XPService.AddXP(profile, 150)
		EconomyService.AddMoney(profile, 75)
		PlayerService.Sync(player)
		player:SetAttribute("QuestMessage", "Crystal Power complete!")
	end
end

return CombatService
