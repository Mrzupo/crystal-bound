local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local combatFeedback = remotes:WaitForChild("CombatFeedback")
local vfx = require(script.Parent:WaitForChild("CrystalVFXController"))

combatFeedback.OnClientEvent:Connect(function(_, attackerUserId, action, crystalId)
	if attackerUserId ~= player.UserId then return end
	if type(action) ~= "string" or (action ~= "Basic" and action ~= "Ability") then return end
	if type(crystalId) ~= "string" then return end

	player:SetAttribute("CrystalVFXAuthorizedAt", os.clock())
	player:SetAttribute("CrystalVFXAuthorizedAction", action)
	player:SetAttribute("CrystalVFXAuthorizedCrystal", crystalId)
	vfx.Play(action, crystalId)
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
	if leavingPlayer == player then
		player:SetAttribute("CrystalVFXAuthorizedAt", nil)
		player:SetAttribute("CrystalVFXAuthorizedAction", nil)
		player:SetAttribute("CrystalVFXAuthorizedCrystal", nil)
	end
end)
