local Config = require(game.ReplicatedStorage.Config.InventoryConfig)
local InventoryService = {}

local function finiteNumber(value)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return nil end
	return number
end

local function normalizePositiveAmount(amount)
	local value = finiteNumber(amount)
	if value == nil or value <= 0 or value % 1 ~= 0 then return nil end
	return value
end

function InventoryService.IsValidItem(itemId)
	return type(itemId) == "string" and Config.GetItemConfig(itemId) ~= nil
end

function InventoryService.AddItem(profile, itemId, amount)
	if not InventoryService.IsValidItem(itemId) then return 0 end
	amount = normalizePositiveAmount(amount)
	if not amount then return 0 end
	if type(profile.Inventory) ~= "table" then profile.Inventory = {} end
	local maxStack = Config.GetMaxStackSize(itemId)
	local currentRaw = finiteNumber(profile.Inventory[itemId]) or 0
	local current = math.clamp(math.max(0, math.floor(currentRaw)), 0, maxStack)
	local nextAmount = math.min(maxStack, current + amount)
	local added = nextAmount - current
	profile.Inventory[itemId] = nextAmount
	return added
end

function InventoryService.RemoveItem(profile, itemId, amount)
	if not InventoryService.IsValidItem(itemId) then return false end
	amount = normalizePositiveAmount(amount)
	if not amount then return false end
	if type(profile.Inventory) ~= "table" then profile.Inventory = {} end
	local maxStack = Config.GetMaxStackSize(itemId)
	local currentRaw = finiteNumber(profile.Inventory[itemId]) or 0
	local current = math.clamp(math.max(0, math.floor(currentRaw)), 0, maxStack)
	if current < amount then return false end
	profile.Inventory[itemId] = current - amount
	return true
end

function InventoryService.HasItem(profile, itemId, amount)
	if not InventoryService.IsValidItem(itemId) then return false end
	amount = normalizePositiveAmount(amount)
	if not amount then return false end
	if type(profile.Inventory) ~= "table" then return false end
	local maxStack = Config.GetMaxStackSize(itemId)
	local current = math.clamp(math.max(0, math.floor(finiteNumber(profile.Inventory[itemId]) or 0)), 0, maxStack)
	return current >= amount
end

function InventoryService.GetInventory(profile)
	if type(profile.Inventory) ~= "table" then profile.Inventory = {} end
	local snapshot = {}
	for itemId, amount in pairs(profile.Inventory) do
		if InventoryService.IsValidItem(itemId) then
			local maxStack = Config.GetMaxStackSize(itemId)
			snapshot[itemId] = math.clamp(math.max(0, math.floor(finiteNumber(amount) or 0)), 0, maxStack)
		end
	end
	return snapshot
end

return InventoryService
