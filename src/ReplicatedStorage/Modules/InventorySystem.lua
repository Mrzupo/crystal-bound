local InventorySystem = {}

function InventorySystem.Has(inventory, itemId, amount)
	return (inventory[itemId] or 0) >= (amount or 1)
end

return InventorySystem
