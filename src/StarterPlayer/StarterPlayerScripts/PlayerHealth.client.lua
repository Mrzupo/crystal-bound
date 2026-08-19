local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui
local barBack
local barFill
local valueLabel
local deathLabel
local lastHealth = nil

local function finiteNumber(value, fallback)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then
		return fallback
	end
	return number
end

local function ensureGui()
	local playerGui = player:WaitForChild("PlayerGui")
	gui = playerGui:FindFirstChild("PlayerHealthUI")
	if gui then return end

	gui = Instance.new("ScreenGui")
	gui.Name = "PlayerHealthUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	local container = Instance.new("Frame")
	container.Name = "HealthPanel"
	container.Position = UDim2.new(0, 16, 1, -92)
	container.Size = UDim2.fromOffset(360, 58)
	container.BackgroundTransparency = 0.2
	container.Parent = gui
	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromOffset(70, 22)
	title.Position = UDim2.fromOffset(10, 4)
	title.BackgroundTransparency = 1
	title.Text = "HEALTH"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = container

	barBack = Instance.new("Frame")
	barBack.Name = "Back"
	barBack.Position = UDim2.fromOffset(10, 27)
	barBack.Size = UDim2.fromOffset(340, 20)
	barBack.BackgroundTransparency = 0.15
	barBack.Parent = container
	Instance.new("UICorner", barBack).CornerRadius = UDim.new(0, 6)

	barFill = Instance.new("Frame")
	barFill.Name = "Fill"
	barFill.Size = UDim2.fromScale(1, 1)
	barFill.Parent = barBack
	Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 6)

	valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.fromScale(1, 1)
	valueLabel.BackgroundTransparency = 1
	valueLabel.TextXAlignment = Enum.TextXAlignment.Center
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextSize = 13
	valueLabel.Parent = barBack

	deathLabel = Instance.new("TextLabel")
	deathLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	deathLabel.Position = UDim2.new(0.5, 0, 0.45, 0)
	deathLabel.Size = UDim2.fromOffset(500, 60)
	deathLabel.BackgroundTransparency = 0.2
	deathLabel.Text = ""
	deathLabel.Font = Enum.Font.GothamBlack
	deathLabel.TextSize = 24
	deathLabel.Visible = false
	deathLabel.Parent = gui
	Instance.new("UICorner", deathLabel).CornerRadius = UDim.new(0, 10)
end

local function update()
	ensureGui()
	local health = math.max(0, finiteNumber(player:GetAttribute("Health"), 0))
	local maxHealth = math.max(1, finiteNumber(player:GetAttribute("MaxHealth"), 100))
	local ratio = math.clamp(health / maxHealth, 0, 1)
	barFill.Size = UDim2.fromScale(ratio, 1)
	valueLabel.Text = string.format("%d / %d", math.floor(health + 0.5), math.floor(maxHealth + 0.5))
	local rawDeathMessage = player:GetAttribute("DeathMessage")
	local deathMessage = type(rawDeathMessage) == "string" and rawDeathMessage or ""
	if deathMessage ~= "" then
		deathLabel.Text = deathMessage
		deathLabel.Visible = true
	else
		deathLabel.Visible = false
	end
	lastHealth = health
end

for _, attribute in ipairs({ "Health", "MaxHealth", "DeathMessage" }) do
	player:GetAttributeChangedSignal(attribute):Connect(update)
end

player.CharacterAdded:Connect(function()
	lastHealth = nil
	task.delay(0.25, update)
end)

ensureGui()
update()

player:GetAttributeChangedSignal("Health"):Connect(function()
	local health = finiteNumber(player:GetAttribute("Health"), 0)
	if health <= 0 then return end
	local panel = gui and gui:FindFirstChild("HealthPanel")
	if panel then
		panel.Size = UDim2.fromOffset(360, 58)
		TweenService:Create(panel, TweenInfo.new(0.12), { Size = UDim2.fromOffset(370, 62) }):Play()
		task.delay(0.13, function()
			if panel.Parent then TweenService:Create(panel, TweenInfo.new(0.12), { Size = UDim2.fromOffset(360, 58) }):Play() end
		end)
	end
end)
