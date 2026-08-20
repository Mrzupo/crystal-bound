local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DamageService = require(script.Parent.DamageService)
local DodgeConfig = require(ReplicatedStorage.Config.DodgeConfig)

local DodgeService = {}
local cooldowns = setmetatable({}, { __mode = "k" })
local playerConnections = setmetatable({}, { __mode = "k" })
local invulnerabilityTokens = setmetatable({}, { __mode = "k" })

local function finiteNumber(value, fallback)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return fallback end
	return number
end

local COOLDOWN = math.clamp(finiteNumber(DodgeConfig.Cooldown, 2.5), 0.1, 60)
local INVULNERABILITY = math.clamp(finiteNumber(DodgeConfig.Invulnerability, 0.45), 0.05, 2)
local BOOST = math.clamp(finiteNumber(DodgeConfig.Boost, 42), 1, 100)
local MAX_DIRECTION_MAGNITUDE = math.clamp(finiteNumber(DodgeConfig.MaxDirectionMagnitude, 1000), 1, 10000)

local function clearForceField(character)
	local forceField = character and character:FindFirstChild("CrystalBoundDodgeForceField")
	if forceField then forceField:Destroy() end
end

local function disconnectPlayer(player)
	local connection = playerConnections[player]
	if connection and connection.Connected then connection:Disconnect() end
	playerConnections[player] = nil
end

local function invalidateInvulnerability(player)
	invulnerabilityTokens[player] = (invulnerabilityTokens[player] or 0) + 1
end

local function finiteComponent(value)
	return type(value) == "number" and value == value and value < math.huge and value > -math.huge
end

local function validDirection(direction)
	if typeof(direction) ~= "Vector3" then return false end
	if not finiteComponent(direction.X) or not finiteComponent(direction.Y) or not finiteComponent(direction.Z) then return false end
	return direction.Magnitude <= MAX_DIRECTION_MAGNITUDE
end

local function finiteDamage(value)
	local amount = tonumber(value)
	if not finiteComponent(amount) then return nil end
	return amount
end

function DodgeService.TryDodge(player, direction)
	if not player or not player:IsA("Player") then return false, "Invalid player" end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then return false, "Not ready" end

	local now = os.clock()
	local nextReady = cooldowns[player] or 0
	if now < nextReady then return false, "Dodge on cooldown" end

	local requested = direction
	if requested ~= nil and not validDirection(requested) then
		return false, "Invalid direction"
	end
	requested = validDirection(requested) and requested or Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	local flat = Vector3.new(requested.X, 0, requested.Z)
	if not finiteComponent(flat.X) or not finiteComponent(flat.Z) or flat.Magnitude < 0.1 then
		flat = Vector3.new(0, 0, -1)
	end
	flat = flat.Unit

	cooldowns[player] = now + COOLDOWN
	player:SetAttribute("DodgeCooldownEnd", now + COOLDOWN)
	player:SetAttribute("DodgeInvulnerable", true)
	player:SetAttribute("DodgeMessage", "Dodge!")

	invalidateInvulnerability(player)
	local token = invulnerabilityTokens[player]
	clearForceField(character)
	local forceField = Instance.new("ForceField")
	forceField.Name = "CrystalBoundDodgeForceField"
	forceField.Visible = false
	forceField.Parent = character

	root.AssemblyLinearVelocity = Vector3.new(flat.X * BOOST, root.AssemblyLinearVelocity.Y, flat.Z * BOOST)

	task.delay(INVULNERABILITY, function()
		if player.Parent and invulnerabilityTokens[player] == token then
			player:SetAttribute("DodgeInvulnerable", false)
			if player.Character == character then clearForceField(character) end
		end
	end)
	return true
end

function DodgeService.IsInvulnerable(player)
	return player and player:IsA("Player") and player:GetAttribute("DodgeInvulnerable") == true
end

function DodgeService.ApplyDamage(player, humanoid, amount, attacker, damageType, range)
	if not player or not player:IsA("Player") or not humanoid or humanoid.Health <= 0 then return false end
	local character = player.Character
	if not character or humanoid.Parent ~= character then return false end
	if DodgeService.IsInvulnerable(player) then
		player:SetAttribute("DodgeMessage", "Dodged!")
		return false
	end
	local damage = finiteDamage(amount)
	if not damage or damage <= 0 then return false end
	local resolvedDamageType = damageType or (attacker and "Physical" or "Environmental")
	local safeRange
	if attacker then
		safeRange = tonumber(range)
		if not safeRange or safeRange ~= safeRange or safeRange == math.huge or safeRange == -math.huge or safeRange <= 0 then
			return false
		end
		safeRange = math.clamp(safeRange, 0.1, 1000)
	end
	local request = {
		Attacker = attacker,
		Target = player,
		Amount = math.clamp(damage, 0, 1000),
		Range = safeRange,
		DamageType = resolvedDamageType,
	}
	local result = DamageService.ProcessDamage(request)
	return result.Success and result.Amount > 0
end

function DodgeService.CleanupPlayer(player)
	disconnectPlayer(player)
	invalidateInvulnerability(player)
	cooldowns[player] = nil
	if player.Character then clearForceField(player.Character) end
	if player.Parent then
		player:SetAttribute("DodgeInvulnerable", false)
		player:SetAttribute("DodgeCooldownEnd", 0)
	end
end

local function resetForRespawn(player)
	invalidateInvulnerability(player)
	cooldowns[player] = 0
	if player.Parent then
		player:SetAttribute("DodgeInvulnerable", false)
		player:SetAttribute("DodgeCooldownEnd", 0)
	end
	if player.Character then clearForceField(player.Character) end
end

local function bindPlayer(player)
	disconnectPlayer(player)
	playerConnections[player] = player.CharacterAdded:Connect(function()
		resetForRespawn(player)
	end)
	if player.Character then resetForRespawn(player) end
end

Players.PlayerAdded:Connect(bindPlayer)
for _, player in ipairs(Players:GetPlayers()) do bindPlayer(player) end
Players.PlayerRemoving:Connect(function(player)
	DodgeService.CleanupPlayer(player)
end)

return DodgeService
