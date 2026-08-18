local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = game.Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local combatFeedback = remotes:WaitForChild("CombatFeedback")

local CRYSTAL_COLORS = {
	EMBER = Color3.fromRGB(255, 104, 42),
	TIDE = Color3.fromRGB(70, 170, 255),
	GALE = Color3.fromRGB(175, 255, 235),
}

local MAX_PRESENTATION_DISTANCE = 220

local function getRoot(model)
	return model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
end

local function isLocallyRelevant(model, root)
	local character = player.Character
	local localRoot = character and character:FindFirstChild("HumanoidRootPart")
	if not localRoot or not root then return false end
	return (localRoot.Position - root.Position).Magnitude <= MAX_PRESENTATION_DISTANCE
end

local function createDamageNumber(model, amount, critical)
	local root = getRoot(model)
	if not root or not isLocallyRelevant(model, root) then return end
	local safeAmount = math.max(0, tonumber(amount) or 0)
	if safeAmount <= 0 then return end

	local gui = Instance.new("BillboardGui")
	gui.Name = "DamageNumber"
	gui.Size = UDim2.fromOffset(130, 42)
	gui.StudsOffset = Vector3.new(math.random(-10, 10) / 10, 3.5, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = root
	gui.Parent = root

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = (critical and "CRIT " or "-") .. tostring(math.max(1, math.floor(safeAmount + 0.5)))
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
	local root = getRoot(model)
	if not root or not isLocallyRelevant(model, root) then return end

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

local function createCrystalImpact(model, crystalId, action, critical)
	local root = getRoot(model)
	if not root or not isLocallyRelevant(model, root) then return end

	local baseColor = CRYSTAL_COLORS[crystalId] or CRYSTAL_COLORS.EMBER
	local color = critical and Color3.fromRGB(255, 230, 90) or baseColor
	local scale = action == "Ability" and 1.5 or 0.95
	local finalScale = action == "Ability" and 5.5 or 3

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
	orb.Size = Vector3.new(scale, scale, scale)
	orb.CFrame = root.CFrame + Vector3.new(0, action == "Ability" and 1.25 or 1.0, 0)
	orb.Parent = root

	TweenService:Create(orb, TweenInfo.new(action == "Ability" and 0.24 or 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(finalScale, finalScale, finalScale),
		Transparency = 1,
	}):Play()

	task.delay(0.28, function()
		if orb.Parent then orb:Destroy() end
	end)
end

local function createAbilityAccent(model, crystalId)
	local root = getRoot(model)
	if not root or not isLocallyRelevant(model, root) then return end

	local color = CRYSTAL_COLORS[crystalId] or CRYSTAL_COLORS.EMBER
	if crystalId == "EMBER" then
		local ring = Instance.new("Part")
		ring.Name = "EmberConfirmedBurst"
		ring.Anchored = true
		ring.CanCollide = false
		ring.CanQuery = false
		ring.CanTouch = false
		ring.Shape = Enum.PartType.Cylinder
		ring.Material = Enum.Material.Neon
		ring.Color = color
		ring.Transparency = 0.25
		ring.Size = Vector3.new(0.45, 2, 2)
		ring.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, 0, math.rad(90))
		ring.Parent = root
		TweenService:Create(ring, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.45, 10, 10),
			Transparency = 1,
		}):Play()
		task.delay(0.32, function()
			if ring.Parent then ring:Destroy() end
		end)
	elseif crystalId == "TIDE" then
		for index = 1, 3 do
			local orb = Instance.new("Part")
			orb.Name = "TideConfirmedOrb"
			orb.Anchored = true
			orb.CanCollide = false
			orb.CanQuery = false
			orb.CanTouch = false
			orb.Shape = Enum.PartType.Ball
			orb.Material = Enum.Material.Neon
			orb.Color = color
			orb.Transparency = 0.2
			orb.Size = Vector3.new(0.65, 0.65, 0.65)
			orb.CFrame = CFrame.new(root.Position + Vector3.new((index - 2) * 1.6, 1 + index * 0.2, 0))
			orb.Parent = root
			TweenService:Create(orb, TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = root.Position + Vector3.new((index - 2) * 3, 3 + index * 0.6, 0),
				Transparency = 1,
			}):Play()
			task.delay(0.42, function()
				if orb.Parent then orb:Destroy() end
			end)
		end
	elseif crystalId == "GALE" then
		for index = 1, 2 do
			local slash = Instance.new("Part")
			slash.Name = "GaleConfirmedSlash"
			slash.Anchored = true
			slash.CanCollide = false
			slash.CanQuery = false
			slash.CanTouch = false
			slash.Material = Enum.Material.Neon
			slash.Color = color
			slash.Transparency = 0.2
			slash.Size = Vector3.new(0.3, 5, 0.3)
			slash.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.rad(index * 65), math.rad(index * 25))
			slash.Parent = root
			TweenService:Create(slash, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.3, 9, 0.3),
				Transparency = 1,
			}):Play()
			task.delay(0.26, function()
				if slash.Parent then slash:Destroy() end
			end)
		end
	end
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

local function watchPlayerHealth(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	if not humanoid then return end
	local lastHealth = humanoid.Health
	humanoid.HealthChanged:Connect(function(newHealth)
		if newHealth < lastHealth then shakePlayer() end
		lastHealth = newHealth
	end)
end

combatFeedback.OnClientEvent:Connect(function(targetModel, attackerUserId, action, crystalId, critical, amount)
	if typeof(targetModel) ~= "Instance" or not targetModel:IsDescendantOf(workspace) then return end
	if targetModel:GetAttribute("Enemy") ~= true then return end
	if type(action) ~= "string" or (action ~= "Basic" and action ~= "Ability") then return end
	if type(crystalId) ~= "string" or not CRYSTAL_COLORS[crystalId] then return end
	if type(attackerUserId) ~= "number" then return end

	local safeAmount = tonumber(amount) or 0
	if safeAmount <= 0 or safeAmount ~= safeAmount or safeAmount == math.huge or safeAmount == -math.huge then return end

	local root = getRoot(targetModel)
	if not root or not isLocallyRelevant(targetModel, root) then return end

	createDamageNumber(targetModel, safeAmount, critical == true)
	flashTarget(targetModel, crystalId, critical == true)
	createCrystalImpact(targetModel, crystalId, action, critical == true)
	if action == "Ability" then createAbilityAccent(targetModel, crystalId) end
end)

if player.Character then watchPlayerHealth(player.Character) end
player.CharacterAdded:Connect(watchPlayerHealth)