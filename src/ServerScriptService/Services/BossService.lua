local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local BossConfig = require(ReplicatedStorage.Config.BossConfig)
local InventoryService = require(script.Parent.InventoryService)
local EconomyService = require(script.Parent.EconomyService)
local XPService = require(script.Parent.XPService)
local QuestSystem = require(ReplicatedStorage.Modules.QuestSystem)
local BossService = { Bound = false }

local function shockwave(center, radius, damage, ignoreModel)
	local folder = workspace:FindFirstChild("NPCs")
	if folder then
		for _, child in ipairs(folder:GetChildren()) do
			if child ~= ignoreModel then
				local humanoid = child:FindFirstChildOfClass("Humanoid")
				local root = child:FindFirstChild("HumanoidRootPart") or child.PrimaryPart
				if humanoid and humanoid.Health > 0 and root and (root.Position - center).Magnitude <= radius then humanoid:TakeDamage(damage) end
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

function BossService.IsBoss(model) return model and model:GetAttribute("BossId") ~= nil end

function BossService.CreateGuardian(position, parent, uniqueName)
	local config = BossConfig.CrystalGuardian
	local model = Instance.new("Model"); model.Name = uniqueName or "CrystalGuardian"; model.Parent = parent
	model:SetAttribute("Enemy", true); model:SetAttribute("BossId", "CrystalGuardian"); model:SetAttribute("EnemyType", "CrystalGuardian"); model:SetAttribute("BossPhase", 1)
	local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Size = Vector3.new(2, 2, 1); root.Position = position + Vector3.new(0, 3, 0); root.Transparency = 1; root.Anchored = false; root.Parent = model
	local body = Instance.new("Part"); body.Name = "Body"; body.Size = Vector3.new(5, 7, 4); body.Position = position + Vector3.new(0, 6, 0); body.Material = Enum.Material.Neon; body.Color = Color3.fromRGB(120, 80, 190); body.Parent = model
	local head = Instance.new("Part"); head.Name = "Head"; head.Shape = Enum.PartType.Ball; head.Size = Vector3.new(3, 3, 3); head.Position = position + Vector3.new(0, 10.5, 0); head.Material = Enum.Material.Neon; head.Color = Color3.fromRGB(180, 130, 255); head.Parent = model
	for _, part in ipairs({ body, head }) do local weld = Instance.new("WeldConstraint"); weld.Part0 = root; weld.Part1 = part; weld.Parent = root end
	local humanoid = Instance.new("Humanoid"); humanoid.MaxHealth = config.Health; humanoid.Health = config.Health; humanoid.DisplayName = config.DisplayName; humanoid.Parent = model
	model.PrimaryPart = root
	local nextAttack, nextAbility = 0, 0
	task.spawn(function()
		while model.Parent and humanoid.Health > 0 do
			local nearestPlayer, nearestDistance
			nearestDistance = config.AggroRange
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character; local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid"); local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
				if targetHumanoid and targetHumanoid.Health > 0 and targetRoot then
					local distance = (targetRoot.Position - root.Position).Magnitude
					if distance < nearestDistance then nearestPlayer, nearestDistance = player, distance end
				end
			end
			if nearestPlayer then
				local character = nearestPlayer.Character; local targetRoot = character and character:FindFirstChild("HumanoidRootPart"); local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
				if targetRoot and targetHumanoid then
					local phase = humanoid.Health <= config.Health * 0.5 and 2 or 1
					model:SetAttribute("BossPhase", phase)
					if nearestDistance > config.AttackRange then
						local direction = targetRoot.Position - root.Position
						if direction.Magnitude > 0.1 then model:PivotTo(CFrame.lookAt(root.Position + direction.Unit * 0.8, targetRoot.Position)) end
					elseif os.clock() >= nextAttack then
						nextAttack = os.clock() + (phase == 2 and 1.0 or config.AttackCooldown)
						targetHumanoid:TakeDamage(phase == 2 and math.floor(config.AttackDamage * 1.35) or config.AttackDamage)
					end
					if os.clock() >= nextAbility and nearestDistance <= config.AbilityRadius * 1.5 then nextAbility = os.clock() + config.AbilityCooldown; shockwave(root.Position, config.AbilityRadius, config.AbilityDamage, model) end
				end
			end
			task.wait(0.15)
		end
	end)
	humanoid.Died:Connect(function()
		if model:GetAttribute("Rewarded") then return end
		model:SetAttribute("Rewarded", true)
		local creator = model:GetAttribute("LastAttackerUserId")
		local player = creator and Players:GetPlayerByUserId(creator)
		if player then
			local PlayerService = require(script.Parent.PlayerService)
			local profile = PlayerService.GetProfile(player)
			if profile then
				XPService.AddXP(profile, config.XP); EconomyService.AddMoney(profile, config.Money); InventoryService.AddItem(profile, config.Drop, 1)
				profile.Stats.BossesDefeated = (profile.Stats.BossesDefeated or 0) + 1
				if QuestSystem.IsActive(profile, "GUARDIAN_TRIAL") then
					QuestSystem.Complete(profile, "GUARDIAN_TRIAL")
					XPService.AddXP(profile, 2200); EconomyService.AddMoney(profile, 1500)
				end
				PlayerService.Sync(player)
				player:SetAttribute("BossMessage", "Crystal Guardian defeated! +" .. config.XP .. " XP and Guardian Core earned.")
				local remotes = ReplicatedStorage:FindFirstChild("Remotes")
				if remotes and remotes:FindFirstChild("InventoryChanged") then remotes.InventoryChanged:FireClient(player, profile.Inventory) end
			end
		end
		task.delay(config.Respawn, function() if parent.Parent then BossService.CreateGuardian(position, parent, uniqueName) end end)
	end)
	return model
end

return BossService
