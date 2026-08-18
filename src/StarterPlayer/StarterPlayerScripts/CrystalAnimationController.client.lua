local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local animationConfig = require(ReplicatedStorage.Config.CrystalAnimationConfig)

local Controller = {}
local tracks = {}
local humanoid
local animator
local characterConnection

local function normalizeAnimationId(value)
	if type(value) ~= "string" or value == "" then return nil end
	if value:match("^rbxassetid://%d+$") then return value end
	local numeric = value:match("^%d+$")
	return numeric and ("rbxassetid://" .. numeric) or nil
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
end

local function getAnimator(character)
	local currentHumanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not currentHumanoid then return nil, nil end
	local currentAnimator = currentHumanoid:FindFirstChildOfClass("Animator")
	if not currentAnimator then
		currentAnimator = Instance.new("Animator")
		currentAnimator.Parent = currentHumanoid
	end
	return currentHumanoid, currentAnimator
end

local function loadTrack(crystalId, action)
	local crystal = animationConfig[crystalId]
	local definition = crystal and crystal[action]
	local animationId = definition and normalizeAnimationId(definition.AnimationId)
	if not animationId or not animator then return nil end

	local key = crystalId .. ":" .. action
	local cached = tracks[key]
	if cached then return cached, definition end

	local animation = Instance.new("Animation")
	animation.Name = "CrystalBound_" .. key:gsub(":", "_")
	animation.AnimationId = animationId
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

function Controller.Initialize()
	if characterConnection then characterConnection:Disconnect() end
	clearTracks()
	humanoid, animator = getAnimator(player.Character)
	characterConnection = player.CharacterAdded:Connect(function(character)
		clearTracks()
		humanoid, animator = getAnimator(character)
	end)
end

function Controller.Play(action, crystalId)
	crystalId = crystalId or player:GetAttribute("EquippedCrystal") or "EMBER"
	if action ~= "Basic" and action ~= "Ability" then return false end
	if not animator or not humanoid or humanoid.Health <= 0 then return false end

	local track, definition = loadTrack(crystalId, action)
	if not track then return false end

	for _, other in pairs(tracks) do
		if other ~= track and other.IsPlaying then
			stopTrack(other, definition.FadeTime)
		end
	end

	track:Play(definition.FadeTime, 1, definition.PlaybackSpeed or 1)
	return true
end

function Controller.Destroy()
	if characterConnection then
		characterConnection:Disconnect()
		characterConnection = nil
	end
	clearTracks()
	humanoid = nil
	animator = nil
end

Controller.Initialize()

return Controller
