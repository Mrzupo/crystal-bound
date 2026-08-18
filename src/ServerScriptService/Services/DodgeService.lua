local Players = game:GetService("Players")

local DodgeService = {}
local cooldowns = {}

local COOLDOWN = 2.5
local INVULNERABILITY = 0.45
local BOOST = 42

local function clearForceField(character)
	local forceField = character and character:FindFirstChild("CrystalBoundDodgeForceField")
	if forceField then forceField:Destroy() end
end

local function finiteComponent(value)
	return type(value) == "number" and value == value and value < math.huge and value > -math.huge
end

local function validDirection(direction)
	if typeof(direction) ~= "Vector3" then return false end
	return finiteComponent(direction.X) and finiteComponent(direction.Y) and finiteComponent(direction.Z)
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

	local requested = validDirection(direction) and direction or Vector3.new(0, 0, -1)
	local flat = Vector3.new(requested.X, 0, requested.Z)
	if not finiteComponent(flat.X) or not finiteComponent(flat.Z) or flat.Magnitude < 0.1 then
		flat = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	end
	if flat.Magnitude < 0.1 or not finiteComponent(flat.X) or not finiteComponent(flat.Z) then
		flat = Vector3.new(0, 0, -1)
	end
	flat = flat.Unit

	cooldowns[player] = now + COOLDOWN
	player:SetAttribute("DodgeCooldownEnd", now + COOLDOWN)
	player:SetAttribute("DodgeInvulnerable", true)
	player:SetAttribute("DodgeMessage", "Dodge!")

	clearForceField(character)
	local forceField = Instance.new("ForceField")
	forceField.Name = "CrystalBoundDodgeForceField"
	forceField.Visible = false
	forceField.Parent = character

	root.AssemblyLinearVelocity = Vector3.new(flat.X * BOOST, root.AssemblyLinearVelocity.Y, flat.Z * BOOST)

	task.delay(INVULNERABILITY, function()
		if player.Parent then
			player:SetAttribute("DodgeInvulnerable", false)
			if player.Character == character then clearForceField(character) end
		end
	end)
	return true
end

function DodgeService.IsInvulnerable(player)
	return player and player:IsA("Player") and player:GetAttribute("DodgeInvulnerable") == true
end

function DodgeService.ApplyDamage(player, humanoid, amount)
	if not player or not humanoid or humanoid.Health <= 0 then return false end
	if DodgeService.IsInvulnerable(player) then
		player:SetAttribute("DodgeMessage", "Dodged!")
		return false
	end
	local damage = finiteDamage(amount)
	if not damage or damage <= 0 then return false end
	humanoid:TakeDamage(math.clamp(damage, 0, 1000))
	return true
end

function DodgeService.CleanupPlayer(player)
	cooldowns[player] = nil
	if player.Character then clearForceField(player.Character) end
	if player.Parent then
		player:SetAttribute("DodgeInvulnerable", false)
		player:SetAttribute("DodgeCooldownEnd", 0)
	end
end

local function resetForRespawn(player)
	cooldowns[player] = 0
	if player.Parent then
		player:SetAttribute("DodgeInvulnerable", false)
		player:SetAttribute("DodgeCooldownEnd", 0)
	end
	if player.Character then clearForceField(player.Character) end
end

local function bindPlayer(player)
	player.CharacterAdded:Connect(function()
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
