local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local BossConfig = require(ReplicatedStorage.Config.BossConfig)
local EconomyConfig = require(ReplicatedStorage.Config.EconomyConfig)
local XPConfig = require(ReplicatedStorage.Config.XPConfig)
local InventoryConfig = require(ReplicatedStorage.Config.InventoryConfig)
local QuestSystem = require(ReplicatedStorage.Modules.QuestSystem)
local InventoryService = require(script.Parent.InventoryService)
local EconomyService = require(script.Parent.EconomyService)
local XPService = require(script.Parent.XPService)
local QuestService = require(script.Parent.QuestService)
local DamageService = require(script.Parent.DamageService)
local DodgeService = require(script.Parent.DodgeService)
local BossService = { Bound = false }

local function finiteNumber(value, fallback)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return fallback end
	return number
end

local function getPhase2Config(config)
	local phase2 = type(config.Phase2) == "table" and config.Phase2 or {}
	return {
		HealthThreshold = math.clamp(finiteNumber(phase2.HealthThreshold, 0.5), 0.01, 0.99),
		AttackCooldown = math.clamp(finiteNumber(phase2.AttackCooldown, finiteNumber(config.AttackCooldown, 1)), 0.1, 60),
		AttackDamageMultiplier = math.clamp(finiteNumber(phase2.AttackDamageMultiplier, 1.35), 0, 10),
		AbilityRangeMultiplier = math.clamp(finiteNumber(phase2.AbilityRangeMultiplier, 1.5), 0, 10),
	}
end

