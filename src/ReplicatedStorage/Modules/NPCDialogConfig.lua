local NPCDialogConfig = {
	CrystalKeeper = {
		Name = "Crystal Keeper",
		Lines = {
			"The crystals choose their wielders. Keep training and the next island will open.",
			"Ember rewards aggression. Tide rewards patience. Gale rewards movement.",
			"The Guardian protects the path to the Ancient Ruins.",
		},
		Options = {
			{ Id = "QUEST", Label = "Open Quests" },
			{ Id = "CRYSTAL", Label = "Open Crystals" },
		},
	},
	MaterialTrader = {
		Name = "Material Trader",
		Lines = {
			"Bring me crystals, pearls, feathers and ancient shards and I will pay you.",
			"Guardian Cores are rare. Save them for important upgrades.",
			"Health Potions are useful before a long fight.",
		},
		Options = {
			{ Id = "SHOP", Label = "Open Shop" },
			{ Id = "INVENTORY", Label = "Open Inventory" },
			{ Id = "CRAFT", Label = "Open Crafting" },
		},
	},
}

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do
		result[key] = copy(child)
	end
	return result
end

function NPCDialogConfig.Get(npcId)
	return copy(NPCDialogConfig[npcId])
end

return NPCDialogConfig
