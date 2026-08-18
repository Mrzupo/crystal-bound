local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PlayerService = require(script.Parent.Services.PlayerService)
local InventoryService = require(script.Parent.Services.InventoryService)
local ConsumableConfig = require(ReplicatedStorage.Config.ConsumableConfig)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local remote = remotes:FindFirstChild("UseItemRequest") or Instance.new("RemoteEvent")
remote.Name = "UseItemRequest"
remote.Parent = remotes

local NEXT_USE = setmetatable({}, { __mode = "k" })
local USE_INTERVAL = 0.2

remote.OnServerEvent:Connect(function(player, itemId)
	local potion = ConsumableConfig.HealthPotion
	if type(potion) ~= "table" or type(potion.ItemId) ~= "string" then return end
	if type(itemId) ~= "string" or itemId ~= potion.ItemId then return end
	local healAmount = tonumber(potion.HealAmount)
	if type(healAmount) ~= "number" or healAmount ~= healAmount or healAmount == math.huge or healAmount <= 0 then
		player:SetAttribute("ShopMessage", "Health Potion configuration is unavailable.")
		return
	end
	local now = os.clock()
	if now < (NEXT_USE[player] or 0) then return end
	NEXT_USE[player] = now + USE_INTERVAL

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
	if not InventoryService.RemoveItem(profile, itemId, 1) then
		player:SetAttribute("ShopMessage", "Unable to consume Health Potion safely.")
		return
	end
	humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + healAmount)
	PlayerService.Sync(player)
	remotes.InventoryChanged:FireClient(player, profile.Inventory)
	player:SetAttribute("ShopMessage", string.format("Health Potion restored %d HP.", healAmount))
end)

Players.PlayerRemoving:Connect(function(player)
	NEXT_USE[player] = nil
end)
