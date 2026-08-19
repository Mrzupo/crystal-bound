local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local animationConfig = require(ReplicatedStorage.Config.CrystalAnimationConfig)
local assets = ReplicatedStorage:FindFirstChild("Assets")
local soundAssets = assets and assets:FindFirstChild("Sounds")

local VFX = {}

local COLORS = {
	EMBER = Color3.fromRGB(255, 104, 42),
	TIDE = Color3.fromRGB(70, 170, 255),
	GALE = Color3.fromRGB(175, 255, 235),
}

local ACTION_GUARD = {
	Basic = 0.07,
	Ability = 0.12,
}

local lastPlayed = {}

local function hasServerConfirmation(action, crystalId)
	local authorizedAt = tonumber(player:GetAttribute("CrystalVFXAuthorizedAt"))
	local authorizedAction = player:GetAttribute("CrystalVFXAuthorizedAction")
	local authorizedCrystal = player:GetAttribute("CrystalVFXAuthorizedCrystal")
	if type(authorizedAt) ~= "number" or authorizedAt ~= authorizedAt or authorizedAt == math.huge or authorizedAt == -math.huge then
		return false
	end
	if authorizedAction ~= action or authorizedCrystal ~= crystalId then return false end
	return os.clock() - authorizedAt <= 0.18
end

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
	Debris:AddItem(part, 0.22)

	TweenService:Create(part, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(scale * 3.2, scale * 3.2, scale * 3.2),
		Transparency = 1,
	}):Play()
end

local function playSound(root, definition)
	if not root or not definition then return end

	local sound
	if soundAssets and type(definition.SoundAssetName) == "string" and definition.SoundAssetName ~= "" then
		local source = soundAssets:FindFirstChild(definition.SoundAssetName)
		if source and source:IsA("Sound") then
			sound = source:Clone()
		end
	end

	if not sound then
		local soundId = definition.SoundId
		local normalized = type(soundId) == "string" and (soundId:match("^rbxassetid://") and soundId
			or (soundId:match("^%d+$") and ("rbxassetid://" .. soundId) or nil))
		if not normalized then return end
		sound = Instance.new("Sound")
		sound.SoundId = normalized
	end

	sound.Name = "CrystalBoundAbilitySound"
	sound.Volume = math.clamp(tonumber(definition.SoundVolume) or 0.5, 0, 1)
	sound.RollOffMaxDistance = 70
	sound.Parent = root
	sound:Play()
	Debris:AddItem(sound, math.max(2, sound.TimeLength > 0 and sound.TimeLength + 0.5 or 4))
end

function VFX.Play(action, crystalId)
	if action ~= "Basic" and action ~= "Ability" then return false end

	crystalId = crystalId or player:GetAttribute("EquippedCrystal") or "EMBER"
	if not hasServerConfirmation(action, crystalId) then return false end

	local now = os.clock()
	local key = action
	local guard = ACTION_GUARD[action] or 0.08
	if now - (lastPlayed[key] or -math.huge) < guard then
		return false
	end
	lastPlayed[key] = now

	local root = getRoot()
	if not root then return false end

	local crystal = animationConfig[crystalId] or animationConfig.EMBER
	local definition = crystal and crystal[action]
	local forward = root.CFrame.LookVector
	local offset = tonumber(definition and definition.VFXOffset) or (action == "Ability" and 4.5 or 3)
	local scale = tonumber(definition and definition.VFXScale) or (action == "Ability" and 0.7 or 0.38)

	makeBurst(root.Position + forward * offset + Vector3.new(0, 0.8, 0), crystalId, scale)
	playSound(root, definition)
	return true
end

return VFX