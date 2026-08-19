local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local EnemyConfig = require(game.ReplicatedStorage.Config.EnemyConfig)
local AIPathService = require(script.Parent.AIPathService)
local StatusEffectService = require(script.Parent.StatusEffectService)
local DodgeService = require(script.Parent.DodgeService)

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
			if distance < nearestDistance then
				nearestDistance = distance
				nearestCharacter = character
			end
		end
	end
	return nearestCharacter, nearestDistance
end

local function steerAroundObstacle(model, desiredDirection)
	if desiredDirection.Magnitude < 0.01 or not model.PrimaryPart then return desiredDirection end
	local root = model.PrimaryPart
	local direction = desiredDirection.Unit
	local origin = root.Position + Vector3.new(0, 2, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model }
	params.IgnoreWater = true
	if not Workspace:Raycast(origin, direction * 7, params) then return desiredDirection end
	local pathDirection = AIPathService.GetNextDirection(model, origin + direction * math.min(desiredDirection.Magnitude, 24))
	if pathDirection and pathDirection.Magnitude > 0.1 then return pathDirection end
	local left = CFrame.Angles(0, math.rad(-55), 0):VectorToWorldSpace(direction)
	if not Workspace:Raycast(origin, left * 7, params) then return left end
	local right = CFrame.Angles(0, math.rad(55), 0):VectorToWorldSpace(direction)
	if not Workspace:Raycast(origin, right * 7, params) then return right end
	return CFrame.Angles(0, math.rad(90), 0):VectorToWorldSpace(direction)
end

local function attachHealthBar(model, humanoid, root)
	local existing = root:FindFirstChild("EnemyHealthBar")
	if existing then existing:Destroy() end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "EnemyHealthBar"
	billboard.Adornee = root
	billboard.Size = UDim2.fromOffset(150, 34)
	billboard.StudsOffset = Vector3.new(0, 6.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = root
	local back = Instance.new("Frame")
	back.Name = "Back"
	back.Size = UDim2.new(1, 0, 0, 10)
	back.Position = UDim2.fromOffset(0, 20)
	back.BackgroundTransparency = 0.2
	back.Parent = billboard
	Instance.new("UICorner", back).CornerRadius = UDim.new(0, 4)
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.Parent = back
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 18)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 12
	title.Text = humanoid.DisplayName
	title.Parent = billboard
	local function update()
		local ratio = math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1)
		fill.Size = UDim2.fromScale(ratio, 1)
		title.Text = string.format("%s  %d/%d", humanoid.DisplayName, math.max(0, math.floor(humanoid.Health)), math.floor(humanoid.MaxHealth))
		billboard.Enabled = humanoid.Health > 0
	end
	humanoid.HealthChanged:Connect(update)
	update()
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
	body.Size = config.BodySize
	head.Size = config.HeadSize
	head.Shape = config.HeadShape
	body.Color = config.Color
	head.Color = config.Color
	body.Material = config.Material
	head.Material = config.Material
	if typeId == "Galewisp" or typeId == "CrystalBat" then
		local light = Instance.new("PointLight")
		light.Color = config.Color
		light.Range = 8
		light.Brightness = 1.5
		light.Parent = head
	end
	if typeId == "Emberling" or typeId == "Tidecrawler" or typeId == "AncientGolem" then
		local aura = Instance.new("SelectionBox")
		aura.Name = "CrystalAura"
		aura.Adornee = body
		aura.LineThickness = 0.03
		aura.SurfaceTransparency = 1
		aura.Color3 = config.Color
		aura.Parent = body
	end
end

local function emitSpecialEffect(position, color, radius)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Shape = Enum.PartType.Ball
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Size = Vector3.new(2, 2, 2)
	part.CFrame = CFrame.new(position)
	part.Transparency = 0.2
	part.Parent = workspace
	TweenService:Create(part, TweenInfo.new(0.3), { Size = Vector3.new(radius, radius, radius), Transparency = 1 }):Play()
	task.delay(0.35, function()
		if part.Parent then part:Destroy() end
	end)
end

