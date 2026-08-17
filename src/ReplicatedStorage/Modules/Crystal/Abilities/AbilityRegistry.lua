local Registry = {}
local abilities = {}

function Registry.Register(id, abilityClass) abilities[id] = abilityClass end
function Registry.Get(id) return abilities[id] end
function Registry.Clear() table.clear(abilities) end

return Registry
