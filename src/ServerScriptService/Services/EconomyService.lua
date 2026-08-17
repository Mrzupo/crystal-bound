local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config.EconomyConfig)
local InventoryConfig = require(ReplicatedStorage.Config.InventoryConfig)

local EconomyService = {}

function EconomyService.AddMoney(profile, amount)
	amount = math.max(0, tonumber(amount) or 0)
	profile.Money = math.clamp(profile.Money + amount, Config.MinMoney, Config.MaxMoney)
	return profile.Money
end

function EconomyService.RemoveMoney(profile, amount)
	amount = math.max(0, tonumber(amount) or 0)
	if profile.Money < amount then return false end
	profile.Money -= amount
	return true
end

function EconomyService.GetMoney(profile)
	return profile.Money
end

function EconomyService.CanAfford(profile, amount)
	return profile.Money >= math.max(0, tonumber(amount) or 0)
end

function EconomyService.GetSellPrice(itemId)
	local item = InventoryConfig.GetItemConfig(itemId)
	return item and math.max(0, item.SellPrice or 0) or 0
end

function EconomyService.SellItem(profile, itemId, amount, InventoryService)
	amount = math.max(1, math.floor(tonumber(amount) or 1))
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
