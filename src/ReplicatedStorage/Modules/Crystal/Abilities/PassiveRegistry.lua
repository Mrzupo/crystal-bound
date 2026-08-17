local Registry = {}

function Registry.Register(id, passive) Registry[id] = passive end
function Registry.Get(id) return Registry[id] end

return Registry
