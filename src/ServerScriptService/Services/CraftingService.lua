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
	for itemId, required in pairs(recipe.Inputs) do
		if not InventoryService.HasItem(profile, itemId, required * amount) then
			return false, string.format("Need %d %s to craft %dx %s.", required * amount, itemId, amount, outputId)
		end
	end
	for itemId, required in pairs(recipe.Inputs) do
		InventoryService.RemoveItem(profile, itemId, required * amount)
	end
	InventoryService.AddItem(profile, recipe.Output, recipe.Amount * amount)
	return true, string.format("Crafted %dx %s.", recipe.Amount * amount, outputId)
end

function CraftingService.GetRecipes()
	return Recipes
end

return CraftingService
