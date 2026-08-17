local Config = require(game.ReplicatedStorage.Config.InventoryConfig)
local InventoryService = {}
function InventoryService.AddItem(profile, itemId, amount)
	amount = amount or 1
	local current = profile.Inventory[itemId] or 0
	local nextAmount = math.min(Config.GetMaxStackSize(itemId), current + amount)
	profile.Inventory[itemId] = nextAmount
	return nextAmount
end
function InventoryService.RemoveItem(profile, itemId, amount)
	amount = amount or 1
	local current = profile.Inventory[itemId] or 0
	if current < amount then return false end
	profile.Inventory[itemId] = current - amount
	return true
end
function InventoryService.HasItem(profile, itemId, amount) return (profile.Inventory[itemId] or 0) >= (amount or 1) end
function InventoryService.GetInventory(profile) return profile.Inventory end
return InventoryService
