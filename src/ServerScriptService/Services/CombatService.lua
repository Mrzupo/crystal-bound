local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DamageService = require(script.Parent.DamageService)
local PlayerService = require(script.Parent.PlayerService)
local XPService = require(script.Parent.XPService)
local EconomyService = require(script.Parent.EconomyService)
local CrystalSystem = require(ReplicatedStorage.Modules.CrystalSystem)

local CombatService = {}
local cooldowns = {}

local function getCharacter(instance)
	if instance:IsA("Player") then
		return instance.Character
	end
	if instance:IsA("Model") then
		return instance
	end
	return nil
end

local function isPlayerTarget(target)
	return target:IsA("Player") or (target:IsA("Model") and Players:GetPlayerFromCharacter(target) ~= nil)
end

local function findRemote(name)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	return remotes and remotes:FindFirstChild(name)
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

function CombatService.HandleRequest(player, action, target)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then return end
	local profile = PlayerService.GetProfile(player)
	if not profile or not profile.Crystals then return end
	if typeof(target) ~= "Instance" then return end
	if target == player or isPlayerTarget(target) then return end

	local crystalId = profile.Crystals.Equipped
	local config
	local key = action == "Ability" and "Abilities" or "BasicAttack"
	config = CrystalSystem.GetAbility(crystalId)
	if action ~= "Ability" then
		config = CrystalSystem.GetBasicAttack(crystalId)
	end
	if not config then return end

	cooldowns[player] = cooldowns[player] or {}
	local now = os.clock()
	local nextAllowed = cooldowns[player][action] or 0
	if now < nextAllowed then return end
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
	if not result.Success then return end

	if targetModel and targetModel:FindFirstChildOfClass("Humanoid") then
		local humanoid = targetModel:FindFirstChildOfClass("Humanoid")
		if humanoid.Health <= 0 then
			local xpGain = action == "Ability" and 40 or 25
			local moneyGain = action == "Ability" and 20 or 10
			local _, _, levelsGained = XPService.AddXP(profile, xpGain)
			EconomyService.AddMoney(profile, moneyGain)
			fireProgress(player, levelsGained, true)
		end
	end
end

return CombatService