local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

if not UserInputService.TouchEnabled then
	return
end

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local combatRemote = remotes:WaitForChild("CombatRequest")
local crystalChanged = remotes:WaitForChild("CrystalChanged")
local crystalConfig = require(ReplicatedStorage.Config.CrystalConfig)
local crystalAnimationController = require(script.Parent:WaitForChild("CrystalAnimationController"))
local crystalVFXController = require(script.Parent:WaitForChild("CrystalVFXController"))

local selectedTarget = nil
local selectedTargetExpires = 0
local localAbilityReadyAt = 0

local function finiteNumber(value, fallback)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then
		return fallback
	end
	return number
end

local function getEquippedCrystal()
	local crystalId = player:GetAttribute("EquippedCrystal")
	if type(crystalId) ~= "string" or not crystalConfig.Abilities[crystalId] then
		return "EMBER"
	end
	return crystalId
end

local function getTargetRange(action)
	local crystalId = getEquippedCrystal()
	local config = action == "Ability" and crystalConfig.Abilities[crystalId] or crystalConfig.BasicAttack[crystalId]
	local range = config and finiteNumber(config.Range, nil)
	return range and range > 0 and range or nil
end

local function canPresentCombat(action, target)
	if not target then return false end
	local range = getTargetRange(action)
	if not range then return false end
	local character = player.Character
	local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
	local targetRoot = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
	if not playerRoot or not targetRoot then return false end
	if (playerRoot.Position - targetRoot.Position).Magnitude > range then return false end
	if action == "Ability" then
		local now = os.clock()
		local cooldownEnd = finiteNumber(player:GetAttribute("AbilityCooldownEnd"), 0)
		if now < math.max(cooldownEnd, localAbilityReadyAt) then return false end
		local crystalId = getEquippedCrystal()
		local cooldown = math.max(0, finiteNumber(crystalConfig.Abilities[crystalId].Cooldown, 0))
		localAbilityReadyAt = now + cooldown
	end
	return true
end

local function playPresentation(action)
	local crystal = getEquippedCrystal()
	crystalAnimationController.Play(action, crystal)
	crystalVFXController.Play(action, crystal)
end

local function resolveTargetFromTouch(position)
	local camera = Workspace.CurrentCamera
	if not camera then return nil end
	local unitRay = camera:ViewportPointToRay(position.X, position.Y)
	local character = player.Character
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = character and { character } or {}
	params.IgnoreWater = true
	local result = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, params)
	if not result or not result.Instance then return nil end
	local model = result.Instance:FindFirstAncestorOfClass("Model")
	if not model or model:GetAttribute("Enemy") ~= true then return nil end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return nil end
	return model
end

local function selectTarget(position)
	local target = resolveTargetFromTouch(position)
	if target then
		selectedTarget = target
		selectedTargetExpires = os.clock() + 5
		player:SetAttribute("TouchTarget", target.Name)
		return target
	end
	return nil
end

local function getTarget()
	if selectedTarget and selectedTarget.Parent and os.clock() < selectedTargetExpires then
		local humanoid = selectedTarget:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 and selectedTarget:GetAttribute("Enemy") == true then
			return selectedTarget
		end
	end
	selectedTarget = nil
	player:SetAttribute("TouchTarget", "")
	return nil
end

UserInputService.TouchTapInWorld:Connect(function(position)
	selectTarget(position)
end)

local gui = Instance.new("ScreenGui")
gui.Name = "TouchControls"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function makeButton(name, text, position, size, callback)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = position
	button.Size = size
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.BackgroundTransparency = 0.18
	button.Text = text
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.Parent = gui
	Instance.new("UICorner", button).CornerRadius = UDim.new(1, 0)
	button.Activated:Connect(callback)
	return button
end

makeButton("Attack", "ATK", UDim2.new(1, -95, 1, -100), UDim2.fromOffset(86, 86), function()
	local hit = getTarget()
	if hit and canPresentCombat("Basic", hit) then
		playPresentation("Basic")
		combatRemote:FireServer("Basic", hit)
	end
end)

makeButton("Ability", "Q", UDim2.new(1, -195, 1, -165), UDim2.fromOffset(74, 74), function()
	local hit = getTarget()
	if hit and canPresentCombat("Ability", hit) then
		playPresentation("Ability")
		combatRemote:FireServer("Ability", hit)
	end
end)

makeButton("Ember", "E", UDim2.new(0, 60, 1, -110), UDim2.fromOffset(64, 64), function() crystalChanged:FireServer("EMBER") end)
makeButton("Tide", "T", UDim2.new(0, 135, 1, -150), UDim2.fromOffset(64, 64), function() crystalChanged:FireServer("TIDE") end)
makeButton("Gale", "G", UDim2.new(0, 210, 1, -110), UDim2.fromOffset(64, 64), function() crystalChanged:FireServer("GALE") end)

local info = Instance.new("TextLabel")
info.Name = "Hint"
info.AnchorPoint = Vector2.new(0.5, 1)
info.Position = UDim2.new(0.5, 0, 1, -62)
info.Size = UDim2.fromOffset(420, 32)
info.BackgroundTransparency = 0.3
info.Text = "Touch Controls • Tap an enemy to target"
info.Font = Enum.Font.GothamMedium
info.TextSize = 13
info.Parent = gui
Instance.new("UICorner", info).CornerRadius = UDim.new(0, 8)

local targetLabel = Instance.new("TextLabel")
targetLabel.Name = "Target"
targetLabel.AnchorPoint = Vector2.new(0.5, 0)
targetLabel.Position = UDim2.new(0.5, 0, 0, 110)
targetLabel.Size = UDim2.fromOffset(360, 30)
targetLabel.BackgroundTransparency = 0.25
targetLabel.Font = Enum.Font.GothamBold
targetLabel.TextSize = 13
targetLabel.Parent = gui
Instance.new("UICorner", targetLabel).CornerRadius = UDim.new(0, 8)

task.spawn(function()
	while gui.Parent do
		local target = getTarget()
		targetLabel.Text = target and ("Target: " .. target.Name) or "Target: none"
		task.wait(0.2)
	end
end)
