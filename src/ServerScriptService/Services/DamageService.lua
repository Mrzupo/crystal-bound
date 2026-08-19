local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Validators = require(ReplicatedStorage.Modules.Combat.DamageValidators)
local DamageTypes = require(ReplicatedStorage.Modules.Combat.DamageTypes)
local DamageResult = require(ReplicatedStorage.Modules.Combat.DamageResult)

local DamageService = {}
local lastAttackers = setmetatable({}, { __mode = "k" })

local function finiteNumber(value)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return nil end
	return number
end

local function getNPCRoot()
	return Workspace:FindFirstChild("NPCs")
end

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

local function isValidAttacker(instance)
	if not instance or not instance:IsA("Instance") then return false end
	if instance:IsA("Player") then
		local character = instance.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		return instance.Parent ~= nil and humanoid ~= nil and humanoid.Health > 0
	end
	if instance:IsA("Model") then
		local humanoid = instance:FindFirstChildOfClass("Humanoid")
		local npcFolder = getNPCRoot()
		return npcFolder ~= nil
			and instance:IsDescendantOf(npcFolder)
			and instance:GetAttribute("Enemy") == true
			and humanoid ~= nil
			and humanoid.Health > 0
	end
	return false
end

local function rememberAttacker(targetModel, attacker)
	if attacker:IsA("Player") then
		lastAttackers[targetModel] = { Kind = "Player", Instance = attacker, UserId = attacker.UserId }
	else
		lastAttackers[targetModel] = { Kind = "Model", Instance = attacker }
	end
end

local function isValidTarget(target)
	if not target or not target:IsA("Instance") or not target:IsDescendantOf(Workspace) then return false end
	local targetModel = target:IsA("Player") and target.Character or target
	if not targetModel or not targetModel:IsA("Model") then return false end
	local humanoid = targetModel:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end
	if Players:GetPlayerFromCharacter(targetModel) then return true end
	local npcFolder = getNPCRoot()
	return npcFolder ~= nil
		and targetModel:IsDescendantOf(npcFolder)
		and (targetModel:GetAttribute("Enemy") == true or targetModel:GetAttribute("BossId") ~= nil)
end

function DamageService.ValidateRequest(request)
	if not Validators.IsValid(request) then return false end
	if typeof(request.Target) ~= "Instance" then return false end
	if request.DamageType == DamageTypes.Environmental and request.Attacker == nil then
		return true
	end
	return typeof(request.Attacker) == "Instance" and isValidAttacker(request.Attacker)
end

function DamageService.CanDamage(request)
	if not DamageService.ValidateRequest(request) then return false end
	if not isValidTarget(request.Target) then return false end

	if request.DamageType == DamageTypes.Environmental and request.Attacker == nil then
		return true
	end

	local attackerModel = request.Attacker:IsA("Player") and request.Attacker.Character or request.Attacker
	local targetModel = request.Target:IsA("Player") and request.Target.Character or request.Target
	if attackerModel == targetModel then return false end
	if Players:GetPlayerFromCharacter(attackerModel) and Players:GetPlayerFromCharacter(targetModel) then
		return false
	end

	local attackerRoot = getRoot(request.Attacker)
	local targetRoot = getRoot(request.Target)
	if not attackerRoot or not targetRoot then return false end
	local maxRange = finiteNumber(request.Range)
	if not maxRange or maxRange <= 0 or maxRange > 1000 then return false end
	return (attackerRoot.Position - targetRoot.Position).Magnitude <= maxRange
end

function DamageService.GetLastAttacker(targetModel)
	if not targetModel or not targetModel:IsA("Model") then return nil end
	local record = lastAttackers[targetModel]
	if not record then return nil end
	if record.Kind == "Player" then
		local player = record.Instance
		if player and player.Parent and Players:GetPlayerByUserId(record.UserId) == player then
			return player
		end
	elseif record.Kind == "Model" then
		local model = record.Instance
		local npcFolder = getNPCRoot()
		if model and model.Parent and npcFolder and model:IsDescendantOf(npcFolder) and model:GetAttribute("Enemy") == true then
			return model
		end
	end
	lastAttackers[targetModel] = nil
	return nil
end

function DamageService.ClearTarget(targetModel)
	if targetModel then lastAttackers[targetModel] = nil end
end

function DamageService.ProcessDamage(request)
	if not DamageService.CanDamage(request) then
		return DamageResult.new(false, 0, "Invalid or out-of-range request")
	end

	local targetModel = request.Target:IsA("Player") and request.Target.Character or request.Target
	if not targetModel or not targetModel:IsA("Model") then
		return DamageResult.new(false, 0, "Invalid target model")
	end

	local humanoid = targetModel:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return DamageResult.new(false, 0, "Target has no living humanoid")
	end

	local amount = math.clamp(finiteNumber(request.Amount) or 0, 0, 1000)
	if amount <= 0 then
		return DamageResult.new(false, 0, "Invalid damage")
	end

	if targetModel:GetAttribute("DodgeInvulnerable") == true then
		return DamageResult.new(true, 0, "Dodged")
	end
	local owner = Players:GetPlayerFromCharacter(targetModel)
	if owner and owner:GetAttribute("DodgeInvulnerable") == true then
		return DamageResult.new(true, 0, "Dodged")
	end

	local previousAttacker = lastAttackers[targetModel]
	if request.Attacker then
		rememberAttacker(targetModel, request.Attacker)
	end
	local before = humanoid.Health
	humanoid:TakeDamage(amount)
	local applied = math.max(0, before - humanoid.Health)
	if applied <= 0 and request.Attacker then
		lastAttackers[targetModel] = previousAttacker
	end
	return DamageResult.new(true, applied, applied > 0 and "Damage applied" or "No damage applied")
end

DamageService.ApplyDamage = DamageService.ProcessDamage

return DamageService
