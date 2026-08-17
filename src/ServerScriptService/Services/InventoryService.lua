local Config = require(game.ReplicatedStorage.Config.InventoryConfig)
local InventoryService = {}
local function normalizeAmount(amount, default)
	local value = tonumber(amount)
	if value == nil then return default or 1 end
	return math.max(1, math.floor(value))
end
function InventoryService.IsValidItem(itemId)
	return type(itemId) == "string" and Config.GetItemConfig(itemId) ~= nil
end
function InventoryService.AddItem(profile, itemId, amount)
	if not InventoryService.IsValidItem(itemId) then return 0 end
	amount = normalizeAmount(amount, 1)
	profile.Inventory = profile.Inventory or {}
	local current = math.max(0, math.floor(profile.Inventory[itemId] or 0))
	local nextAmount = math.min(Config.GetMaxStackSize(itemId), current + amount)
	profile.Inventory[itemId] = nextAmount
	return nextAmount
end
function InventoryService.RemoveItem(profile, itemId, amount)
	if not InventoryService.IsValidItem(itemId) then return false end
	amount = normalizeAmount(amount, 1)
	profile.Inventory = profile.Inventory or {}
	local current = math.max(0, math.floor(profile.Inventory[itemId] or 0))
	if current < amount then return false end
	profile.Inventory[itemId] = current - amount
	return true
end
function InventoryService.HasItem(profile, itemId, amount)
	if not InventoryService.IsValidItem(itemId) then return false end
	amount = normalizeAmount(amount, 1)
	return (profile.Inventory and profile.Inventory[itemId] or 0) >= amount
end
function InventoryService.GetInventory(profile)
	profile.Inventory = profile.Inventory or {}
	return profile.Inventory
end
return InventoryService
