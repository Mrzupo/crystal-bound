local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryConfig = require(ReplicatedStorage.Config.InventoryConfig)
local CraftingConfig = require(ReplicatedStorage.Config.CraftingConfig)

local CraftingService = {}
local Recipes = CraftingConfig.Recipes

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

function CraftingService.GetRecipe(outputId)
	return Recipes[outputId]
end

function CraftingService.Craft(profile, outputId, amount, InventoryService)
	local recipe = Recipes[outputId]
	if not recipe then return false, "Recipe not found." end
	amount = positiveInteger(amount)
	if not amount then return false, "Craft amount must be a positive integer." end
	local maxPerCraft = positiveInteger(CraftingConfig.MaxPerCraft) or 1
	if amount > maxPerCraft then return false, "Craft amount exceeds the per-request limit." end

	InventoryService.GetInventory(profile)
	local outputConfig = InventoryConfig.GetItemConfig(recipe.Output)
	if not outputConfig then return false, "Crafting output is not registered." end

	local currentRaw = profile.Inventory[recipe.Output]
	local currentOutput = math.max(0, math.floor(finiteNumber(currentRaw) or 0))
	local recipeAmount = positiveInteger(recipe.Amount)
	if not recipeAmount then return false, "Crafting recipe output amount is invalid." end
	local maxStack = InventoryConfig.GetMaxStackSize(recipe.Output)
	local availableOutputSpace = math.max(0, maxStack - currentOutput)
	if recipeAmount > availableOutputSpace / math.max(1, amount) then
		return false, string.format("Not enough inventory space for %dx %s.", recipeAmount * math.min(amount, maxPerCraft), recipe.Output)
	end
	local outputAmount = recipeAmount * amount

	if type(recipe.Inputs) ~= "table" or next(recipe.Inputs) == nil then
		return false, "Crafting recipe has no valid inputs."
	end

	local consumed = {}
	for itemId, required in pairs(recipe.Inputs) do
		local safeRequired = positiveInteger(required)
		if not safeRequired then
			return false, string.format("Crafting recipe input %s is invalid.", tostring(itemId))
		end
		local totalRequired = safeRequired * amount
		if not InventoryService.HasItem(profile, itemId, totalRequired) then
			return false, string.format("Need %d %s to craft %dx %s.", totalRequired, itemId, amount, outputId)
		end
	end

	for itemId, required in pairs(recipe.Inputs) do
		local safeRequired = positiveInteger(required)
		local totalRequired = safeRequired * amount
		if not InventoryService.RemoveItem(profile, itemId, totalRequired) then
			for rollbackId, rollbackAmount in pairs(consumed) do InventoryService.AddItem(profile, rollbackId, rollbackAmount) end
			return false, "Crafting could not consume all materials safely."
		end
		consumed[itemId] = totalRequired
	end

	local added = InventoryService.AddItem(profile, recipe.Output, outputAmount)
	if added ~= outputAmount then
		for itemId, consumedAmount in pairs(consumed) do InventoryService.AddItem(profile, itemId, consumedAmount) end
		return false, "Crafting output could not be added safely."
	end

	return true, string.format("Crafted %dx %s.", outputAmount, outputId)
end

function CraftingService.GetRecipes()
	return Recipes
end

return CraftingService
