local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryConfig = require(ReplicatedStorage.Config.InventoryConfig)

local CraftingService = {}

local Recipes = {
	HealthPotion = {
		Output = "HealthPotion",
		Amount = 1,
		Inputs = { EmberShard = 2, TidePearl = 1 },
	},
}

function CraftingService.GetRecipe(outputId)
	return Recipes[outputId]
end

function CraftingService.Craft(profile, outputId, amount, InventoryService)
	local recipe = Recipes[outputId]
	if not recipe then return false, "Recipe not found." end
	amount = math.clamp(math.floor(tonumber(amount) or 1), 1, 10)

	local outputConfig = InventoryConfig.GetItemConfig(recipe.Output)
	if not outputConfig then return false, "Crafting output is not registered." end

	local currentOutput = math.max(0, math.floor((profile.Inventory and profile.Inventory[recipe.Output]) or 0))
	local outputAmount = recipe.Amount * amount
	local maxStack = InventoryConfig.GetMaxStackSize(recipe.Output)
	if currentOutput + outputAmount > maxStack then
		return false, string.format("Not enough inventory space for %dx %s.", outputAmount, recipe.Output)
	end

	for itemId, required in pairs(recipe.Inputs) do
		if not InventoryService.HasItem(profile, itemId, required * amount) then
			return false, string.format("Need %d %s to craft %dx %s.", required * amount, itemId, amount, outputId)
		end
	end

	for itemId, required in pairs(recipe.Inputs) do
		if not InventoryService.RemoveItem(profile, itemId, required * amount) then
			return false, "Crafting could not consume all materials safely."
		end
	end

	local added = InventoryService.AddItem(profile, recipe.Output, outputAmount)
	if added < currentOutput + outputAmount then
		return false, "Crafting output could not be added safely."
	end
	return true, string.format("Crafted %dx %s.", outputAmount, outputId)
end

function CraftingService.GetRecipes()
	return Recipes
end

return CraftingService
