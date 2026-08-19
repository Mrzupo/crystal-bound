local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local MovementConfig = require(ReplicatedStorage.Config.MovementConfig)

local ENFORCEMENT_INTERVAL = 0.25
local BASE_WALK_SPEED = math.max(1, tonumber(MovementConfig.BaseWalkSpeed) or 16)
local MIN_WALK_SPEED = math.max(1, tonumber(MovementConfig.MinWalkSpeed) or 6)
local MIN_SLOW_MULTIPLIER = math.clamp(tonumber(MovementConfig.MinSlowMultiplier) or 0.2, 0.01, 1)
local MAX_SLOW_MULTIPLIER = math.clamp(tonumber(MovementConfig.MaxSlowMultiplier) or 1, MIN_SLOW_MULTIPLIER, 10)
local MAX_OBSERVED_SPEED = math.clamp(tonumber(MovementConfig.MaxObservedSpeed) or 90, 16, 200)
local EXTRA_DISTANCE_TOLERANCE = math.clamp(tonumber(MovementConfig.ExtraDistanceTolerance) or 12, 2, 50)
local POSITION_CHECK_INTERVAL = math.clamp(tonumber(MovementConfig.PositionCheckInterval) or 0.15, 0.05, 1)
local PORTAL_ARRIVAL_TOLERANCE = math.clamp(tonumber(MovementConfig.PortalArrivalTolerance) or 18, 4, 50)
local PORTAL_GRACE_DURATION = math.clamp(tonumber(MovementConfig.PortalGraceDuration) or 1.5, 0.25, 5)
local SPEED_EPSILON = 0.05
local PORTAL_DESTINATIONS = {
	TidePortal = Vector3.new(120, 4, 0),
	StarterPortal = Vector3.new(48, 4, 0),
	WindPortal = Vector3.new(280, 4, 0),
	TideReturnPortal = Vector3.new(210, 4, 0),
	AncientPortal = Vector3.new(440, 4, 0),
	WindReturnPortal = Vector3.new(380, 4, 0),
}
local connections = setmetatable({}, { __mode = "k" })
local humanoidConnections = setmetatable({}, { __mode = "k" })
local positionState = setmetatable({}, { __mode = "k" })
local portalConnections = setmetatable({}, { __mode = "k" })

local function finiteNumber(value, fallback)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return fallback end
	return number
end

