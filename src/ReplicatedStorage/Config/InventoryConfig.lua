local Items = {}
local InventoryConfig = { DefaultMaxStackSize = 99, ItemTypes = {}, Items = Items }
function InventoryConfig.GetItemConfig(id) return Items[id] end
function InventoryConfig.GetMaxStackSize(id) return (Items[id] and Items[id].MaxStackSize) or InventoryConfig.DefaultMaxStackSize end
return InventoryConfig
