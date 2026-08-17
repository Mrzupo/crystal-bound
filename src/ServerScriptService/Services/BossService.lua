local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local BossConfig = require(ReplicatedStorage.Config.BossConfig)
local InventoryService = require(script.Parent.InventoryService)

local BossService = {
	Bound = false,
}

function BossService.GetConfig(id)
	return BossConfig[id]
end

function BossService.IsBoss(model)
	return model and model:GetAttribute("BossId") ~= nil
end

function BossService.RewardDefeat(player, model, EconomyService, XPService, PlayerService)
	local bossId = model and model:GetAttribute("BossId")
	local config = bossId and BossConfig[bossId]
	if not config or model:GetAttribute("BossRewarded") then return false end
	model:SetAttribute("BossRewarded", true)
	local profile = PlayerService.GetProfile(player)
	if not profile then return false end
	XPService.AddXP(profile, config.XP)
	EconomyService.AddMoney(profile, config.Money)
	if config.Drop then InventoryService.AddItem(profile, config.Drop, 1) end
	PlayerService.Sync(player)
	player:SetAttribute("BossMessage", config.DisplayName .. " defeated! +" .. config.XP .. " XP")
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes and remotes:FindFirstChild("InventoryChanged") then
		remotes.InventoryChanged:FireClient(player, profile.Inventory)
	end
	return true
end

local function nearestPlayer(position, range)
	local nearest, nearestDistance
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			local distance = (root.Position - position).Magnitude
			if distance <= range and (not nearestDistance or distance < nearestDistance) then
				nearest = player
				nearestDistance = distance
			end
		end
	end
	return nearest, nearestDistance
end

local function pulseEffect(position, radius)
	local effect = Instance.new("Part")
	effect.Name = "GuardianShockwave"
	effect.Shape = Enum.PartType.Ball
	effect.Anchored = true
	effect.CanCollide = false
	effect.CanTouch = false
	effect.CanQuery = false
	effect.Material = Enum.Material.Neon
	effect.Transparency = 0.2
	effect.Size = Vector3.new(4, 4, 4)
	effect.Position = position
	effect.Color = Color3.fromRGB(190, 140, 255)
	effect.Parent = Workspace
	TweenService:Create(effect, TweenInfo.new(0.35), { Size = Vector3.new(radius * 2, radius * 2, radius * 2), Transparency = 1 }):Play()
	Debris:AddItem(effect, 0.4)
end

local function attachGuardian(model)
	if not model or model:GetAttribute("BossBound") then return end
	local bossId = model:GetAttribute("BossId") or "CrystalGuardian"
	local config = BossConfig[bossId]
	if not config then return end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	if not humanoid or not root then return end
	model:SetAttribute("BossBound", true)
	model:SetAttribute("BossPhase", 1)
	model:SetAttribute("BossId", bossId)

	local attackAt = 0
	local abilityAt = 0
	task.spawn(function()
		while model.Parent and humanoid.Health > 0 do
			local phase = humanoid.Health <= humanoid.MaxHealth * 0.5 and 2 or 1
			model:SetAttribute("BossPhase", phase)
			local target, distance = nearestPlayer(root.Position, config.AggroRange)
			if target and distance then
				local character = target.Character
				local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
				local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
				if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
					if distance > config.AttackRange then
						local direction = targetRoot.Position - root.Position
						if direction.Magnitude > 0.1 then
							model:PivotTo(CFrame.lookAt(root.Position + direction.Unit * math.min(1, direction.Magnitude), targetRoot.Position))
						end
					elseif os.clock() >= attackAt then
						attackAt = os.clock() + (phase == 2 and config.AttackCooldown * 0.75 or config.AttackCooldown)
						targetHumanoid:TakeDamage(phase == 2 and config.AttackDamage + 10 or config.AttackDamage)
					end

					if os.clock() >= abilityAt then
						abilityAt = os.clock() + (phase == 2 and config.AbilityCooldown * 0.7 or config.AbilityCooldown)
						local radius = config.AbilityRadius + (phase == 2 and 4 or 0)
						local damage = config.AbilityDamage + (phase == 2 and 15 or 0)
						pulseEffect(root.Position, radius)
						for _, player in ipairs(Players:GetPlayers()) do
							local char = player.Character
							local playerRoot = char and char:FindFirstChild("HumanoidRootPart")
							local playerHumanoid = char and char:FindFirstChildOfClass("Humanoid")
							if playerRoot and playerHumanoid and playerHumanoid.Health > 0 and (playerRoot.Position - root.Position).Magnitude <= radius then
								playerHumanoid:TakeDamage(damage)
								player:SetAttribute("BossMessage", config.DisplayName .. " unleashed a shockwave!")
							end
						end
					end
				end
			end
			task.wait(0.15)
		end
	end)

	humanoid.Died:Connect(function()
		model:SetAttribute("BossDefeated", true)
		local center = root.Position
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
			if playerRoot and (playerRoot.Position - center).Magnitude <= 100 then
				player:SetAttribute("BossMessage", config.DisplayName .. " defeated! Claim your reward!")
			end
		end
	end)
end

function BossService.Bind()
	if BossService.Bound then return end
	BossService.Bound = true
	task.spawn(function()
		while true do
			local folder = Workspace:FindFirstChild("NPCs")
			local guardian = folder and folder:FindFirstChild("CrystalGuardian")
			if guardian then attachGuardian(guardian) end
			task.wait(1)
		end
	end)
end

function BossService.ClearPlayer(player)
	return player and Players:GetPlayerFromCharacter(player.Character) == player
end

return BossService
