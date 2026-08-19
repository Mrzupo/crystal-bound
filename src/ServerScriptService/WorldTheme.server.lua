local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local islands = Workspace:WaitForChild("Islands")
local PlayerService = require(script.Parent.Services.PlayerService)
local WorldConfig = require(ReplicatedStorage.Config.WorldConfig)
local MovementConfig = require(ReplicatedStorage.Config.MovementConfig)

local themes = {
	StarterIsland = { Material = Enum.Material.Grass },
	TideIsland = { Material = Enum.Material.Sand },
	WindIsland = { Material = Enum.Material.Slate },
	AncientRuins = { Material = Enum.Material.Rock },
}

local portalTargets = {
	TidePortal = { Destination = Vector3.new(120, 4, 0), RequiredLevel = WorldConfig.Islands.TIDE.Level },
	StarterPortal = { Destination = Vector3.new(48, 4, 0), RequiredLevel = WorldConfig.Islands.STARTER.Level },
	WindPortal = { Destination = Vector3.new(280, 4, 0), RequiredLevel = WorldConfig.Islands.WIND.Level },
	TideReturnPortal = { Destination = Vector3.new(210, 4, 0), RequiredLevel = WorldConfig.Islands.TIDE.Level },
	AncientPortal = { Destination = Vector3.new(440, 4, 0), RequiredLevel = WorldConfig.Islands.ANCIENT.Level },
	WindReturnPortal = { Destination = Vector3.new(380, 4, 0), RequiredLevel = WorldConfig.Islands.WIND.Level },
}

local portalGrace = math.clamp(tonumber(MovementConfig.GraceDuration) or 0.6, 0.1, 3)
local portalConnections = {}

local function bindPortal(portal)
	if not portal:IsA("BasePart") then return end
	local target = portalTargets[portal.Name]
	if not target or portalConnections[portal] then return end
	portalConnections[portal] = portal.Touched:Connect(function(hit)
		local character = hit and hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then return end
		local profile = PlayerService.GetProfile(player)
		if not profile or profile.Level < target.RequiredLevel then return end
		player:SetAttribute("PortalExpectedDestination", target.Destination)
		player:SetAttribute("PortalMovementGraceUntil", os.clock() + portalGrace)
	end)
end

local function bindExistingPortals()
	for _, island in ipairs(islands:GetChildren()) do
		for _, descendant in ipairs(island:GetDescendants()) do bindPortal(descendant) end
	end
end

for islandName, theme in pairs(themes) do
	local island = islands:WaitForChild(islandName, 30)
	if not island then
		warn(("Crystal Bound: world theme island missing after 30s: %s"):format(islandName))
		continue
	end

	local ground = island:FindFirstChild("Ground")
	if not ground or not ground:IsA("BasePart") then
		warn(("Crystal Bound: world theme ground missing for island: %s"):format(islandName))
		continue
	end

	ground.Material = theme.Material
end

bindExistingPortals()
islands.DescendantAdded:Connect(bindPortal)

print("Crystal Bound world themes and portal movement authority ready")
