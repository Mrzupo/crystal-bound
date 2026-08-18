local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config.EconomyConfig)
local InventoryConfig = require(ReplicatedStorage.Config.InventoryConfig)

local EconomyService = {}

local function finiteNumber(value)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return nil end
	return number
end

function EconomyService.AddMoney(profile, amount)
	amount = finiteNumber(amount) or 0
	amount = math.max(0, amount)
	profile.Money = math.clamp(profile.Money + amount, Config.MinMoney, Config.MaxMoney)
	return profile.Money
end

function EconomyService.RemoveMoney(profile, amount)
	amount = finiteNumber(amount) or 0
	amount = math.max(0, amount)
	if profile.Money < amount then return false end
	profile.Money -= amount
	return true
end

function EconomyService.GetMoney(profile)
	return profile.Money
end

function EconomyService.CanAfford(profile, amount)
	amount = finiteNumber(amount) or 0
	return profile.Money >= math.max(0, amount)
end

function EconomyService.GetSellPrice(itemId)
	local item = InventoryConfig.GetItemConfig(itemId)
	local price = item and finiteNumber(item.SellPrice) or 0
	return math.max(0, price)
end

function EconomyService.SellItem(profile, itemId, amount, InventoryService)
	local numericAmount = finiteNumber(amount) or 1
	amount = math.max(1, math.floor(numericAmount))
	local price = EconomyService.GetSellPrice(itemId)
	if price <= 0 or not InventoryService.HasItem(profile, itemId, amount) then
		return false, 0
	end
	if not InventoryService.RemoveItem(profile, itemId, amount) then return false, 0 end
	local earned = price * amount
	EconomyService.AddMoney(profile, earned)
	return true, earned
end

return EconomyService