local function damagePlayer(player, humanoid, amount, attacker, damageType, range)
	if not player or not player.Parent or not humanoid or not humanoid.Parent or humanoid.Health <= 0 then return false end
	if attacker and attacker:IsA("Model") then
		if not attacker.Parent or attacker:GetAttribute("Enemy") ~= true then return false end
		local attackerHumanoid = attacker:FindFirstChildOfClass("Humanoid")
		if attackerHumanoid and attackerHumanoid.Health <= 0 then return false end
	end
	return DodgeService.ApplyDamage(player, humanoid, math.max(0, amount), attacker, damageType or "Physical", range)
end

local function specialAttack(typeId, model, character, targetHumanoid, targetRoot, root)
	local config = EnemyConfig.Get(typeId)
	if not config then return end
	local special = type(config.Special) == "table" and config.Special or {}
	local baseDamage = config.AttackDamage
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player then return end
	if typeId == "Emberling" then
		local range = math.clamp(tonumber(special.Range) or 14, 0.1, 1000)
		if (targetRoot.Position - root.Position).Magnitude <= range then
			emitSpecialEffect(targetRoot.Position, Color3.fromRGB(255, 90, 30), 6)
			local applied = damagePlayer(player, targetHumanoid, baseDamage + (tonumber(special.BonusDamage) or 0), model, "Physical", range)
			if applied then
				StatusEffectService.ApplyBurn(targetHumanoid, special.BurnDamage, special.BurnTicks, special.BurnInterval, model, range)
			end
		end
	elseif typeId == "Tidecrawler" then
		local range = math.clamp(tonumber(special.Range) or 10, 0.1, 1000)
		if (targetRoot.Position - root.Position).Magnitude <= range then
			emitSpecialEffect(targetRoot.Position, Color3.fromRGB(40, 150, 255), 5)
			local applied = damagePlayer(player, targetHumanoid, baseDamage + (tonumber(special.BonusDamage) or 0), model, "Physical", range)
			if applied then
				StatusEffectService.ApplySlow(targetHumanoid, special.SlowMultiplier, special.SlowDuration)
			end
		end
	elseif typeId == "Galewisp" then
		local direction = targetRoot.Position - root.Position
		local range = math.clamp(tonumber(special.Range) or 18, 0.1, 1000)
		if direction.Magnitude > 0.1 and direction.Magnitude <= range then
			emitSpecialEffect(root.Position, Color3.fromRGB(175, 120, 255), 8)
			local offset = math.clamp(tonumber(special.TeleportOffset) or 4, 0, math.min(100, range))
			model:PivotTo(CFrame.lookAt(targetRoot.Position - direction.Unit * offset, targetRoot.Position))
			damagePlayer(player, targetHumanoid, baseDamage + (tonumber(special.BonusDamage) or 0), model, "Physical", range)
		end
	elseif typeId == "CrystalBat" then
		local range = math.clamp(tonumber(special.Range) or 12, 0.1, 1000)
		if (targetRoot.Position - root.Position).Magnitude <= range then
			emitSpecialEffect(targetRoot.Position, Color3.fromRGB(80, 255, 240), 5)
			damagePlayer(player, targetHumanoid, baseDamage + (tonumber(special.BonusDamage) or 0), model, "Physical", range)
		end
	elseif typeId == "AncientGolem" then
		local range = math.clamp(tonumber(special.Range) or special.Radius or 10, 0.1, 1000)
		emitSpecialEffect(root.Position, Color3.fromRGB(150, 140, 125), 12)
		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			local otherCharacter = otherPlayer.Character
			local otherHumanoid = otherCharacter and otherCharacter:FindFirstChildOfClass("Humanoid")
			local otherRoot = otherCharacter and otherCharacter:FindFirstChild("HumanoidRootPart")
			if otherHumanoid and otherHumanoid.Health > 0 and otherRoot and (otherRoot.Position - root.Position).Magnitude <= range then
				damagePlayer(otherPlayer, otherHumanoid, baseDamage + (tonumber(special.BonusDamage) or 0), model, "Physical", range)
			end
		end
	end
end

