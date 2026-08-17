local Items = {
	EmberShard = {
		Id = "EmberShard",
		Name = "Ember Shard",
		Type = "Material",
		MaxStackSize = 99,
		SellPrice = 8,
	},
	TidePearl = {
		Id = "TidePearl",
		Name = "Tide Pearl",
		Type = "Material",
		MaxStackSize = 99,
		SellPrice = 14,
	},
	GaleFeather = {
		Id = "GaleFeather",
		Name = "Gale Feather",
		Type = "Material",
		MaxStackSize = 99,
		SellPrice = 22,
	},
	GuardianCore = {
		Id = "GuardianCore",
		Name = "Guardian Core",
		Type = "BossMaterial",
		MaxStackSize = 10,
		SellPrice = 250,
	},
}

local InventoryConfig = {
	DefaultMaxStackSize = 99,
	ItemTypes = { Material = "Material", BossMaterial = "BossMaterial" },
	Items = Items,
}

function InventoryConfig.GetItemConfig(id)
	return Items[id]
end

function InventoryConfig.GetMaxStackSize(id)
	return (Items[id] and Items[id].MaxStackSize) or InventoryConfig.DefaultMaxStackSize
end

return InventoryConfig
