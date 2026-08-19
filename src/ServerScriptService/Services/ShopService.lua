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

local function positiveInteger(value)
	local number = finiteNumber(value)
	if number == nil then return nil end
	number = math.floor(number)
	if number <= 0 then return nil end
	return number
end

local function copyOffer(offer)
	if type(offer) ~= "table" then return offer end
	local result = {}
	for key, value in pairs(offer) do result[key] = value end
	return result
end

function ShopService.GetOffer(itemId)
	return copyOffer(Offers[itemId])
end

function ShopService.Buy(profile, itemId, amount, InventoryService, EconomyService)
	local offer = Offers[itemId]
	if not offer then return false, "Item is not for sale." end
	if type(offer.ItemId) ~= "string" or offer.ItemId ~= itemId or not InventoryConfig.GetItemConfig(itemId) then
		return false, "Shop offer is invalid."
	end
	local price = positiveInteger(offer.Price)
	if not price then return false, "Shop offer is invalid." end
	amount = positiveInteger(amount)
	if not amount then return false, "Purchase amount must be a positive integer." end
	local maxPerPurchase = positiveInteger(offer.MaxPerPurchase) or 1
	if amount > maxPerPurchase then return false, "Purchase amount exceeds the per-purchase limit." end
	local total = price * amount
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
	local copy = {}
	for itemId, offer in pairs(Offers) do
		copy[itemId] = copyOffer(offer)
	end
	return copy
end

return ShopService
