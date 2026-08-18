local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DamageService = require(script.Parent.DamageService)
local HitboxService = require(ReplicatedStorage.Modules.Combat.HitboxService)

local CrystalAbilityService = {}

local function executeTide(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return { Message = nil, Hits = {} }
	end

	humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 30)
	return {
		Message = "Tidal Pulse restored health.",
		Hits = {},
	}
end

local function executeGale(player, targetModel, abilityDamage, abilityRange)
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
				Amount = math.max(1, abilityDamage * 0.45),
				Range = abilityRange,
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
	if crystalId == "TIDE" then
		return executeTide(player)
	elseif crystalId == "GALE" then
		return executeGale(player, targetModel, abilityDamage, abilityRange)
	end

	return { Message = nil, Hits = {} }
end

return CrystalAbilityService
