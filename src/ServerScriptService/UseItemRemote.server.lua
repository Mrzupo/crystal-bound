local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PlayerService = require(script.Parent.Services.PlayerService)
local InventoryService = require(script.Parent.Services.InventoryService)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local remote = remotes:FindFirstChild("UseItemRequest") or Instance.new("RemoteEvent")
remote.Name = "UseItemRequest"
remote.Parent = remotes

remote.OnServerEvent:Connect(function(player, itemId)
	if itemId ~= "HealthPotion" then return end
	local profile = PlayerService.GetProfile(player)
	if not profile or not InventoryService.HasItem(profile, itemId, 1) then
		player:SetAttribute("ShopMessage", "You do not have a Health Potion.")
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or humanoid.Health >= humanoid.MaxHealth then
		player:SetAttribute("ShopMessage", "You cannot use a Health Potion right now.")
		return
	end
	InventoryService.RemoveItem(profile, itemId, 1)
	humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 60)
	PlayerService.Sync(player)
	remotes.InventoryChanged:FireClient(player, profile.Inventory)
	player:SetAttribute("ShopMessage", "Health Potion restored 60 HP.")
end)

Players.PlayerRemoving:Connect(function(player)
	player:SetAttribute("UsingPotion", false)
end)
