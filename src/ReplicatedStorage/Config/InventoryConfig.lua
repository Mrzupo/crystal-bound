local Items = {
	EmberShard = {
		Id = "EmberShard",
		Name = "Ember Shard",
		Type = "Material",
		MaxStackSize = 99,
	},
	TidePearl = {
		Id = "TidePearl",
		Name = "Tide Pearl",
		Type = "Material",
		MaxStackSize = 99,
	},
	GaleFeather = {
		Id = "GaleFeather",
		Name = "Gale Feather",
		Type = "Material",
		MaxStackSize = 99,
	},
}

local InventoryConfig = {
	DefaultMaxStackSize = 99,
	ItemTypes = { Material = "Material" },
	Items = Items,
}

function InventoryConfig.GetItemConfig(id)
	return Items[id]
end

function InventoryConfig.GetMaxStackSize(id)
	return (Items[id] and Items[id].MaxStackSize) or InventoryConfig.DefaultMaxStackSize
end

return InventoryConfig
