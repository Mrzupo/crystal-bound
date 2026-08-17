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
			if distance < nearestDistance then
				nearestDistance = distance
				nearestCharacter = character
			end
		end
	end
	return nearestCharacter, nearestDistance
end

function NPCService.StartEnemyAI(model)
	local typeId = model:GetAttribute("EnemyType")
	local config = EnemyConfig.Get(typeId)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	if not humanoid or not root or config.AggroRange <= 0 then return end

	task.spawn(function()
		local nextAttack = 0
		while model.Parent and humanoid.Health > 0 do
			local character, distance = getNearestPlayer(root.Position, config.AggroRange)
			if character then
				local targetRoot = character:FindFirstChild("HumanoidRootPart")
				local targetHumanoid = character:FindFirstChildOfClass("Humanoid")
				if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
					if distance > config.AttackRange then
						local direction = (targetRoot.Position - root.Position)
						if direction.Magnitude > 0.1 then
							local step = math.min(0.9, direction.Magnitude)
							local nextPosition = root.Position + direction.Unit * step
							model:PivotTo(CFrame.lookAt(nextPosition, targetRoot.Position))
						end
					elseif os.clock() >= nextAttack then
						nextAttack = os.clock() + config.AttackCooldown
						targetHumanoid:TakeDamage(config.AttackDamage)
					end
				end
			end
			task.wait(0.1)
		end
	end)
end

function NPCService.CreateEnemy(typeId, position, parent, onDeath)
	local config = EnemyConfig.Get(typeId)
	local model = Instance.new("Model")
	model.Name = config.DisplayName:gsub("%s+", "")
	model:SetAttribute("Enemy", true)
	model:SetAttribute("EnemyType", typeId)
	model:SetAttribute("RewardXP", config.XP)
	model:SetAttribute("RewardMoney", config.Money)
	model.Parent = parent

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Position = position + Vector3.new(0, 3, 0)
	root.Transparency = 1
	root.Anchored = true
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
	root.Anchored = false
	body.Anchored = false
	head.Anchored = false

	humanoid.Died:Connect(function()
		model:SetAttribute("DeathRewarded", false)
		if onDeath then onDeath(model, config) end
	end)

	NPCService.StartEnemyAI(model)
	return model
end

return NPCService
