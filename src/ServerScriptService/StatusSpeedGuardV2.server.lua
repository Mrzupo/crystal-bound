local Players = game:GetService("Players")

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

local function bind(player)
	local function deferredRefresh()
		task.defer(function() refresh(player) end)
	end

	player:GetAttributeChangedSignal("WalkSpeedBonus"):Connect(deferredRefresh)
	player:GetAttributeChangedSignal("EquippedCrystal"):Connect(deferredRefresh)
	player:GetAttributeChangedSignal("CrystalMasteryLevel"):Connect(deferredRefresh)
	player.CharacterAdded:Connect(function()
		task.defer(function() refresh(player) end)
	end)
end

Players.PlayerAdded:Connect(bind)
for _, player in ipairs(Players:GetPlayers()) do bind(player) end
