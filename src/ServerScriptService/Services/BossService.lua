local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local BossConfig = require(ReplicatedStorage.Config.BossConfig)
local InventoryService = require(script.Parent.InventoryService)
local EconomyService = require(script.Parent.EconomyService)
local XPService = require(script.Parent.XPService)
local QuestSystem = require(ReplicatedStorage.Modules.QuestSystem)
local QuestService = require(script.Parent.QuestService)
local DodgeService = require(script.Parent.DodgeService)
local BossService = { Bound = false }

local function shockwave(center, radius, damage, ignoreModel)
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root and (root.Position - center).Magnitude <= radius then
			DodgeService.ApplyDamage(player, humanoid, math.max(0, damage))
		end
	end

	local folder = workspace:FindFirstChild("NPCs")
	if folder then
		for _, child in ipairs(folder:GetChildren()) do
			if child ~= ignoreModel and child:GetAttribute("Enemy") == true and not child:GetAttribute("BossId") then
				local humanoid = child:FindFirstChildOfClass("Humanoid")
				local root = child:FindFirstChild("HumanoidRootPart") or child.PrimaryPart
				if humanoid and humanoid.Health > 0 and root and (root.Position - center).Magnitude <= radius then
					humanoid:TakeDamage(damage)
				end
			end
		end
	end

	local effect = Instance.new("Part")
	effect.Anchored = true; effect.CanCollide = false; effect.CanTouch = false; effect.CanQuery = false
	effect.Shape = Enum.PartType.Cylinder; effect.Size = Vector3.new(1, radius * 2, radius * 2)
	effect.CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90)); effect.Material = Enum.Material.Neon
	effect.Transparency = 0.2; effect.Color = Color3.fromRGB(170, 120, 255); effect.Parent = workspace
	TweenService:Create(effect, TweenInfo.new(0.35), { Transparency = 1, Size = Vector3.new(1, radius * 2.6, radius * 2.6) }):Play()
	Debris:AddItem(effect, 0.4)
end

local function attachBossHealthBar(model, humanoid, root)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BossHealthBar"
	billboard.Adornee = root
	billboard.Size = UDim2.fromOffset(240, 46)
	billboard.StudsOffset = Vector3.new(0, 6.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = root

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 20)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.Parent = billboard

	local back = Instance.new("Frame")
	back.Position = UDim2.fromOffset(0, 22)
	back.Size = UDim2.new(1, 0, 0, 14)
	back.Parent = billboard
	Instance.new("UICorner", back).CornerRadius = UDim.new(0, 5)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.Parent = back
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 5)

	local function update()
		local ratio = math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1)
		fill.Size = UDim2.fromScale(ratio, 1)
		title.Text = string.format("%s  •  Phase %d", humanoid.DisplayName, model:GetAttribute("BossPhase") or 1)
		billboard.Enabled = humanoid.Health > 0
	end

	humanoid.HealthChanged:Connect(update)
	model:GetAttributeChangedSignal("BossPhase"):Connect(update)
	update()
end

function BossService.IsBoss(model) return model and model:GetAttribute("BossId") ~= nil end

