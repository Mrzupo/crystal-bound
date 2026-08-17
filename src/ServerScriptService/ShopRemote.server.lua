local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShopService = require(script.Parent.Services.ShopService)
local PlayerService = require(script.Parent.Services.PlayerService)
local InventoryService = require(script.Parent.Services.InventoryService)
local EconomyService = require(script.Parent.Services.EconomyService)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local remote = remotes:FindFirstChild("ShopRequest") or Instance.new("RemoteEvent")
remote.Name = "ShopRequest"
remote.Parent = remotes

local function isNearTrader(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local folder = workspace:FindFirstChild("NPCs")
	local trader = folder and folder:FindFirstChild("MaterialTrader")
	local traderRoot = trader and (trader.PrimaryPart or trader:FindFirstChild("Torso"))
	return root and traderRoot and (root.Position - traderRoot.Position).Magnitude <= 14
end

remote.OnServerEvent:Connect(function(player, action, itemId, amount)
	local profile = PlayerService.GetProfile(player)
	if not profile or action ~= "Buy" then return end
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
