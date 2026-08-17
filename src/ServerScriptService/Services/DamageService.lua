local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Validators = require(ReplicatedStorage.Modules.Combat.DamageValidators)
local DamageResult = require(ReplicatedStorage.Modules.Combat.DamageResult)

local DamageService = {}

local function getRoot(instance)
	if not instance or not instance:IsA("Instance") then return nil end
	if instance:IsA("Player") then
		local character = instance.Character
		return character and character:FindFirstChild("HumanoidRootPart")
	end
	if instance:IsA("Model") then
		return instance:FindFirstChild("HumanoidRootPart") or instance.PrimaryPart
	end
	return nil
end

function DamageService.ValidateRequest(request)
	return Validators.IsValid(request)
		and typeof(request.Target) == "Instance"
		and typeof(request.Attacker) == "Instance"
end

function DamageService.CanDamage(request)
	if not DamageService.ValidateRequest(request) then return false end
	if request.Attacker == request.Target then return false end
	if not request.Target:IsDescendantOf(workspace) then return false end
	local attackerRoot = getRoot(request.Attacker)
	local targetRoot = getRoot(request.Target)
	if not attackerRoot or not targetRoot then return false end
	local maxRange = tonumber(request.Range) or 16
	return (attackerRoot.Position - targetRoot.Position).Magnitude <= maxRange
end

function DamageService.ProcessDamage(request)
	if not DamageService.CanDamage(request) then
		return DamageResult.new(false, 0, "Invalid or out-of-range request")
	end

	local targetModel = request.Target:IsA("Player") and request.Target.Character or request.Target
	if not targetModel or not targetModel:IsA("Model") then
		return DamageResult.new(false, 0, "Invalid target model")
	end

	local isEnemy = targetModel:GetAttribute("Enemy") == true
	local isBoss = targetModel:GetAttribute("BossId") ~= nil
	if not isEnemy and not isBoss then
		return DamageResult.new(false, 0, "Target is not a combat enemy")
	end

	local humanoid = targetModel:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return DamageResult.new(false, 0, "Target has no living humanoid")
	end

	local amount = math.clamp(tonumber(request.Amount) or 0, 0, 1000)
	if amount <= 0 then
		return DamageResult.new(false, 0, "Invalid damage")
	end

	if targetModel:GetAttribute("DodgeInvulnerable") == true then
		return DamageResult.new(true, 0, "Dodged")
	end
	local owner = game:GetService("Players"):GetPlayerFromCharacter(targetModel)
	if owner and owner:GetAttribute("DodgeInvulnerable") == true then
		return DamageResult.new(true, 0, "Dodged")
	end

	humanoid:TakeDamage(amount)
	return DamageResult.new(true, amount, "Damage applied")
end

DamageService.ApplyDamage = DamageService.ProcessDamage

return DamageService