local function shockwave(center, radius, damage, ignoreModel)
	radius = math.clamp(finiteNumber(radius, 0), 0, 1000)
	damage = math.clamp(finiteNumber(damage, 0), 0, 1000)
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root and (root.Position - center).Magnitude <= radius then
			DodgeService.ApplyDamage(player, humanoid, damage, ignoreModel, "BossShockwave", radius)
		end
	end

	local folder = workspace:FindFirstChild("NPCs")
	if folder and ignoreModel and ignoreModel:IsA("Model") then
		local attackerRoot = ignoreModel:FindFirstChild("HumanoidRootPart") or ignoreModel.PrimaryPart
		if attackerRoot then
			for _, child in ipairs(folder:GetChildren()) do
				if child ~= ignoreModel and child:GetAttribute("Enemy") == true and not child:GetAttribute("BossId") then
					local humanoid = child:FindFirstChildOfClass("Humanoid")
					local root = child:FindFirstChild("HumanoidRootPart") or child.PrimaryPart
					if humanoid and humanoid.Health > 0 and root and (root.Position - center).Magnitude <= radius then
						DamageService.ProcessDamage({
							Attacker = ignoreModel,
							Target = child,
							Amount = damage,
							Range = radius,
							DamageType = "BossShockwave",
						})
					end
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
	if not parent or not parent.Parent or typeof(position) ~= "Vector3" then return nil end
	local bossName = uniqueName or "CrystalGuardian"
	local existing = parent:FindFirstChild(bossName)
	if existing then
		if existing:IsA("Model") and existing:GetAttribute("BossId") == "CrystalGuardian" then
			return existing
		end
		existing:Destroy()
	end

	local config = BossConfig.CrystalGuardian
	local phase2 = getPhase2Config(config)
	local health = math.clamp(finiteNumber(config.Health, 2500), 1, 1000000)
	local aggroRange = math.clamp(finiteNumber(config.AggroRange, 65), 1, 1000)
	local attackRange = math.clamp(finiteNumber(config.AttackRange, 9), 0.1, 1000)
	local attackCooldown = math.clamp(finiteNumber(config.AttackCooldown, 1.4), 0.1, 60)
	local respawn = math.clamp(finiteNumber(config.Respawn, 90), 1.5, 600)
	local displayName = type(config.DisplayName) == "string" and config.DisplayName ~= "" and config.DisplayName or "Crystal Guardian"
	local model = Instance.new("Model"); model.Name = bossName; model.Parent = parent
	model:SetAttribute("Enemy", true); model:SetAttribute("BossId", "CrystalGuardian"); model:SetAttribute("EnemyType", "CrystalGuardian"); model:SetAttribute("BossPhase", 1)
	local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Size = Vector3.new(2, 2, 1); root.Position = position + Vector3.new(0, 3, 0); root.Transparency = 1; root.Anchored = true; root.CanCollide = false; root.Parent = model
	local body = Instance.new("Part"); body.Name = "Body"; body.Size = Vector3.new(5, 7, 4); body.Position = position + Vector3.new(0, 6, 0); body.Material = Enum.Material.Neon; body.Color = Color3.fromRGB(120, 80, 190); body.Anchored = true; body.Parent = model
	local head = Instance.new("Part"); head.Name = "Head"; head.Shape = Enum.PartType.Ball; head.Size = Vector3.new(3, 3, 3); head.Position = position + Vector3.new(0, 10.5, 0); head.Material = Enum.Material.Neon; head.Color = Color3.fromRGB(180, 130, 255); head.Anchored = true; head.Parent = model
	for _, part in ipairs({ body, head }) do local weld = Instance.new("WeldConstraint"); weld.Part0 = root; weld.Part1 = part; weld.Parent = root end
	local humanoid = Instance.new("Humanoid"); humanoid.MaxHealth = health; humanoid.Health = health; humanoid.DisplayName = displayName; humanoid.Parent = model
	model.PrimaryPart = root
	attachBossHealthBar(model, humanoid, root)
	local nextAttack, nextAbility = 0, 0
	task.spawn(function()
		while model.Parent and humanoid.Health > 0 do
			local nearestPlayer, nearestDistance = nil, aggroRange
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
					local phase = humanoid.Health <= health * phase2.HealthThreshold and 2 or 1
					model:SetAttribute("BossPhase", phase)
					if nearestDistance > attackRange then
						local direction = targetRoot.Position - root.Position
						if direction.Magnitude > 0.1 then
							local step = math.min(0.8, direction.Magnitude)
							model:PivotTo(CFrame.lookAt(root.Position + direction.Unit * step, targetRoot.Position))
						end
					elseif os.clock() >= nextAttack then
						local attackCooldownValue = phase == 2 and phase2.AttackCooldown or attackCooldown
						local attackDamage = phase == 2 and math.floor(math.clamp(finiteNumber(config.AttackDamage, 0), 0, 1000) * phase2.AttackDamageMultiplier) or math.clamp(finiteNumber(config.AttackDamage, 0), 0, 1000)
						nextAttack = os.clock() + attackCooldownValue
						DodgeService.ApplyDamage(nearestPlayer, targetHumanoid, attackDamage, model, "Physical", attackRange)
					end
					local baseAbilityRadius = math.clamp(finiteNumber(config.AbilityRadius, 0), 0, 1000)
					local abilityRadius = math.clamp(baseAbilityRadius * (phase == 2 and phase2.AbilityRangeMultiplier or 1), 0, 1000)
					if os.clock() >= nextAbility and nearestDistance <= abilityRadius then
						nextAbility = os.clock() + math.clamp(finiteNumber(config.AbilityCooldown, 6), 0.1, 60)
						shockwave(root.Position, abilityRadius, math.clamp(finiteNumber(config.AbilityDamage, 0), 0, 1000), model)
					end
				end
			end
			task.wait(0.15)
		end
	end)
	humanoid.Died:Connect(function()
		if model:GetAttribute("Rewarded") then return end

		local creator = DamageService.GetLastAttacker(model)
		local player = creator and (creator:IsA("Player") and creator or Players:GetPlayerFromCharacter(creator))
		local PlayerService = require(script.Parent.PlayerService)
		local profile = player and PlayerService.GetProfile(player) or nil
		local xpReward = finiteNumber(config.XP)
		local moneyReward = finiteNumber(config.Money)
		local dropId = type(config.Drop) == "string" and config.Drop or nil
		local validRewardConfig = player ~= nil and profile ~= nil
			and xpReward ~= nil and xpReward >= 0 and xpReward % 1 == 0
			and xpReward <= XPConfig.MaxExperience
			and moneyReward ~= nil and moneyReward >= 0 and moneyReward % 1 == 0
			and moneyReward <= EconomyConfig.MaxMoney
			and dropId ~= nil and InventoryConfig.GetItemConfig(dropId) ~= nil

		if validRewardConfig then
			model:SetAttribute("Rewarded", true)
		end

		if player and profile and validRewardConfig then
			XPService.AddXP(profile, xpReward)
			local _, earnedMoney = EconomyService.AddMoney(profile, moneyReward)
			local coreAdded = InventoryService.AddItem(profile, dropId, 1)
			if not profile.Stats then profile.Stats = {} end
			profile.Stats.BossesDefeated = (finiteNumber(profile.Stats.BossesDefeated, 0) or 0) + 1
			QuestService.Complete(player, profile, "GUARDIAN_TRIAL", "Guardian of the Crystals complete!")
			PlayerService.Sync(player)
			if coreAdded > 0 then
				player:SetAttribute("BossMessage", earnedMoney < moneyReward
					and string.format("Crystal Guardian defeated! +%d Money (wallet cap) and Guardian Core earned.", earnedMoney)
					or "Crystal Guardian defeated! Guardian Core earned.")
			else
				player:SetAttribute("BossMessage", earnedMoney < moneyReward
					and string.format("Crystal Guardian defeated! +%d Money (wallet cap). Guardian Core stack is full.", earnedMoney)
					or "Crystal Guardian defeated! Guardian Core stack is full.")
			end
			local remotes = ReplicatedStorage:FindFirstChild("Remotes"); if remotes and remotes:FindFirstChild("InventoryChanged") then remotes.InventoryChanged:FireClient(player, InventoryService.GetInventory(profile)) end
		end

		DamageService.ClearTarget(model)
		task.delay(1.5, function()
			if model.Parent then model:Destroy() end
		end)
		task.delay(respawn + 1.5, function()
			if parent.Parent and not parent:FindFirstChild(bossName) then
				BossService.CreateGuardian(position, parent, bossName)
			end
		end)
	end)
	return model
end

return BossService
