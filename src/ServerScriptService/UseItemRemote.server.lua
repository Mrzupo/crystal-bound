local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PlayerService = require(script.Parent.Services.PlayerService)
local InventoryService = require(script.Parent.Services.InventoryService)
local ConsumableConfig = require(ReplicatedStorage.Config.ConsumableConfig)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local remote = remotes:FindFirstChild("UseItemRequest")
if remote then
	if not remote:IsA("RemoteEvent") then
		error(("Crystal Bound: UseItemRequest has class %s, expected RemoteEvent"):format(remote.ClassName))
	end
else
	remote = Instance.new("RemoteEvent")
	remote.Name = "UseItemRequest"
	remote.Parent = remotes
end

local NEXT_USE = setmetatable({}, { __mode = "k" })
local USE_INTERVAL = 0.2

local function finiteNumber(value, fallback)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return fallback end
	return number
end

remote.OnServerEvent:Connect(function(player, itemId)
	if not player or not player:IsA("Player") then return end
	local now = os.clock()
	if now < (NEXT_USE[player] or 0) then return end
	NEXT_USE[player] = now + USE_INTERVAL

	local potion = ConsumableConfig.HealthPotion
	if type(potion) ~= "table" or type(potion.ItemId) ~= "string" then return end
	if type(itemId) ~= "string" or itemId ~= potion.ItemId then return end
	local healAmount = finiteNumber(potion.HealAmount, 0)
	if healAmount <= 0 then
		player:SetAttribute("ShopMessage", "Health Potion configuration is unavailable.")
		return
	end
	healAmount = math.clamp(healAmount, 0.1, 1000)

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
	local applied = PlayerService.Heal(player, healAmount)
	if applied <= 0 then
		InventoryService.AddItem(profile, itemId, 1)
		player:SetAttribute("ShopMessage", "Health Potion could not heal safely.")
		return
	end
	PlayerService.Sync(player)
	remotes.InventoryChanged:FireClient(player, InventoryService.GetInventory(profile))
	player:SetAttribute("ShopMessage", string.format("Health Potion restored %d HP.", math.floor(applied + 0.5)))
end)

Players.PlayerRemoving:Connect(function(player)
	NEXT_USE[player] = nil
end)