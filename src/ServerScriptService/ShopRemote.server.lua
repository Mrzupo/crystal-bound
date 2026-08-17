local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShopService = require(script.Parent.Services.ShopService)
local PlayerService = require(script.Parent.Services.PlayerService)
local InventoryService = require(script.Parent.Services.InventoryService)
local EconomyService = require(script.Parent.Services.EconomyService)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local remote = remotes:FindFirstChild("ShopRequest") or Instance.new("RemoteEvent")
remote.Name = "ShopRequest"
remote.Parent = remotes

remote.OnServerEvent:Connect(function(player, action, itemId, amount)
	local profile = PlayerService.GetProfile(player)
	if not profile then return end
	if action == "Buy" then
		local ok, message = ShopService.Buy(profile, itemId, amount, InventoryService, EconomyService)
		player:SetAttribute("ShopMessage", message)
		if ok then
			PlayerService.Sync(player)
			remotes.InventoryChanged:FireClient(player, profile.Inventory)
			remotes.MoneyChanged:FireClient(player, profile.Money)
		end
	end
end)
