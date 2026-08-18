local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local animationConfig = require(ReplicatedStorage.Config.CrystalAnimationConfig)
local crystalConfig = require(ReplicatedStorage.Config.CrystalConfig)
local animationAssets = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Animations")

local Controller = {}
local tracks = {}
local lastPlay = {}
local humanoid
local animator
local characterConnection
local characterAncestryConnection
local generation = 0

local function normalizeAnimationId(value)
	if type(value) ~= "string" or value == "" then return nil end
	if value:match("^rbxassetid://%d+$") then return value end
	local numeric = value:match("^%d+$")
	return numeric and ("rbxassetid://" .. numeric) or nil
end

local function finiteNumber(value, fallback)
	local number = tonumber(value)
	if not number or number ~= number or number == math.huge or number == -math.huge then return fallback end
	return number
end

local function getLocalCooldown(crystalId, action)
	local config = action == "Ability" and crystalConfig.Abilities[crystalId] or crystalConfig.BasicAttack[crystalId]
	return math.max(0, finiteNumber(config and config.Cooldown, 0))
end

local function stopTrack(track, fadeTime)
	if track and track.IsPlaying then
		track:Stop(fadeTime or 0.08)
	end
end

local function clearTracks()
	for _, track in pairs(tracks) do
		stopTrack(track, 0.05)
		track:Destroy()
	end
	table.clear(tracks)
	table.clear(lastPlay)
end

local function disconnectCharacterSignals()
	if characterConnection then
		characterConnection:Disconnect()
		characterConnection = nil
	end
	if characterAncestryConnection then
		characterAncestryConnection:Disconnect()
		characterAncestryConnection = nil
	end
end

local function getAnimator(character)
	local currentHumanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not currentHumanoid then return nil, nil end

	local currentAnimator = currentHumanoid:FindFirstChildOfClass("Animator")
	if not currentAnimator then
		currentAnimator = currentHumanoid:WaitForChild("Animator", 5)
	end
	if not currentAnimator then return nil, nil end

	return currentHumanoid, currentAnimator
end

local function loadTrack(crystalId, action)
	local crystal = animationConfig[crystalId]
	local definition = crystal and crystal[action]
	if not definition or not animator then return nil end

	local key = crystalId .. ":" .. action
	local cached = tracks[key]
	if cached and cached.Parent then return cached, definition end
	tracks[key] = nil

	local animation
	if animationAssets and type(definition.AssetName) == "string" and definition.AssetName ~= "" then
		local source = animationAssets:FindFirstChild(definition.AssetName)
		if source and source:IsA("Animation") then
			animation = source:Clone()
		end
	end

	if not animation then
		local animationId = normalizeAnimationId(definition.AnimationId)
		if not animationId then return nil end
		animation = Instance.new("Animation")
		animation.AnimationId = animationId
	end

	animation.Name = "CrystalBound_" .. key:gsub(":", "_")
	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	animation:Destroy()
	if not ok or not track then return nil end

	track.Priority = Enum.AnimationPriority.Action
	track.Looped = false
	tracks[key] = track
	return track, definition
end

local function attachCharacter(character)
	generation += 1
	local localGeneration = generation
	clearTracks()
	humanoid = nil
	animator = nil

	local function tryAttach()
		if localGeneration ~= generation or not character.Parent then return false end
		local currentHumanoid, currentAnimator = getAnimator(character)
		if currentHumanoid and currentAnimator then
			humanoid = currentHumanoid
			animator = currentAnimator
			return true
		end
		return false
	end

	if not tryAttach() then
		task.spawn(function()
			if localGeneration ~= generation or not character.Parent then return end
			local currentHumanoid = character:WaitForChild("Humanoid", 5)
			if not currentHumanoid or localGeneration ~= generation then return end
			tryAttach()
		end)
	end

	if characterAncestryConnection then characterAncestryConnection:Disconnect() end
	characterAncestryConnection = character.AncestryChanged:Connect(function(_, parent)
		if parent == nil and localGeneration == generation then
			clearTracks()
			humanoid = nil
			animator = nil
		end
	end)
end

function Controller.Initialize()
	disconnectCharacterSignals()
	generation += 1
	clearTracks()
	humanoid = nil
	animator = nil

	if player.Character then
		attachCharacter(player.Character)
	end

	characterConnection = player.CharacterAdded:Connect(attachCharacter)
end

function Controller.Play(action, crystalId)
	crystalId = crystalId or player:GetAttribute("EquippedCrystal") or "EMBER"
	if action ~= "Basic" and action ~= "Ability" then return false end
	if not animator or not humanoid or humanoid.Health <= 0 then return false end

	local now = os.clock()
	local playKey = crystalId .. ":" .. action
	if now < (lastPlay[playKey] or 0) then return false end

	local track, definition = loadTrack(crystalId, action)
	if not track or not definition then return false end

	lastPlay[playKey] = now + getLocalCooldown(crystalId, action)
	for _, other in pairs(tracks) do
		if other ~= track and other.IsPlaying then
			stopTrack(other, finiteNumber(definition.FadeTime, 0.08))
		end
	end

	local fadeTime = math.max(0, finiteNumber(definition.FadeTime, 0.08))
	local playbackSpeed = math.max(0.05, finiteNumber(definition.PlaybackSpeed, 1))
	track:Play(fadeTime, 1, playbackSpeed)
	return true
end

function Controller.Destroy()
	generation += 1
	disconnectCharacterSignals()
	clearTracks()
	humanoid = nil
	animator = nil
end

Controller.Initialize()

return Controller
