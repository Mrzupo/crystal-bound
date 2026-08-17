local Definitions = require(script.Parent.Crystal.CrystalDefinitions)
local CrystalSystem = {}

function CrystalSystem.Exists(id) return Definitions[id] ~= nil end
function CrystalSystem.GetDefinition(id) return Definitions[id] end
function CrystalSystem.Owns(profile, id) return table.find(profile.Crystals.Owned, id) ~= nil end
function CrystalSystem.Unlock(profile, id)
	if not CrystalSystem.Exists(id) or CrystalSystem.Owns(profile, id) then return false end
	table.insert(profile.Crystals.Owned, id)
	return true
end
function CrystalSystem.Equip(profile, id)
	if not CrystalSystem.Owns(profile, id) then return false end
	profile.Crystals.Equipped = id
	return true
end

return CrystalSystem
