local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("DodgeRequest")

local gui = Instance.new("ScreenGui")
gui.Name = "DodgeControls"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Name = "DodgeCooldown"
label.AnchorPoint = Vector2.new(1, 1)
label.Position = UDim2.new(1, -20, 1, -20)
label.Size = UDim2.fromOffset(150, 34)
label.BackgroundTransparency = 0.2
label.Font = Enum.Font.GothamBold
label.TextSize = 14
label.Parent = gui
Instance.new("UICorner", label).CornerRadius = UDim.new(0, 8)

local function fireDodge()
	local now = os.clock()
	local cooldownEnd = tonumber(player:GetAttribute("DodgeCooldownEnd")) or 0
	if now < cooldownEnd then return end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then return end
	local move = humanoid.MoveDirection
	if move.Magnitude < 0.1 then move = root.CFrame.LookVector end
	remote:FireServer(Vector3.new(move.X, 0, move.Z))
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonB then
		fireDodge()
	end
end)

if UserInputService.TouchEnabled then
	local button = Instance.new("TextButton")
	button.Name = "Dodge"
	button.AnchorPoint = Vector2.new(1, 1)
	button.Position = UDim2.new(1, -18, 1, -70)
	button.Size = UDim2.fromOffset(76, 54)
	button.Text = "DODGE"
	button.Font = Enum.Font.GothamBold
	button.TextSize = 13
	button.BackgroundTransparency = 0.15
	button.Parent = gui
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 12)
	button.Activated:Connect(fireDodge)
end

task.spawn(function()
	while gui.Parent do
		local remaining = math.max(0, (tonumber(player:GetAttribute("DodgeCooldownEnd")) or 0) - os.clock())
		label.Text = remaining > 0 and string.format("Dodge: %.1fs", remaining) or "Dodge: READY"
		task.wait(0.1)
	end
end)