function NPCService.StartEnemyAI(model)
	local typeId = model:GetAttribute("EnemyType")
	local config = EnemyConfig.Get(typeId)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	if not config or not humanoid or not root or config.AggroRange <= 0 then return end
	local homePosition = root.Position
	model:SetAttribute("HomeX", homePosition.X)
	model:SetAttribute("HomeY", homePosition.Y)
	model:SetAttribute("HomeZ", homePosition.Z)
	task.spawn(function()
		local nextAttack, nextSpecial = 0, os.clock() + 3
		local leashDistance = math.max(config.AggroRange * 1.8, 50)
		local specialConfig = type(config.Special) == "table" and config.Special or {}
		local specialCooldown = math.clamp(tonumber(specialConfig.Cooldown) or 6, 0.25, 60)
		local specialRange = math.clamp(tonumber(specialConfig.Range) or 0, 0, 1000)
		while model.Parent and humanoid.Health > 0 do
			local character, distance = getNearestPlayer(root.Position, config.AggroRange)
			if character then
				local targetRoot = character:FindFirstChild("HumanoidRootPart")
				local targetHumanoid = character:FindFirstChildOfClass("Humanoid")
				local targetPlayer = Players:GetPlayerFromCharacter(character)
				if targetRoot and targetHumanoid and targetHumanoid.Health > 0 and targetPlayer then
					if distance > config.AttackRange then
						local direction = targetRoot.Position - root.Position
						local steer = steerAroundObstacle(model, direction)
						if steer.Magnitude > 0.1 then
							local step = math.min(0.9, direction.Magnitude)
							local nextPosition = root.Position + steer.Unit * step
							if (nextPosition - homePosition).Magnitude <= leashDistance then
								model:PivotTo(CFrame.lookAt(nextPosition, targetRoot.Position))
							end
						end
					elseif os.clock() >= nextAttack then
						nextAttack = os.clock() + math.clamp(tonumber(config.AttackCooldown) or 1, 0.25, 60)
						damagePlayer(targetPlayer, targetHumanoid, config.AttackDamage, model, "Physical", config.AttackRange)
					end
					if os.clock() >= nextSpecial and typeId ~= "TrainingDummy" and specialRange > 0 and distance <= specialRange then
						nextSpecial = os.clock() + specialCooldown
						specialAttack(typeId, model, character, targetHumanoid, targetRoot, root)
					end
				end
			else
				local distanceFromHome = (root.Position - homePosition).Magnitude
				if distanceFromHome > 3 then
					local direction = homePosition - root.Position
					local steer = steerAroundObstacle(model, direction)
					if steer.Magnitude > 0.1 then
						local step = math.min(0.75, direction.Magnitude)
						local nextPosition = root.Position + steer.Unit * step
						model:PivotTo(CFrame.lookAt(nextPosition, homePosition))
					end
				end
			end
			task.wait(0.1)
		end
		AIPathService.Clear(model)
		StatusEffectService.Clear(humanoid)
	end)
end

function NPCService.CreateEnemy(typeId, position, parent, onDeath, uniqueName)
	local config = EnemyConfig.Get(typeId)
	if not config or not position or not parent then return nil end
	local model = Instance.new("Model")
	model.Name = uniqueName or config.DisplayName:gsub("%s+", "")
	model:SetAttribute("Enemy", true)
	model:SetAttribute("EnemyType", typeId)
	model:SetAttribute("RewardXP", config.XP)
	model:SetAttribute("RewardMoney", config.Money)
	model:SetAttribute("SpawnX", position.X)
	model:SetAttribute("SpawnY", position.Y)
	model:SetAttribute("SpawnZ", position.Z)
	model.Parent = parent
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Position = position + Vector3.new(0, 3, 0)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.Parent = model
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 4, 2)
	body.Position = position + Vector3.new(0, 4, 0)
	body.Anchored = true
	body.Parent = model
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(2, 2, 2)
	head.Position = position + Vector3.new(0, 7, 0)
	head.Anchored = true
	head.Parent = model
	applyVisualStyle(typeId, body, head)
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = config.Health
	humanoid.Health = config.Health
	humanoid.DisplayName = config.DisplayName
	humanoid.Parent = model
	local weldA = Instance.new("WeldConstraint")
	weldA.Part0 = root
	weldA.Part1 = body
	weldA.Parent = root
	local weldB = Instance.new("WeldConstraint")
	weldB.Part0 = body
	weldB.Part1 = head
	weldB.Parent = body
	model.PrimaryPart = root
	attachHealthBar(model, humanoid, root)
	humanoid.Died:Connect(function()
		AIPathService.Clear(model)
		StatusEffectService.Clear(humanoid)
		if onDeath then onDeath(model, config) end
		task.delay(1.5, function()
			if model.Parent then model:Destroy() end
		end)
	end)
	NPCService.StartEnemyAI(model)
	return model
end

return NPCService
