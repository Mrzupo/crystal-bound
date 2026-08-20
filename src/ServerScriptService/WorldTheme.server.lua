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

local function finiteNumber(value, fallback)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return fallback end
	return number
end

local portalGrace = math.clamp(finiteNumber(MovementConfig.GraceDuration, 0.6), 0.1, 5)
local portalTolerance = math.clamp(finiteNumber(MovementConfig.PortalArrivalTolerance, 18), 4, 50)
local portalCooldownDuration = 1
local portalCandidates = setmetatable({}, { __mode = "k" })
local portalCooldowns = setmetatable({}, { __mode = "k" })
local portalCooldownTokens = setmetatable({}, { __mode = "k" })
local lastPositions = setmetatable({}, { __mode = "k" })
local portalConnections = setmetatable({}, { __mode = "k" })
local playerCharacterConnections = setmetatable({}, { __mode = "k" })

local function getRoot(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function getLoadedProfileForPortal(player)
	if not player.Parent or PlayerService.ShuttingDown or PlayerService.Closing[player] then return nil end
	return PlayerService.Profiles[player]
end

local function rememberPosition(player)
	local root = getRoot(player)
	if root then
		lastPositions[player] = { Character = player.Character, Position = root.Position, Timestamp = os.clock() }
	end
end

local function clearPortalState(player)
	portalCooldownTokens[player] = (portalCooldownTokens[player] or 0) + 1
	portalCandidates[player] = nil
	portalCooldowns[player] = nil
	player:SetAttribute("PortalMovementGraceUntil", 0)
	player:SetAttribute("PortalExpectedDestination", nil)
end

local function tryArmArrival(player, character, destination, beforePosition, requiredLevel)
	if not player.Parent or player.Character ~= character then return end
	local profile = getLoadedProfileForPortal(player)
	if not profile or profile.Level < requiredLevel then return end
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local displacement = (root.Position - beforePosition).Magnitude
	local destinationError = (root.Position - destination).Magnitude
	if destinationError > portalTolerance or displacement <= math.max(2, portalTolerance * 0.25) then return end
	player:SetAttribute("PortalExpectedDestination", destination)
	player:SetAttribute("PortalMovementGraceUntil", os.clock() + portalGrace)
	portalCandidates[player] = nil
end

local function disconnectPlayerCharacter(player)
	local connection = playerCharacterConnections[player]
	if connection and connection.Connected then connection:Disconnect() end
	playerCharacterConnections[player] = nil
end

local function bindPortal(portal)
	if not portal:IsA("BasePart") then return end
	local target = portalTargets[portal.Name]
	if not target or portalConnections[portal] then return end
	portalConnections[portal] = portal.Touched:Connect(function(hit)
		local character = hit and hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player or player.Character ~= character or portalCooldowns[player] then return end
		local profile = getLoadedProfileForPortal(player)
		if not profile or profile.Level < target.RequiredLevel then return end
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return end

		local cooldownToken = (portalCooldownTokens[player] or 0) + 1
		portalCooldownTokens[player] = cooldownToken
		portalCooldowns[player] = true
		task.delay(portalCooldownDuration, function()
			if player.Parent and portalCooldownTokens[player] == cooldownToken then
				portalCooldowns[player] = nil
			end
		end)

		local snapshot = lastPositions[player]
		local beforePosition = snapshot and snapshot.Character == character and snapshot.Position or root.Position
		portalCandidates[player] = {
			Character = character,
			Destination = target.Destination,
			RequiredLevel = target.RequiredLevel,
			BeforePosition = beforePosition,
			ExpiresAt = os.clock() + math.max(0.5, portalGrace + 0.5),
		}

		root.CFrame = CFrame.new(target.Destination)
		root.AssemblyLinearVelocity = Vector3.zero
		tryArmArrival(player, character, target.Destination, beforePosition, target.RequiredLevel)

		task.defer(function()
			local candidate = portalCandidates[player]
			if not candidate or candidate.Character ~= character or candidate.Destination ~= target.Destination then return end
			if os.clock() > candidate.ExpiresAt then portalCandidates[player] = nil; return end
			tryArmArrival(player, character, candidate.Destination, candidate.BeforePosition, candidate.RequiredLevel)
		end)
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

Players.PlayerRemoving:Connect(function(player)
	disconnectPlayerCharacter(player)
	clearPortalState(player)
	lastPositions[player] = nil
end)

bindExistingPortals()
islands.DescendantAdded:Connect(bindPortal)

local function bindPlayer(player)
	disconnectPlayerCharacter(player)
	clearPortalState(player)
	rememberPosition(player)
	playerCharacterConnections[player] = player.CharacterAdded:Connect(function(character)
		clearPortalState(player)
		task.defer(function()
			if player.Parent and player.Character == character then rememberPosition(player) end
		end)
	end)
end

for _, player in ipairs(Players:GetPlayers()) do bindPlayer(player) end
Players.PlayerAdded:Connect(bindPlayer)

task.spawn(function()
	while islands.Parent do
		local now = os.clock()
		for _, player in ipairs(Players:GetPlayers()) do
			local root = getRoot(player)
			if root then lastPositions[player] = { Character = player.Character, Position = root.Position, Timestamp = now } end
		end
		for player, candidate in pairs(portalCandidates) do
			if now > candidate.ExpiresAt then
				portalCandidates[player] = nil
			elseif player.Parent and player.Character == candidate.Character then
				tryArmArrival(player, candidate.Character, candidate.Destination, candidate.BeforePosition, candidate.RequiredLevel)
			end
		end
		task.wait(0.1)
	end
end)

print("Crystal Bound world themes and portal movement authority ready")
