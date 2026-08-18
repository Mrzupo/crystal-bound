local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryConfig = require(ReplicatedStorage.Config.InventoryConfig)
local ShopConfig = require(ReplicatedStorage.Config.ShopConfig)

local ShopService = {}
local Offers = ShopConfig.Offers

local function finiteNumber(value)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return nil end
	return number
end

function ShopService.GetOffer(itemId)
	return Offers[itemId]
end

function ShopService.Buy(profile, itemId, amount, InventoryService, EconomyService)
	local offer = Offers[itemId]
	if not offer then return false, "Item is not for sale." end
	local numericAmount = finiteNumber(amount) or 1
	amount = math.clamp(math.floor(numericAmount), 1, math.max(1, math.floor(finiteNumber(offer.MaxPerPurchase) or 1)))
	local total = math.max(0, finiteNumber(offer.Price) or 0) * amount
	if not EconomyService.CanAfford(profile, total) then return false, "Not enough Money." end

	InventoryService.GetInventory(profile)
	local current = math.max(0, math.floor(finiteNumber(profile.Inventory[itemId]) or 0))
	local maxStack = InventoryConfig.GetMaxStackSize(itemId)
	if current + amount > maxStack then return false, "Inventory is full." end

	if not EconomyService.RemoveMoney(profile, total) then return false, "Unable to charge purchase." end
	local added = InventoryService.AddItem(profile, itemId, amount)
	if added ~= amount then
		EconomyService.AddMoney(profile, total)
		return false, "Purchase could not be added to inventory."
	end
	return true, string.format("Bought %dx %s for %d Money.", amount, offer.ItemId, total)
end

function ShopService.GetOffers()
	return Offers
end

return ShopService
