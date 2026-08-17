local ShopService = {}

local Offers = {
	HealthPotion = { ItemId = "HealthPotion", Price = 75, MaxPerPurchase = 10 },
}

function ShopService.GetOffer(itemId)
	return Offers[itemId]
end

function ShopService.Buy(profile, itemId, amount, InventoryService, EconomyService)
	local offer = Offers[itemId]
	if not offer then return false, "Item is not for sale." end
	amount = math.clamp(math.floor(tonumber(amount) or 1), 1, offer.MaxPerPurchase)
	local total = offer.Price * amount
	if (profile.Money or 0) < total then return false, "Not enough Money." end
	local current = profile.Inventory and profile.Inventory[itemId] or 0
	local free = InventoryService.GetInventory(profile)
	local maxStack = require(game.ReplicatedStorage.Config.InventoryConfig).GetMaxStackSize(itemId)
	if current + amount > maxStack then return false, "Inventory is full." end
	if not EconomyService.RemoveMoney(profile, total) then return false, "Unable to charge purchase." end
	InventoryService.AddItem(profile, itemId, amount)
	return true, string.format("Bought %dx %s for %d Money.", amount, offer.ItemId, total)
end

function ShopService.GetOffers()
	return Offers
end

return ShopService
