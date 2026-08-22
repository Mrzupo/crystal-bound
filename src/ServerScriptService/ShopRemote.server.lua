local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ShopService = require(script.Parent.Services.ShopService)
local PlayerService = require(script.Parent.Services.PlayerService)
local InventoryService = require(script.Parent.Services.InventoryService)
local EconomyService = require(script.Parent.Services.EconomyService)
local InteractionConfig = require(ReplicatedStorage.Config.InteractionConfig)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local remote = remotes:FindFirstChild("ShopRequest")
if remote then
	if not remote:IsA("RemoteEvent") then
		error(("Crystal Bound: ShopRequest has class %s, expected RemoteEvent"):format(remote.ClassName))
	end
else
	remote = Instance.new("RemoteEvent")
	remote.Name = "ShopRequest"
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

local function isNearTrader(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local folder = workspace:FindFirstChild("NPCs")
	local trader = folder and folder:FindFirstChild("MaterialTrader")
	if not folder or not trader or not trader:IsA("Model") or trader.Parent ~= folder or trader:GetAttribute("Interactable") ~= true then return false end
	local traderRoot = trader.PrimaryPart or trader:FindFirstChild("Torso")
	if not root or not root:IsA("BasePart") or not traderRoot or not traderRoot:IsA("BasePart") then return false end
	return (root.Position - traderRoot.Position).Magnitude <= NPC_INTERACTION_RANGE
end

remote.OnServerEvent:Connect(function(player, action, itemId, amount)
	local now = os.clock()
	if now < (NEXT_REQUEST[player] or 0) then return end
	NEXT_REQUEST[player] = now + REQUEST_INTERVAL
	if action ~= "Buy" then return end
	if player:GetAttribute("ProfileLoaded") ~= true then return end

	local profile = PlayerService.GetProfile(player)
	if not profile then return end
	if not isNearTrader(player) then
		player:SetAttribute("ShopMessage", "You need to be near the Material Trader.")
		return
	end
	local ok, message = ShopService.Buy(profile, itemId, amount, InventoryService, EconomyService)
	player:SetAttribute("ShopMessage", message)
	if ok then
		PlayerService.Sync(player)
		remotes.InventoryChanged:FireClient(player, InventoryService.GetInventory(profile))
		remotes.MoneyChanged:FireClient(player, profile.Money)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	NEXT_REQUEST[player] = nil
end)