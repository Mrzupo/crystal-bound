local Players = game:GetService("Players")

local ENFORCEMENT_INTERVAL = 0.25
local connections = setmetatable({}, { __mode = "k" })

local function refresh(player)
	if not player.Parent then return end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	local slow = tonumber(humanoid:GetAttribute("CrystalBoundSlowMultiplier"))
	if not slow or slow <= 0 then return end
	local base = 16 + math.max(0, tonumber(player:GetAttribute("WalkSpeedBonus")) or 0)
	humanoid.WalkSpeed = math.max(6, base * math.clamp(slow, 0.2, 1))
end

local function cleanup(player)
	local playerConnections = connections[player]
	if not playerConnections then return end
	for _, connection in ipairs(playerConnections) do
		if connection.Connected then connection:Disconnect() end
	end
	connections[player] = nil
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
	table.insert(playerConnections, player.CharacterAdded:Connect(function()
		task.defer(function() refresh(player) end)
	end))
end

Players.PlayerAdded:Connect(bind)
Players.PlayerRemoving:Connect(cleanup)
for _, player in ipairs(Players:GetPlayers()) do bind(player) end

task.spawn(function()
	while true do
		task.wait(ENFORCEMENT_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 and humanoid:GetAttribute("CrystalBoundSlowMultiplier") ~= nil then
				refresh(player)
			end
		end
	end
end
