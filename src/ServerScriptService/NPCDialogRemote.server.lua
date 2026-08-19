local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DialogConfig = require(ReplicatedStorage.Modules.NPCDialogConfig)
local InteractionConfig = require(ReplicatedStorage.Config.InteractionConfig)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local remote = remotes:FindFirstChild("NPCDialogRequest") or Instance.new("RemoteFunction")
remote.Name = "NPCDialogRequest"
remote.Parent = remotes

local REQUEST_INTERVAL = 0.2
local NPC_INTERACTION_RANGE = math.max(1, tonumber(InteractionConfig.NPCInteractionRange) or 14)
local nextRequest = setmetatable({}, { __mode = "k" })

local function isNearNPC(player, npcId)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local folder = workspace:FindFirstChild("NPCs")
	local npc = folder and folder:FindFirstChild(npcId)
	local npcRoot = npc and (npc.PrimaryPart or npc:FindFirstChild("Torso"))
	return root and npcRoot and (root.Position - npcRoot.Position).Magnitude <= NPC_INTERACTION_RANGE
end

remote.OnServerInvoke = function(player, npcId)
	local now = os.clock()
	if now < (nextRequest[player] or 0) then return nil end
	nextRequest[player] = now + REQUEST_INTERVAL
	if type(npcId) ~= "string" then return nil end
	local config = DialogConfig.Get(npcId)
	if not config or not isNearNPC(player, npcId) then return nil end
	return {
		Name = config.Name,
		Lines = config.Lines,
		Options = config.Options,
	}
end

Players.PlayerRemoving:Connect(function(player)
	nextRequest[player] = nil
end)
