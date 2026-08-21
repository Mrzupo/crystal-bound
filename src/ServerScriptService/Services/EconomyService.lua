local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config.EconomyConfig)
local InventoryConfig = require(ReplicatedStorage.Config.InventoryConfig)

local EconomyService = {}

local function finiteNumber(value)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return nil end
	return number
end

local function nonNegativeInteger(value)
	local number = finiteNumber(value)
	if number == nil or number < 0 or number % 1 ~= 0 then return nil end
	return number
end

function EconomyService.AddMoney(profile, amount)
	amount = nonNegativeInteger(amount)
	if amount == nil then return false, 0 end
	local before = math.clamp(finiteNumber(profile.Money) or 0, Config.MinMoney, Config.MaxMoney)
	profile.Money = before
	local nextMoney = math.clamp(before + amount, Config.MinMoney, Config.MaxMoney)
	profile.Money = nextMoney
	return nextMoney, nextMoney - before
end

function EconomyService.RemoveMoney(profile, amount)
	amount = nonNegativeInteger(amount)
	if amount == nil then return false end
	local current = math.clamp(finiteNumber(profile.Money) or 0, Config.MinMoney, Config.MaxMoney)
	profile.Money = current
	if current < amount then return false end
	profile.Money = current - amount
	return true
end

function EconomyService.GetMoney(profile)
	return math.clamp(finiteNumber(profile.Money) or 0, Config.MinMoney, Config.MaxMoney)
end

function EconomyService.CanAfford(profile, amount)
	amount = nonNegativeInteger(amount)
	if amount == nil then return false end
	local current = math.clamp(finiteNumber(profile.Money) or 0, Config.MinMoney, Config.MaxMoney)
	return current >= amount
end

function EconomyService.GetSellPrice(itemId)
	local item = InventoryConfig.GetItemConfig(itemId)
	local price = item and nonNegativeInteger(item.SellPrice) or 0
	return math.max(0, price or 0)
end

function EconomyService.SellItem(profile, itemId, amount, InventoryService)
	amount = nonNegativeInteger(amount)
	if not amount or amount <= 0 then return false, 0 end
	local price = EconomyService.GetSellPrice(itemId)
	if price <= 0 or not InventoryService.HasItem(profile, itemId, amount) then
		return false, 0
	end

	if amount > Config.MaxMoney / price then
		return false, 0
	end
	local requestedEarned = price * amount
	if finiteNumber(requestedEarned) == nil then
		return false, 0
	end

	local beforeMoney = math.clamp(finiteNumber(profile.Money) or 0, Config.MinMoney, Config.MaxMoney)
	if beforeMoney + requestedEarned > Config.MaxMoney then
		return false, 0
	end

	if not InventoryService.RemoveItem(profile, itemId, amount) then
		return false, 0
	end

	local _, earned = EconomyService.AddMoney(profile, requestedEarned)
	if earned ~= requestedEarned then
		profile.Money = beforeMoney
		InventoryService.AddItem(profile, itemId, amount)
		return false, 0
	end

	return true, earned
end

return EconomyService
