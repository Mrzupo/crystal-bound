local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local watched = {}

local CRYSTAL_COLORS = {
	EMBER = Color3.fromRGB(255, 104, 42),
	TIDE = Color3.fromRGB(70, 170, 255),
	GALE = Color3.fromRGB(175, 255, 235),
}

local function createDamageNumber(model, amount, critical)
	local root = model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
	if not root then return end
	local gui = Instance.new("BillboardGui")
	gui.Name = "DamageNumber"
	gui.Size = UDim2.fromOffset(120, 42)
	gui.StudsOffset = Vector3.new(math.random(-10, 10) / 10, 3.5, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = root
	gui.Parent = root

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = (critical and "CRIT " or "-") .. tostring(math.max(1, math.floor(amount + 0.5)))
	label.Font = Enum.Font.GothamBlack
	label.TextSize = critical and 22 or 18
	label.TextStrokeTransparency = 0.35
	label.Parent = gui

	local start = gui.StudsOffset
	TweenService:Create(gui, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffset = start + Vector3.new(0, 2.2, 0),
	}):Play()
	TweenService:Create(label, TweenInfo.new(0.45), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(0.48, function()
		if gui.Parent then gui:Destroy() end
	end)
end

local function flashTarget(model, crystalId, critical)
	if not model or not model.Parent then return end
	local old = model:FindFirstChild("CrystalBoundHitFlash")
	if old then old:Destroy() end

	local baseColor = CRYSTAL_COLORS[crystalId] or Color3.fromRGB(255, 95, 95)
	local fillColor = critical and Color3.fromRGB(255, 210, 80) or baseColor
	local outlineColor = critical and Color3.fromRGB(255, 245, 180) or baseColor:Lerp(Color3.new(1, 1, 1), 0.45)
	local highlight = Instance.new("Highlight")
	highlight.Name = "CrystalBoundHitFlash"
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillTransparency = critical and 0.12 or 0.28
	highlight.OutlineTransparency = 0.05
	highlight.FillColor = fillColor
	highlight.OutlineColor = outlineColor
	highlight.Parent = model

	TweenService:Create(highlight, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FillTransparency = 1,
		OutlineTransparency = 1,
	}):Play()

	task.delay(0.24, function()
		if highlight.Parent then highlight:Destroy() end
	end)
end

local function createCrystalImpact(model, crystalId, critical)
	local root = model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
	if not root then return end

	local color = critical and Color3.fromRGB(255, 230, 90) or CRYSTAL_COLORS[crystalId] or CRYSTAL_COLORS.EMBER
	local orb = Instance.new("Part")
	orb.Name = "CrystalBoundConfirmedImpact"
	orb.Anchored = true
	orb.CanCollide = false
	orb.CanQuery = false
	orb.CanTouch = false
	orb.Shape = Enum.PartType.Ball
	orb.Material = Enum.Material.Neon
	orb.Color = color
	orb.Transparency = 0.15
	orb.Size = critical and Vector3.new(1.8, 1.8, 1.8) or Vector3.new(1.15, 1.15, 1.15)
	orb.CFrame = root.CFrame + Vector3.new(0, 1.1, 0)
	orb.Parent = Workspace

	local finalSize = critical and 6 or 3.5
	TweenService:Create(orb, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(finalSize, finalSize, finalSize),
		Transparency = 1,
	}):Play()
	task.delay(0.2, function()
		if orb.Parent then orb:Destroy() end
	end)
end

local function shakePlayer()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local original = humanoid.CameraOffset
	local target = original + Vector3.new(math.random(-12, 12) / 100, math.random(-8, 8) / 100, 0)
	TweenService:Create(humanoid, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CameraOffset = target,
	}):Play()
	task.delay(0.07, function()
		if humanoid.Parent then
			TweenService:Create(humanoid, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				CameraOffset = original,
			}):Play()
		end
	end)
end

local function watchHumanoid(humanoid)
	if watched[humanoid] then return end
	local lastHealth = humanoid.Health
	watched[humanoid] = true

	humanoid.HealthChanged:Connect(function(newHealth)
		if newHealth < lastHealth then
			local model = humanoid.Parent
			if model and model:GetAttribute("Enemy") == true then
				local amount = lastHealth - newHealth
				local crystalId = model:GetAttribute("LastHitCrystal")
				local critical = model:GetAttribute("LastHitCritical") == true
				createDamageNumber(model, amount, critical)
				flashTarget(model, crystalId, critical)
				createCrystalImpact(model, crystalId, critical)
			elseif model == player.Character then
				shakePlayer()
			end
		end
		lastHealth = newHealth
	end)

	humanoid.AncestryChanged:Connect(function(_, parent)
		if not parent then watched[humanoid] = nil end
	end)
end

local function scan()
	local folder = Workspace:FindFirstChild("NPCs")
	if folder then
		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("Model") then
				local humanoid = child:FindFirstChildOfClass("Humanoid")
				if humanoid then watchHumanoid(humanoid) end
			end
		end
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then watchHumanoid(humanoid) end
end

player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then watchHumanoid(humanoid) end
end)

scan()
task.spawn(function()
	while true do
		scan()
		task.wait(0.4)
	end
end)