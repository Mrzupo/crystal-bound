local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DialogConfig = require(ReplicatedStorage.Modules.NPCDialogConfig)
local InteractionConfig = require(ReplicatedStorage.Config.InteractionConfig)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local remote = remotes:FindFirstChild("NPCDialogRequest")
if remote then
	if not remote:IsA("RemoteFunction") then
		error(("Crystal Bound: NPCDialogRequest has class %s, expected RemoteFunction"):format(remote.ClassName))
	end
else
	remote = Instance.new("RemoteFunction")
	remote.Name = "NPCDialogRequest"
	remote.Parent = remotes
end

local REQUEST_INTERVAL = 0.2

local function finiteNumber(value, fallback)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return fallback end
	return number
end

local NPC_INTERACTION_RANGE = math.clamp(finiteNumber(InteractionConfig.NPCInteractionRange, 14), 4, 50)
local nextRequest = setmetatable({}, { __mode = "k" })

local function isNearCanonicalNPC(player, npcId)
	if npcId ~= "CrystalKeeper" and npcId ~= "MaterialTrader" then return false end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local folder = workspace:FindFirstChild("NPCs")
	local npc = folder and folder:FindFirstChild(npcId)
	if not npc or not npc:IsA("Model") or npc:GetAttribute("Interactable") ~= true then return false end
	local npcRoot = npc.PrimaryPart or npc:FindFirstChild("Torso")
	return root and npcRoot and (root.Position - npcRoot.Position).Magnitude <= NPC_INTERACTION_RANGE
end

remote.OnServerInvoke = function(player, npcId)
	local now = os.clock()
	if now < (nextRequest[player] or 0) then return nil end
	nextRequest[player] = now + REQUEST_INTERVAL
	if type(npcId) ~= "string" then return nil end
	local config = DialogConfig.Get(npcId)
	if not config or not isNearCanonicalNPC(player, npcId) then return nil end
	return {
		Name = config.Name,
		Lines = config.Lines,
		Options = config.Options,
	}
end

Players.PlayerRemoving:Connect(function(player)
	nextRequest[player] = nil
end)
