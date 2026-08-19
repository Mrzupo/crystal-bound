local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Config.MovementAuthorityConfig)

local MAX_OBSERVED_SPEED = math.clamp(tonumber(Config.MaxObservedSpeed) or 90, 16, 200)
local EXTRA_TOLERANCE = math.clamp(tonumber(Config.ExtraDistanceTolerance) or 12, 2, 50)
local GRACE_DURATION = math.clamp(tonumber(Config.GraceDuration) or 0.6, 0.1, 3)
local CHECK_INTERVAL = math.clamp(tonumber(Config.CheckInterval) or 0.15, 0.05, 1)

local state = setmetatable({}, { __mode = "k" })

local function finiteNumber(value, fallback)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return fallback end
	return number
end

local function getRoot(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then return nil end
	return root
end

local function reset(player)
	local root = getRoot(player)
	state[player] = {
		Character = player.Character,
		Position = root and root.Position or nil,
		Timestamp = os.clock(),
	}
end

local function hasGrace(player, now)
	local untilTime = finiteNumber(player:GetAttribute("ServerMovementGraceUntil"), 0)
	return untilTime > now
end

local function bind(player)
	state[player] = nil
	player.CharacterAdded:Connect(function()
		task.defer(reset, player)
	end)
	player:GetAttributeChangedSignal("ServerMovementGraceUntil"):Connect(function()
		if hasGrace(player, os.clock()) then reset(player) end
	end)
	reset(player)
end

local function cleanup(player)
	state[player] = nil
end

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < CHECK_INTERVAL then return end
	local now = os.clock()
	elapsed = 0

	for _, player in ipairs(Players:GetPlayers()) do
		local root = getRoot(player)
		local snapshot = state[player]
		if not root then
			if snapshot and player.Character ~= snapshot.Character then reset(player) end
			continue
		end

		if not snapshot or snapshot.Character ~= player.Character or not snapshot.Position then
			state[player] = { Character = player.Character, Position = root.Position, Timestamp = now }
			continue
		end

		local sampleDt = math.max(0.05, now - snapshot.Timestamp)
		local displacement = (root.Position - snapshot.Position).Magnitude
		local allowed = MAX_OBSERVED_SPEED * sampleDt + EXTRA_TOLERANCE

		if not hasGrace(player, now) and displacement > allowed then
			root.CFrame = CFrame.new(snapshot.Position)
			root.AssemblyLinearVelocity = Vector3.zero
			player:SetAttribute("MovementCorrection", true)
		else
			player:SetAttribute("MovementCorrection", false)
			state[player] = {
				Character = player.Character,
				Position = root.Position,
				Timestamp = now,
			}
		end
	end
end)

Players.PlayerAdded:Connect(bind)
Players.PlayerRemoving:Connect(cleanup)
for _, player in ipairs(Players:GetPlayers()) do bind(player) end
