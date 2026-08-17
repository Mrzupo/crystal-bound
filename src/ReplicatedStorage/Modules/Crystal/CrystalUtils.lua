local Definitions = require(script.Parent.CrystalDefinitions)
local CrystalUtils = {}

function CrystalUtils.Exists(id)
	return Definitions[id] ~= nil
end

function CrystalUtils.Get(id)
	return Definitions[id]
end

return CrystalUtils
