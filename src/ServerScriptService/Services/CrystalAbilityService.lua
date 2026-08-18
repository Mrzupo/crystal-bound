local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CrystalConfig = require(ReplicatedStorage.Config.CrystalConfig)
local DamageService = require(script.Parent.DamageService)
local HitboxService = require(ReplicatedStorage.Modules.Combat.HitboxService)

local CrystalAbilityService = {}

local function safePositive(value, fallback)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge or number <= 0 then
		return fallback
	end
	return math.min(number, 1000)
end

local function executeTide(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return { Message = nil, Hits = {} }
	end

	local abilityConfig = CrystalConfig.Abilities.TIDE or {}
	local healAmount = math.max(0, safePositive(abilityConfig.HealAmount, 0))
	humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + healAmount)
	return {
		Message = "Tidal Pulse restored health.",
		Hits = {},
	}
end

local function executeGale(player, targetModel, abilityDamage, abilityRange)
	local safeDamage = safePositive(abilityDamage, 1)
	local safeRange = safePositive(abilityRange, 1)
	local centerRoot = targetModel:FindFirstChild("HumanoidRootPart") or targetModel.PrimaryPart
	if not centerRoot then
		return { Message = nil, Hits = {} }
	end

	local hits = {}
	for _, enemy in ipairs(HitboxService.GetEnemyModels(centerRoot.Position, 12, targetModel)) do
		local humanoid = enemy:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			local result = DamageService.ProcessDamage({
				Attacker = player,
				Target = enemy,
				Amount = math.max(1, safeDamage * 0.45),
				Range = safeRange,
				DamageType = "CrystalAbilitySplash",
			})
			if result.Success and result.Amount > 0 then
				table.insert(hits, {
					Target = enemy,
					Amount = result.Amount,
					Defeated = humanoid.Health <= 0,
				})
			end
		end
	end

	return { Message = nil, Hits = hits }
end

function CrystalAbilityService.Execute(player, profile, crystalId, targetModel, abilityDamage, abilityRange)
	if not player or not player:IsA("Player") then
		return { Message = nil, Hits = {} }
	end
	if crystalId == "TIDE" then
		return executeTide(player)
	elseif crystalId == "GALE" then
		if not targetModel or not targetModel:IsA("Model") then
			return { Message = nil, Hits = {} }
		end
		return executeGale(player, targetModel, abilityDamage, abilityRange)
	end

	return { Message = nil, Hits = {} }
end

return CrystalAbilityService
