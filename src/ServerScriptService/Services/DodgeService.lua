local Players = game:GetService("Players")

local DodgeService = {}
local cooldowns = {}

local COOLDOWN = 2.5
local INVULNERABILITY = 0.45
local BOOST = 42

function DodgeService.TryDodge(player, direction)
	if not player or not player:IsA("Player") then return false, "Invalid player" end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then return false, "Not ready" end

	local now = os.clock()
	local nextReady = cooldowns[player] or 0
	if now < nextReady then return false, "Dodge on cooldown" end

	local requested = typeof(direction) == "Vector3" and direction or Vector3.new(0, 0, -1)
	local flat = Vector3.new(requested.X, 0, requested.Z)
	if flat.Magnitude < 0.1 then flat = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z) end
	flat = flat.Unit

	cooldowns[player] = now + COOLDOWN
	player:SetAttribute("DodgeCooldownEnd", now + COOLDOWN)
	player:SetAttribute("DodgeInvulnerable", true)
	player:SetAttribute("DodgeMessage", "Dodge!")
	root.AssemblyLinearVelocity = Vector3.new(flat.X * BOOST, root.AssemblyLinearVelocity.Y, flat.Z * BOOST)

	task.delay(INVULNERABILITY, function()
		if player.Parent then player:SetAttribute("DodgeInvulnerable", false) end
	end)
	return true
end

function DodgeService.CleanupPlayer(player)
	cooldowns[player] = nil
	if player.Parent then player:SetAttribute("DodgeInvulnerable", false) end
end

Players.PlayerRemoving:Connect(function(player)
	DodgeService.CleanupPlayer(player)
end)

return DodgeService