function BossService.CreateGuardian(position, parent, uniqueName)
	local config = BossConfig.CrystalGuardian
	local model = Instance.new("Model"); model.Name = uniqueName or "CrystalGuardian"; model.Parent = parent
	model:SetAttribute("Enemy", true); model:SetAttribute("BossId", "CrystalGuardian"); model:SetAttribute("EnemyType", "CrystalGuardian"); model:SetAttribute("BossPhase", 1)
	local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Size = Vector3.new(2, 2, 1); root.Position = position + Vector3.new(0, 3, 0); root.Transparency = 1; root.Anchored = true; root.CanCollide = false; root.Parent = model
	local body = Instance.new("Part"); body.Name = "Body"; body.Size = Vector3.new(5, 7, 4); body.Position = position + Vector3.new(0, 6, 0); body.Material = Enum.Material.Neon; body.Color = Color3.fromRGB(120, 80, 190); body.Anchored = true; body.Parent = model
	local head = Instance.new("Part"); head.Name = "Head"; head.Shape = Enum.PartType.Ball; head.Size = Vector3.new(3, 3, 3); head.Position = position + Vector3.new(0, 10.5, 0); head.Material = Enum.Material.Neon; head.Color = Color3.fromRGB(180, 130, 255); head.Anchored = true; head.Parent = model
	for _, part in ipairs({ body, head }) do local weld = Instance.new("WeldConstraint"); weld.Part0 = root; weld.Part1 = part; weld.Parent = root end
	local humanoid = Instance.new("Humanoid"); humanoid.MaxHealth = config.Health; humanoid.Health = config.Health; humanoid.DisplayName = config.DisplayName; humanoid.Parent = model
	model.PrimaryPart = root
	attachBossHealthBar(model, humanoid, root)
	local nextAttack, nextAbility = 0, 0
	task.spawn(function()
		while model.Parent and humanoid.Health > 0 do
			local nearestPlayer, nearestDistance = nil, config.AggroRange
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
				local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
				if targetHumanoid and targetHumanoid.Health > 0 and targetRoot then
					local distance = (targetRoot.Position - root.Position).Magnitude
					if distance < nearestDistance then nearestPlayer, nearestDistance = player, distance end
				end
			end
			if nearestPlayer then
				local character = nearestPlayer.Character
				local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
				local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
				if targetRoot and targetHumanoid then
					local phase = humanoid.Health <= config.Health * 0.5 and 2 or 1
					model:SetAttribute("BossPhase", phase)
					if nearestDistance > config.AttackRange then
						local direction = targetRoot.Position - root.Position
						if direction.Magnitude > 0.1 then
							local step = math.min(0.8, direction.Magnitude)
							model:PivotTo(CFrame.lookAt(root.Position + direction.Unit * step, targetRoot.Position))
						end
					elseif os.clock() >= nextAttack then
						nextAttack = os.clock() + (phase == 2 and 1.0 or config.AttackCooldown)
						DodgeService.ApplyDamage(nearestPlayer, targetHumanoid, phase == 2 and math.floor(config.AttackDamage * 1.35) or config.AttackDamage)
					end
					if os.clock() >= nextAbility and nearestDistance <= config.AbilityRadius * 1.5 then
						nextAbility = os.clock() + config.AbilityCooldown
						shockwave(root.Position, config.AbilityRadius, config.AbilityDamage, model)
					end
				end
			end
			task.wait(0.15)
		end
	end)
	humanoid.Died:Connect(function()
		if model:GetAttribute("Rewarded") then return end
		model:SetAttribute("Rewarded", true)
		local creator = model:GetAttribute("LastAttackerUserId"); local player = creator and Players:GetPlayerByUserId(creator)
		if player then
			local PlayerService = require(script.Parent.PlayerService); local profile = PlayerService.GetProfile(player)
			if profile then
				XPService.AddXP(profile, config.XP)
				EconomyService.AddMoney(profile, config.Money)
				local coreAdded = InventoryService.AddItem(profile, config.Drop, 1)
				profile.Stats.BossesDefeated = (profile.Stats.BossesDefeated or 0) + 1
				if QuestSystem.IsActive(profile, "GUARDIAN_TRIAL") then
					QuestService.Complete(player, profile, "GUARDIAN_TRIAL", "Guardian Trial complete!")
				end
				PlayerService.Sync(player)
				if coreAdded > 0 then
					player:SetAttribute("BossMessage", "Crystal Guardian defeated! Guardian Core earned.")
				else
					player:SetAttribute("BossMessage", "Crystal Guardian defeated! Guardian Core stack is full.")
				end
				local remotes = ReplicatedStorage:FindFirstChild("Remotes"); if remotes and remotes:FindFirstChild("InventoryChanged") then remotes.InventoryChanged:FireClient(player, profile.Inventory) end
			end
		end
		task.delay(1.5, function()
			if model.Parent then model:Destroy() end
		end)
		task.delay(config.Respawn + 1.5, function()
			if parent.Parent and not parent:FindFirstChild(uniqueName or "CrystalGuardian") then
				BossService.CreateGuardian(position, parent, uniqueName)
			end
		end)
	end)
	return model
end

return BossService