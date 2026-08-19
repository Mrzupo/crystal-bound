local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ShopService = require(script.Parent.Services.ShopService)
local PlayerService = require(script.Parent.Services.PlayerService)
local InventoryService = require(script.Parent.Services.InventoryService)
local EconomyService = require(script.Parent.Services.EconomyService)
local InteractionConfig = require(ReplicatedStorage.Config.InteractionConfig)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local remote = remotes:FindFirstChild("ShopRequest") or Instance.new("RemoteEvent")
remote.Name = "ShopRequest"
remote.Parent = remotes

local NEXT_REQUEST = setmetatable({}, { __mode = "k" })
local REQUEST_INTERVAL = 0.15
local NPC_INTERACTION_RANGE = math.max(1, tonumber(InteractionConfig.NPCInteractionRange) or 14)

local function isNearTrader(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local folder = workspace:FindFirstChild("NPCs")
	local trader = folder and folder:FindFirstChild("MaterialTrader")
	local traderRoot = trader and (trader.PrimaryPart or trader:FindFirstChild("Torso"))
	return root and traderRoot and (root.Position - traderRoot.Position).Magnitude <= NPC_INTERACTION_RANGE
end

remote.OnServerEvent:Connect(function(player, action, itemId, amount)
	if action ~= "Buy" then return end
	local now = os.clock()
	if now < (NEXT_REQUEST[player] or 0) then return end
	NEXT_REQUEST[player] = now + REQUEST_INTERVAL

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
		remotes.InventoryChanged:FireClient(player, profile.Inventory)
		remotes.MoneyChanged:FireClient(player, profile.Money)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	NEXT_REQUEST[player] = nil
end)
