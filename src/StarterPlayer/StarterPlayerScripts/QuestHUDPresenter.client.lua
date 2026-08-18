local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local getQuestData = remotes:WaitForChild("GetQuestData")

local FETCH_INTERVAL = 0.35
local fetching = false
local queued = false
local lastFetch = 0
local cachedData = nil
local boundLabel = nil
local rebinding = false

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
	cachedData = data

	local active = data.Active or {}
	local progress = data.Progress or {}
	local definitions = data.Definitions or {}
	local questId = active[1]
	local definition = questId and definitions[questId]
	local text
	if not definition then
		text = "Quest: no active quest"
	else
		text = string.format(
			"Quest: %s  •  %d/%d",
			definition.Name or questId,
			tonumber(progress[questId]) or 0,
			tonumber(definition.Goal) or 0
		)
	end

	if label.Text ~= text then
		rebinding = true
		label.Text = text
		rebinding = false
	end

	if boundLabel ~= label then
		boundLabel = label
		label:GetPropertyChangedSignal("Text"):Connect(function()
			if rebinding or not cachedData or label.Parent == nil then return end
			if label.Text == "" or label.Text == "Quest: " then
				present(cachedData)
			end
		end)
	end
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

task.spawn(function()
	while player.Parent do
		task.wait(1)
		if player.Parent then
			local label = getQuestLabel()
			if label and (label.Text == "" or label.Text == "Quest: ") then
				if cachedData then present(cachedData) else fetchNow(false) end
			end
		end
	end
end)

fetchNow(true)
