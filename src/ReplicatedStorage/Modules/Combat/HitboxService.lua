local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local HitboxService = {}

local function rootOf(instance)
	if not instance then return nil end
	if instance:IsA("Player") then
		local character = instance.Character
		return character and character:FindFirstChild("HumanoidRootPart")
	end
	if instance:IsA("Model") then
		return instance:FindFirstChild("HumanoidRootPart") or instance.PrimaryPart
	end
	return nil
end

local function safeRadius(value)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then
		return 0
	end
	return math.clamp(number, 0, 1000)
end

function HitboxService.GetEnemyModels(center, radius, ignoreModel)
	local results = {}
	if typeof(center) ~= "Vector3" then return results end
	radius = safeRadius(radius)
	local folder = Workspace:FindFirstChild("NPCs")
	if not folder then return results end
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") and model ~= ignoreModel and model:GetAttribute("Enemy") == true then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local root = rootOf(model)
			if humanoid and humanoid.Health > 0 and root and (root.Position - center).Magnitude <= radius then
				table.insert(results, model)
			end
		end
	end
	return results
end

function HitboxService.GetPlayersInRadius(center, radius, ignorePlayer)
	local results = {}
	if typeof(center) ~= "Vector3" then return results end
	radius = safeRadius(radius)
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= ignorePlayer then
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = rootOf(player)
			if humanoid and humanoid.Health > 0 and root and (root.Position - center).Magnitude <= radius then
				table.insert(results, player)
			end
		end
	end
	return results
end

function HitboxService.IsWithinRange(attacker, target, radius)
	radius = safeRadius(radius)
	local attackerRoot = rootOf(attacker)
	local targetRoot = rootOf(target)
	return attackerRoot ~= nil and targetRoot ~= nil and (attackerRoot.Position - targetRoot.Position).Magnitude <= radius
end

return HitboxService
