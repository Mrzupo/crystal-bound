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
	local before = math.clamp(finiteNumber(profile.Money) or 0, Config.MinMoney, Config.MaxMoney)
	profile.Money = before
	local nextMoney = math.clamp(before + amount, Config.MinMoney, Config.MaxMoney)
	profile.Money = nextMoney
	return nextMoney, nextMoney - before
end

function EconomyService.RemoveMoney(profile, amount)
	amount = finiteNumber(amount) or 0
	amount = math.max(0, amount)
	local current = math.clamp(finiteNumber(profile.Money) or 0, Config.MinMoney, Config.MaxMoney)
	profile.Money = current
	if current < amount then return false end
	profile.Money = current - amount
	return true
end

function EconomyService.GetMoney(profile)
	local current = math.clamp(finiteNumber(profile.Money) or 0, Config.MinMoney, Config.MaxMoney)
	profile.Money = current
	return current
end

function EconomyService.CanAfford(profile, amount)
	amount = finiteNumber(amount) or 0
	local current = math.clamp(finiteNumber(profile.Money) or 0, Config.MinMoney, Config.MaxMoney)
	profile.Money = current
	return current >= math.max(0, amount)
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
	if InventoryService.RemoveItem(profile, itemId, amount) ~= true then return false, 0 end
	local requestedEarned = price * amount
	local _, earned = EconomyService.AddMoney(profile, requestedEarned)
	return true, earned
end

return EconomyService
