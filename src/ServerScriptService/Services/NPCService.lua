local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local EnemyConfig = require(game.ReplicatedStorage.Config.EnemyConfig)

local NPCService = {}

function NPCService.GetNPCs()
	local folder = Workspace:FindFirstChild("NPCs")
	return folder and folder:GetChildren() or {}
end

function NPCService.FindByName(name)
	local folder = Workspace:FindFirstChild("NPCs")
	return folder and folder:FindFirstChild(name) or nil
end

function NPCService.IsInteractable(instance)
	return instance and instance:IsA("Model") and instance:GetAttribute("Interactable") == true
end

local function getNearestPlayer(position, maxDistance)
	local nearestCharacter
	local nearestDistance = maxDistance
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root then
			local distance = (root.Position - position).Magnitude
			if distance < nearestDistance then nearestDistance = distance; nearestCharacter = character end
		end
	end
	return nearestCharacter, nearestDistance
end

local function attachHealthBar(model, humanoid, root)
	local existing = root:FindFirstChild("EnemyHealthBar")
	if existing then existing:Destroy() end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "EnemyHealthBar"; billboard.Adornee = root; billboard.Size = UDim2.fromOffset(150, 34); billboard.StudsOffset = Vector3.new(0, 6.5, 0); billboard.AlwaysOnTop = true; billboard.Parent = root
	local back = Instance.new("Frame")
	back.Name = "Back"; back.Size = UDim2.new(1, 0, 0, 10); back.Position = UDim2.fromOffset(0, 20); back.BackgroundTransparency = 0.2; back.Parent = billboard; Instance.new("UICorner", back).CornerRadius = UDim.new(0, 4)
	local fill = Instance.new("Frame")
	fill.Name = "Fill"; fill.Size = UDim2.fromScale(1, 1); fill.Parent = back; Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)
	local title = Instance.new("TextLabel")
	title.Name = "Title"; title.Size = UDim2.new(1, 0, 0, 18); title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBold; title.TextSize = 12; title.Text = humanoid.DisplayName; title.Parent = billboard
	local function update()
		local ratio = math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1)
		fill.Size = UDim2.fromScale(ratio, 1)
		title.Text = string.format("%s  %d/%d", humanoid.DisplayName, math.max(0, math.floor(humanoid.Health)), math.floor(humanoid.MaxHealth))
		billboard.Enabled = humanoid.Health > 0
	end
	humanoid.HealthChanged:Connect(update); update()
end

local function applyVisualStyle(typeId, body, head)
	local style = {
		TrainingDummy = { Color = Color3.fromRGB(180, 150, 100), Material = Enum.Material.Wood, BodySize = Vector3.new(3, 4, 2), HeadSize = Vector3.new(2, 2, 2), HeadShape = Enum.PartType.Ball },
		Emberling = { Color = Color3.fromRGB(255, 105, 45), Material = Enum.Material.Neon, BodySize = Vector3.new(2.8, 3.6, 2), HeadSize = Vector3.new(2.2, 2.2, 2.2), HeadShape = Enum.PartType.Ball },
		Tidecrawler = { Color = Color3.fromRGB(50, 150, 255), Material = Enum.Material.SmoothPlastic, BodySize = Vector3.new(3.8, 2.4, 2.8), HeadSize = Vector3.new(2.8, 1.8, 2.8), HeadShape = Enum.PartType.Ball },
		Galewisp = { Color = Color3.fromRGB(175, 120, 255), Material = Enum.Material.Neon, BodySize = Vector3.new(2.2, 4.5, 2.2), HeadSize = Vector3.new(1.8, 1.8, 1.8), HeadShape = Enum.PartType.Ball },
		CrystalBat = { Color = Color3.fromRGB(80, 255, 240), Material = Enum.Material.Neon, BodySize = Vector3.new(4.2, 1.8, 2.2), HeadSize = Vector3.new(1.7, 1.7, 1.7), HeadShape = Enum.PartType.Ball },
		AncientGolem = { Color = Color3.fromRGB(110, 105, 95), Material = Enum.Material.Rock, BodySize = Vector3.new(4.5, 5.5, 3.8), HeadSize = Vector3.new(3, 3, 3), HeadShape = Enum.PartType.Block },
	}
	local config = style[typeId] or style.TrainingDummy
	body.Size = config.BodySize; head.Size = config.HeadSize; head.Shape = config.HeadShape
	body.Color = config.Color; head.Color = config.Color; body.Material = config.Material; head.Material = config.Material
	if typeId == "Galewisp" or typeId == "CrystalBat" then
		local light = Instance.new("PointLight")
		light.Color = config.Color; light.Range = 8; light.Brightness = 1.5; light.Parent = head
	end
	if typeId == "Emberling" or typeId == "Tidecrawler" or typeId == "AncientGolem" then
		local aura = Instance.new("SelectionBox")
		aura.Name = "CrystalAura"; aura.Adornee = body; aura.LineThickness = 0.03; aura.SurfaceTransparency = 1; aura.Color3 = config.Color; aura.Parent = body
	end
