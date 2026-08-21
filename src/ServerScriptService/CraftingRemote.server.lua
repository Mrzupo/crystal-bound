local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PlayerService = require(script.Parent.Services.PlayerService)
local InventoryService = require(script.Parent.Services.InventoryService)
local CraftingService = require(script.Parent.Services.CraftingService)
local InteractionConfig = require(ReplicatedStorage.Config.InteractionConfig)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local remote = remotes:FindFirstChild("CraftingRequest")
if remote then
	if not remote:IsA("RemoteEvent") then
		error(("Crystal Bound: CraftingRequest has class %s, expected RemoteEvent"):format(remote.ClassName))
	end
else
	remote = Instance.new("RemoteEvent")
	remote.Name = "CraftingRequest"
	remote.Parent = remotes
end

local NEXT_REQUEST = setmetatable({}, { __mode = "k" })
local REQUEST_INTERVAL = 0.15

local function finiteNumber(value, fallback)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return fallback end
	return number
end

local NPC_INTERACTION_RANGE = math.clamp(finiteNumber(InteractionConfig.NPCInteractionRange, 14), 4, 50)

local function getCanonicalTrader()
	local folder = workspace:FindFirstChild("NPCs")
	local trader = folder and folder:FindFirstChild("MaterialTrader")
	if not trader or not trader:IsA("Model") or trader.Parent ~= folder or trader:GetAttribute("Interactable") ~= true then return nil end
	return trader
end

local function isNearTrader(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local trader = getCanonicalTrader()
	local traderRoot = trader and (trader.PrimaryPart or trader:FindFirstChild("Torso"))
	return root and traderRoot and (root.Position - traderRoot.Position).Magnitude <= NPC_INTERACTION_RANGE
end

remote.OnServerEvent:Connect(function(player, action, outputId, amount)
	if action ~= "Craft" then return end
	if player:GetAttribute("ProfileLoaded") ~= true then return end
	local now = os.clock()
	if now < (NEXT_REQUEST[player] or 0) then return end
	NEXT_REQUEST[player] = now + REQUEST_INTERVAL

	local profile = PlayerService.GetProfile(player)
	if not profile then return end
	if not isNearTrader(player) then
		player:SetAttribute("CraftingMessage", "You need to be near the Material Trader to craft.")
		return
	end

	local ok, message = CraftingService.Craft(profile, outputId, amount, InventoryService)
	player:SetAttribute("CraftingMessage", message)
	if ok then
		PlayerService.Sync(player)
		remotes.InventoryChanged:FireClient(player, InventoryService.GetInventory(profile))
	end
end)

Players.PlayerRemoving:Connect(function(player)
	NEXT_REQUEST[player] = nil
end)
