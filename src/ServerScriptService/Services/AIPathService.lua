local PathfindingService = game:GetService("PathfindingService")

local AIPathService = {}
local cache = setmetatable({}, { __mode = "k" })

local function keyFor(goal)
	return string.format("%d:%d:%d", math.floor(goal.X / 4), math.floor(goal.Y / 4), math.floor(goal.Z / 4))
end

function AIPathService.GetNextDirection(model, destination)
	if not model or not model.PrimaryPart or typeof(destination) ~= "Vector3" then return nil end
	local root = model.PrimaryPart
	local cacheEntry = cache[model]
	local key = keyFor(destination)
	if cacheEntry and cacheEntry.key == key and cacheEntry.waypointIndex and cacheEntry.waypoints[cacheEntry.waypointIndex] then
		local waypoint = cacheEntry.waypoints[cacheEntry.waypointIndex]
		if (root.Position - waypoint.Position).Magnitude < 3 then
			cacheEntry.waypointIndex += 1
			waypoint = cacheEntry.waypoints[cacheEntry.waypointIndex]
		end
		if waypoint then return waypoint.Position - root.Position end
	end

	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		WaypointSpacing = 4,
	})
	local ok = pcall(function()
		path:ComputeAsync(root.Position, destination)
	end)
	if not ok or path.Status ~= Enum.PathStatus.Success then
		cache[model] = nil
		return nil
	end

	local waypoints = path:GetWaypoints()
	if #waypoints < 2 then return nil end
	cache[model] = { key = key, waypoints = waypoints, waypointIndex = 2 }
	local waypoint = waypoints[2]
	if waypoint.Action == Enum.PathWaypointAction.Jump then
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.Jump = true end
	end
	return waypoint.Position - root.Position
end

function AIPathService.Clear(model)
	cache[model] = nil
end

return AIPathService