local function getHumanoid(player)
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRoot(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function resetPositionState(player)
	local root = getRoot(player)
	positionState[player] = {
		Character = player.Character,
		Position = root and root.Position or nil,
		Timestamp = os.clock(),
	}
end

local function consumePortalArrival(player)
	player:SetAttribute("PortalMovementGraceUntil", 0)
	player:SetAttribute("PortalExpectedDestination", nil)
	resetPositionState(player)
end

local function isValidPortalArrival(player, root, now)
	local untilTime = finiteNumber(player:GetAttribute("PortalMovementGraceUntil"), 0)
	if untilTime <= now then return false end
	local destination = player:GetAttribute("PortalExpectedDestination")
	if typeof(destination) ~= "Vector3" then return false end
	return (root.Position - destination).Magnitude <= PORTAL_ARRIVAL_TOLERANCE
end

local function armPortalArrival(player, destination)
	if not player or not player.Parent or typeof(destination) ~= "Vector3" then return end
	local root = getRoot(player)
	if not root then return end
	if (root.Position - destination).Magnitude > PORTAL_ARRIVAL_TOLERANCE then return end
	player:SetAttribute("PortalExpectedDestination", destination)
	player:SetAttribute("PortalMovementGraceUntil", os.clock() + PORTAL_GRACE_DURATION)
	resetPositionState(player)
end

local function attachPortal(portal)
	if not portal or not portal:IsA("BasePart") or portalConnections[portal] or not PORTAL_DESTINATIONS[portal.Name] then return end
	portalConnections[portal] = portal.Touched:Connect(function(hit)
		local character = hit and hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		local destination = portal and PORTAL_DESTINATIONS[portal.Name]
		if not player or not destination then return end
		task.defer(function()
			if portal.Parent and player.Parent and player.Character == character then
				armPortalArrival(player, destination)
			end
		end)
	end)
end

local function scanPortals()
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("BasePart") and PORTAL_DESTINATIONS[descendant.Name] then
			attachPortal(descendant)
		end
	end
end

local function enforcePosition(player, now)
	if not player.Parent then return end
	local humanoid = getHumanoid(player)
	local root = getRoot(player)
	if not humanoid or humanoid.Health <= 0 or not root then
		if positionState[player] and positionState[player].Character ~= player.Character then
			resetPositionState(player)
		end
		return
	end

	local snapshot = positionState[player]
	if not snapshot or snapshot.Character ~= player.Character or not snapshot.Position then
		resetPositionState(player)
		return
	end

	local sampleDt = math.max(0.05, now - snapshot.Timestamp)
	local displacement = (root.Position - snapshot.Position).Magnitude
	local allowed = MAX_OBSERVED_SPEED * sampleDt + EXTRA_DISTANCE_TOLERANCE

	if displacement > allowed then
		if isValidPortalArrival(player, root, now) then
			player:SetAttribute("MovementCorrection", false)
			consumePortalArrival(player)
			return
		end
		root.CFrame = CFrame.new(snapshot.Position)
		root.AssemblyLinearVelocity = Vector3.zero
		player:SetAttribute("MovementCorrection", true)
	else
		player:SetAttribute("MovementCorrection", false)
		positionState[player] = {
			Character = player.Character,
			Position = root.Position,
			Timestamp = now,
		}
	end
end

local function refresh(player)
	if not player.Parent then return end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	local base = BASE_WALK_SPEED + math.max(0, finiteNumber(player:GetAttribute("WalkSpeedBonus"), 0))
	local expected = math.max(MIN_WALK_SPEED, base)
	local slow = finiteNumber(humanoid:GetAttribute("CrystalBoundSlowMultiplier"), nil)
	if slow and slow > 0 then
		expected = math.max(MIN_WALK_SPEED, base * math.clamp(slow, MIN_SLOW_MULTIPLIER, MAX_SLOW_MULTIPLIER))
	end

	if math.abs(humanoid.WalkSpeed - expected) > SPEED_EPSILON then
		humanoid.WalkSpeed = expected
	end
end

local function disconnectHumanoid(player)
	local connection = humanoidConnections[player]
	if connection and connection.Connected then connection:Disconnect() end
	humanoidConnections[player] = nil
end

local function cleanup(player)
	disconnectHumanoid(player)
	local playerConnections = connections[player]
	if playerConnections then
		for _, connection in ipairs(playerConnections) do
			if connection.Connected then connection:Disconnect() end
		end
	end
	connections[player] = nil
	positionState[player] = nil
	player:SetAttribute("PortalMovementGraceUntil", 0)
	player:SetAttribute("PortalExpectedDestination", nil)
end

local function watchCharacter(player, character)
	if player.Character ~= character then return end
	disconnectHumanoid(player)
	resetPositionState(player)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	humanoidConnections[player] = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		refresh(player)
	end)
	refresh(player)
end

local function bind(player)
	cleanup(player)
	local playerConnections = {}
	connections[player] = playerConnections

	local function deferredRefresh()
		task.defer(function() refresh(player) end)
	end

	table.insert(playerConnections, player:GetAttributeChangedSignal("WalkSpeedBonus"):Connect(deferredRefresh))
	table.insert(playerConnections, player:GetAttributeChangedSignal("EquippedCrystal"):Connect(deferredRefresh))
	table.insert(playerConnections, player:GetAttributeChangedSignal("CrystalMasteryLevel"):Connect(deferredRefresh))
	table.insert(playerConnections, player.CharacterAdded:Connect(function(character)
		task.defer(function()
			watchCharacter(player, character)
		end)
	end))

	if player.Character then
		task.defer(function()
			watchCharacter(player, player.Character)
		end)
	end
end

Players.PlayerAdded:Connect(bind)
Players.PlayerRemoving:Connect(cleanup)
Workspace.DescendantAdded:Connect(attachPortal)
scanPortals()
for _, player in ipairs(Players:GetPlayers()) do bind(player) end

task.spawn(function()
	local positionElapsed = 0
	while true do
		local dt = task.wait(ENFORCEMENT_INTERVAL)
		positionElapsed += dt
		local now = os.clock()
		for _, player in ipairs(Players:GetPlayers()) do
			refresh(player)
			if positionElapsed >= POSITION_CHECK_INTERVAL then
				enforcePosition(player, now)
			end
		end
		if positionElapsed >= POSITION_CHECK_INTERVAL then positionElapsed = 0 end
	end
end)
