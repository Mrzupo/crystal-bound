local PathfindingService = game:GetService("PathfindingService")

local AIPathService = {}
local cache = setmetatable({}, { __mode = "k" })
local RECOMPUTE_INTERVAL = 0.5

local function finiteNumber(value)
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function isFiniteVector3(value)
	return typeof(value) == "Vector3"
		and finiteNumber(value.X)
		and finiteNumber(value.Y)
		and finiteNumber(value.Z)
end

local function keyFor(goal)
	return string.format("%d:%d:%d", math.floor(goal.X / 4), math.floor(goal.Y / 4), math.floor(goal.Z / 4))
end

local function applyWaypointAction(model, waypoint)
	if not model or not waypoint or waypoint.Action ~= Enum.PathWaypointAction.Jump then return end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.Jump = true end
end

function AIPathService.GetNextDirection(model, destination)
	if not model or not model.PrimaryPart or not isFiniteVector3(destination) then return nil end
	local root = model.PrimaryPart
	local rootPosition = root.Position
	if not isFiniteVector3(rootPosition) then return nil end

	local now = os.clock()
	local cacheEntry = cache[model]
	local key = keyFor(destination)
	if cacheEntry and cacheEntry.key == key and cacheEntry.waypointIndex and cacheEntry.waypoints[cacheEntry.waypointIndex] then
		local waypoint = cacheEntry.waypoints[cacheEntry.waypointIndex]
		if (rootPosition - waypoint.Position).Magnitude < 3 then
			cacheEntry.waypointIndex += 1
			waypoint = cacheEntry.waypoints[cacheEntry.waypointIndex]
		end
		if waypoint then
			applyWaypointAction(model, waypoint)
			return waypoint.Position - rootPosition
		end
	end
	if cacheEntry and cacheEntry.key == key and (now - (cacheEntry.computedAt or 0)) < RECOMPUTE_INTERVAL then
		return nil
	end

	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		WaypointSpacing = 4,
	})
	local ok = pcall(function()
		path:ComputeAsync(rootPosition, destination)
	end)
	if not ok or path.Status ~= Enum.PathStatus.Success then
		cache[model] = { key = key, waypoints = {}, waypointIndex = nil, computedAt = now }
		return nil
	end

	local waypoints = path:GetWaypoints()
	if #waypoints < 2 then
		cache[model] = { key = key, waypoints = {}, waypointIndex = nil, computedAt = now }
		return nil
	end
	cache[model] = { key = key, waypoints = waypoints, waypointIndex = 2, computedAt = now }
	local waypoint = waypoints[2]
	applyWaypointAction(model, waypoint)
	return waypoint.Position - rootPosition
end

function AIPathService.Clear(model)
	cache[model] = nil
end

return AIPathService
