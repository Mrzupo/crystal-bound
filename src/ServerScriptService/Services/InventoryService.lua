local Config = require(game.ReplicatedStorage.Config.InventoryConfig)
local InventoryService = {}

local function finiteNumber(value)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return nil end
	return number
end

local function normalizeAmount(amount, default)
	local value = finiteNumber(amount)
	if value == nil then return default or 1 end
	return math.max(1, math.floor(value))
end

function InventoryService.IsValidItem(itemId)
	return type(itemId) == "string" and Config.GetItemConfig(itemId) ~= nil
end

function InventoryService.AddItem(profile, itemId, amount)
	if not InventoryService.IsValidItem(itemId) then return 0 end
	amount = normalizeAmount(amount, 1)
	profile.Inventory = type(profile.Inventory) == "table" and profile.Inventory or {}
	local currentRaw = finiteNumber(profile.Inventory[itemId]) or 0
	local current = math.max(0, math.floor(currentRaw))
	local nextAmount = math.min(Config.GetMaxStackSize(itemId), current + amount)
	local added = nextAmount - current
	profile.Inventory[itemId] = nextAmount
	return added
end

function InventoryService.RemoveItem(profile, itemId, amount)
	if not InventoryService.IsValidItem(itemId) then return false end
	amount = normalizeAmount(amount, 1)
	profile.Inventory = type(profile.Inventory) == "table" and profile.Inventory or {}
	local currentRaw = finiteNumber(profile.Inventory[itemId]) or 0
	local current = math.max(0, math.floor(currentRaw))
	if current < amount then return false end
	profile.Inventory[itemId] = current - amount
	return true
end

function InventoryService.HasItem(profile, itemId, amount)
	if not InventoryService.IsValidItem(itemId) then return false end
	amount = normalizeAmount(amount, 1)
	if type(profile.Inventory) ~= "table" then return false end
	return (finiteNumber(profile.Inventory[itemId]) or 0) >= amount
end

function InventoryService.GetInventory(profile)
	if type(profile.Inventory) ~= "table" then profile.Inventory = {} end
	return profile.Inventory
end

return InventoryService
