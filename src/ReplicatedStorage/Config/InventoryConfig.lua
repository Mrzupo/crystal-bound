local Items = {
	EmberShard = { Id = "EmberShard", Name = "Ember Shard", Type = "Material", Rarity = "Common", MaxStackSize = 99, SellPrice = 8 },
	TidePearl = { Id = "TidePearl", Name = "Tide Pearl", Type = "Material", Rarity = "Uncommon", MaxStackSize = 99, SellPrice = 14 },
	GaleFeather = { Id = "GaleFeather", Name = "Gale Feather", Type = "Material", Rarity = "Rare", MaxStackSize = 99, SellPrice = 22 },
	GuardianCore = { Id = "GuardianCore", Name = "Guardian Core", Type = "BossMaterial", Rarity = "Legendary", MaxStackSize = 10, SellPrice = 250 },
	AncientShard = { Id = "AncientShard", Name = "Ancient Shard", Type = "Material", Rarity = "Epic", MaxStackSize = 99, SellPrice = 35 },
	HealthPotion = { Id = "HealthPotion", Name = "Health Potion", Type = "Consumable", Rarity = "Uncommon", MaxStackSize = 20, SellPrice = 0 },
}

local InventoryConfig = {
	DefaultMaxStackSize = 99,
	ItemTypes = { Material = "Material", BossMaterial = "BossMaterial", Consumable = "Consumable" },
	Rarities = {
		Common = 1,
		Uncommon = 2,
		Rare = 3,
		Epic = 4,
		Legendary = 5,
		Mythic = 6,
		Divine = 7,
	},
	Items = Items,
}

local function copyItem(item)
	if type(item) ~= "table" then return nil end
	local result = {}
	for key, value in pairs(item) do result[key] = value end
	return result
end

function InventoryConfig.GetItemConfig(id) return copyItem(Items[id]) end
function InventoryConfig.GetMaxStackSize(id) return (Items[id] and Items[id].MaxStackSize) or InventoryConfig.DefaultMaxStackSize end
return InventoryConfig
