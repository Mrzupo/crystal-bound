local Players = game:GetService("Players")

local function refresh(player, humanoid)
	if not player.Parent or not humanoid or not humanoid.Parent or humanoid.Health <= 0 then return end
	local slow = tonumber(humanoid:GetAttribute("CrystalBoundSlowMultiplier"))
	if not slow or slow <= 0 then return end
	local base = 16 + math.max(0, tonumber(player:GetAttribute("WalkSpeedBonus")) or 0)
	humanoid.WalkSpeed = math.max(6, base * math.clamp(slow, 0.2, 1))
end

local function bind(player)
	local function bindCharacter(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
		if not humanoid then return end
		local function deferredRefresh()
			task.defer(function() refresh(player, humanoid) end)
		end
		player:GetAttributeChangedSignal("WalkSpeedBonus"):Connect(deferredRefresh)
		player:GetAttributeChangedSignal("EquippedCrystal"):Connect(deferredRefresh)
		player:GetAttributeChangedSignal("CrystalMasteryLevel"):Connect(deferredRefresh)
		humanoid:GetAttributeChangedSignal("CrystalBoundSlowMultiplier"):Connect(deferredRefresh)
		deferredRefresh()
	end
	if player.Character then bindCharacter(player.Character) end
	player.CharacterAdded:Connect(bindCharacter)
end

Players.PlayerAdded:Connect(bind)
for _, player in ipairs(Players:GetPlayers()) do bind(player) end