end

function NPCService.StartEnemyAI(model)
	local typeId = model:GetAttribute("EnemyType")
	local config = EnemyConfig.Get(typeId)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	if not humanoid or not root or config.AggroRange <= 0 then return end
	task.spawn(function()
		local nextAttack = 0
		local homePosition = root.Position
		local leashDistance = math.max(config.AggroRange * 1.8, 50)
		while model.Parent and humanoid.Health > 0 do
			local character, distance = getNearestPlayer(root.Position, config.AggroRange)
			if character then
				local targetRoot = character:FindFirstChild("HumanoidRootPart")
				local targetHumanoid = character:FindFirstChildOfClass("Humanoid")
				if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
					if distance > config.AttackRange then
						local direction = targetRoot.Position - root.Position
						if direction.Magnitude > 0.1 then
							local step = math.min(0.9, direction.Magnitude)
							local nextPosition = root.Position + direction.Unit * step
							if (nextPosition - homePosition).Magnitude <= leashDistance then model:PivotTo(CFrame.lookAt(nextPosition, targetRoot.Position)) end
						end
					elseif os.clock() >= nextAttack then
						nextAttack = os.clock() + math.max(0.25, config.AttackCooldown)
						targetHumanoid:TakeDamage(math.max(0, config.AttackDamage))
					end
				end
			else
				local distanceFromHome = (root.Position - homePosition).Magnitude
				if distanceFromHome > 3 then
					local direction = homePosition - root.Position
					if direction.Magnitude > 0.1 then
						local step = math.min(0.75, direction.Magnitude)
						local nextPosition = root.Position + direction.Unit * step
						model:PivotTo(CFrame.lookAt(nextPosition, homePosition))
					end
				end
			end
			task.wait(0.1)
		end
	end)
end

function NPCService.CreateEnemy(typeId, position, parent, onDeath, uniqueName)
	local config = EnemyConfig.Get(typeId)
	local model = Instance.new("Model")
	model.Name = uniqueName or config.DisplayName:gsub("%s+", "")
	model:SetAttribute("Enemy", true); model:SetAttribute("EnemyType", typeId); model:SetAttribute("RewardXP", config.XP); model:SetAttribute("RewardMoney", config.Money)
	model:SetAttribute("SpawnX", position.X); model:SetAttribute("SpawnY", position.Y); model:SetAttribute("SpawnZ", position.Z); model.Parent = parent

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"; root.Size = Vector3.new(2, 2, 1); root.Position = position + Vector3.new(0, 3, 0); root.Transparency = 1; root.Anchored = true; root.CanCollide = false; root.Parent = model
	local body = Instance.new("Part")
	body.Name = "Body"; body.Size = Vector3.new(3, 4, 2); body.Position = position + Vector3.new(0, 4, 0); body.Anchored = true; body.Parent = model
	local head = Instance.new("Part")
	head.Name = "Head"; head.Shape = Enum.PartType.Ball; head.Size = Vector3.new(2, 2, 2); head.Position = position + Vector3.new(0, 7, 0); head.Anchored = true; head.Parent = model
	applyVisualStyle(typeId, body, head)
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = config.Health; humanoid.Health = config.Health; humanoid.DisplayName = config.DisplayName; humanoid.Parent = model
	local weldA = Instance.new("WeldConstraint"); weldA.Part0 = root; weldA.Part1 = body; weldA.Parent = root
	local weldB = Instance.new("WeldConstraint"); weldB.Part0 = body; weldB.Part1 = head; weldB.Parent = body
	model.PrimaryPart = root
	attachHealthBar(model, humanoid, root)
	humanoid.Died:Connect(function() if onDeath then onDeath(model, config) end end)
	NPCService.StartEnemyAI(model)
	return model
end

return NPCService
