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
	if number == nil or number % 1 ~= 0 then return nil end
	number = math.floor(number)
	if number <= 0 then return nil end
	return number
end

local function safeProduct(left, right)
	local product = left * right
	if finiteNumber(product) == nil or product <= 0 or product % 1 ~= 0 then return nil end
	return product
end

local function cloneRecipe(recipe)
	if type(recipe) ~= "table" then return nil end
	local copy = {}
	for key, value in pairs(recipe) do
		if key == "Inputs" and type(value) == "table" then
			local inputs = {}
			for itemId, amount in pairs(value) do inputs[itemId] = amount end
			copy[key] = inputs
		else
			copy[key] = value
		end
	end
	return copy
end

function CraftingService.GetRecipe(outputId)
	return cloneRecipe(Recipes[outputId])
end

function CraftingService.Craft(profile, outputId, amount, InventoryService)
	local recipe = Recipes[outputId]
	if not recipe then return false, "Recipe not found." end
	if type(outputId) ~= "string" or type(recipe.Output) ~= "string" or recipe.Output ~= outputId then
		return false, "Crafting recipe output identity is invalid."
	end
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
	local outputAmount = safeProduct(recipeAmount, amount)
	if not outputAmount then
		return false, "Crafting output amount is out of bounds."
	end
	local maxStack = InventoryService.GetInventory(profile) and InventoryConfig.GetMaxStackSize(recipe.Output) or 0
	local availableOutputSpace = math.max(0, maxStack - currentOutput)
	if outputAmount > availableOutputSpace then
		return false, string.format("Not enough inventory space for %d %s.", outputAmount, recipe.Output)
	end

	if type(recipe.Inputs) ~= "table" or next(recipe.Inputs) == nil then
		return false, "Crafting recipe has no valid inputs."
	end

	local consumed = {}
	for itemId, required in pairs(recipe.Inputs) do
		if type(itemId) ~= "string" or not InventoryConfig.GetItemConfig(itemId) then
			return false, string.format("Crafting recipe input %s is not a registered item.", tostring(itemId))
		end
		local safeRequired = positiveInteger(required)
		if not safeRequired then
			return false, string.format("Crafting recipe input %s is invalid.", tostring(itemId))
		end
		local totalRequired = safeProduct(safeRequired, amount)
		if not totalRequired then
			return false, string.format("Crafting input %s is out of bounds.", tostring(itemId))
		end
		if not InventoryService.HasItem(profile, itemId, totalRequired) then
			return false, string.format("Need %d %s to craft %dx %s.", totalRequired, itemId, amount, outputId)
		end
	end

	for itemId, required in pairs(recipe.Inputs) do
		local safeRequired = positiveInteger(required)
		local totalRequired = safeRequired and safeProduct(safeRequired, amount) or nil
		if not totalRequired or not InventoryService.RemoveItem(profile, itemId, totalRequired) then
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
	local result = {}
	for outputId, recipe in pairs(Recipes) do
		result[outputId] = cloneRecipe(recipe)
	end
	return result
end

return CraftingService
