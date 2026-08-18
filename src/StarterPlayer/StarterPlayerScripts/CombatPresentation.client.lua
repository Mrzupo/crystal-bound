local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local watched = {}

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

local function flashTarget(model, critical)
	if not model or not model.Parent then return end
	local old = model:FindFirstChild("CrystalBoundHitFlash")
	if old then old:Destroy() end

	local highlight = Instance.new("Highlight")
	highlight.Name = "CrystalBoundHitFlash"
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillTransparency = critical and 0.18 or 0.35
	highlight.OutlineTransparency = 0.05
	highlight.FillColor = critical and Color3.fromRGB(255, 210, 80) or Color3.fromRGB(255, 95, 95)
	highlight.OutlineColor = critical and Color3.fromRGB(255, 245, 180) or Color3.fromRGB(255, 180, 180)
	highlight.Parent = model

	TweenService:Create(highlight, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FillTransparency = 1,
		OutlineTransparency = 1,
	}):Play()

	task.delay(0.22, function()
		if highlight.Parent then highlight:Destroy() end
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
				local critical = model:GetAttribute("LastHitCritical") == true
				createDamageNumber(model, amount, critical)
				flashTarget(model, model:GetAttribute("BossId") ~= nil or critical)
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