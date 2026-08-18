local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

local VFX = {}

local COLORS = {
	EMBER = Color3.fromRGB(255, 104, 42),
	TIDE = Color3.fromRGB(70, 170, 255),
	GALE = Color3.fromRGB(175, 255, 235),
}

local function getRoot()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function makeBurst(position, crystalId, scale)
	local part = Instance.new("Part")
	part.Name = "CrystalBoundAbilityVFX"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 0.35
	part.Shape = Enum.PartType.Ball
	part.Material = Enum.Material.Neon
	part.Color = COLORS[crystalId] or COLORS.EMBER
	part.Size = Vector3.new(scale, scale, scale)
	part.CFrame = CFrame.new(position)
	part.Parent = workspace
	Debris:AddItem(part, 0.18)

	local tweenService = game:GetService("TweenService")
	tweenService:Create(part, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(scale * 3.2, scale * 3.2, scale * 3.2),
		Transparency = 1,
	}):Play()
end

function VFX.Play(action, crystalId)
	if action ~= "Basic" and action ~= "Ability" then return end
	local root = getRoot()
	if not root then return end

	local forward = root.CFrame.LookVector
	local offset = action == "Ability" and 4.5 or 3
	local scale = action == "Ability" and 0.7 or 0.38
	makeBurst(root.Position + forward * offset + Vector3.new(0, 0.8, 0), crystalId, scale)
end

return VFX
