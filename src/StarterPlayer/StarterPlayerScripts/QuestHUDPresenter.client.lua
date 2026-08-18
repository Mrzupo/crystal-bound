local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local getQuestData = remotes:WaitForChild("GetQuestData")

local FETCH_INTERVAL = 0.35
local fetching = false
local queued = false
local lastFetch = 0

local function getQuestLabel()
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then return nil end
	local hud = playerGui:FindFirstChild("CrystalBoundHUD")
	local panel = hud and hud:FindFirstChild("Panel")
	local label = panel and panel:FindFirstChild("Quest")
	return label
end

local function present(data)
	local label = getQuestLabel()
	if not label or not label:IsA("TextLabel") or type(data) ~= "table" then return end

	local active = data.Active or {}
	local progress = data.Progress or {}
	local definitions = data.Definitions or {}
	local questId = active[1]
	local definition = questId and definitions[questId]
	if not definition then
		label.Text = "Quest: no active quest"
		return
	end

	label.Text = string.format(
		"Quest: %s  •  %d/%d",
		definition.Name or questId,
		onumber(progress[questId]) or 0,
		onumber(definition.Goal) or 0
	)
end

local function fetchNow(force)
	local now = os.clock()
	if fetching then
		queued = true
		return
	end
	if not force and now - lastFetch < FETCH_INTERVAL then return end
	fetching = true
	lastFetch = now
	local ok, result = pcall(function()
		return getQuestData:InvokeServer()
	end)
	if ok then present(result) end
	fetching = false
	if queued then
		queued = false
		task.delay(FETCH_INTERVAL, function()
			if player.Parent then fetchNow(false) end
		end)
	end
end

player:GetAttributeChangedSignal("QuestMessage"):Connect(function()
	fetchNow(false)
end)
player:GetAttributeChangedSignal("ActiveQuestCount"):Connect(function()
	fetchNow(false)
end)
player:GetAttributeChangedSignal("CompletedQuestCount"):Connect(function()
	fetchNow(false)
end)

local playerGui = player:WaitForChild("PlayerGui")
playerGui.ChildAdded:Connect(function(child)
	if child.Name == "CrystalBoundHUD" then
		task.defer(function()
			if player.Parent then fetchNow(true) end
		end)
	end
end)

fetchNow(true)
