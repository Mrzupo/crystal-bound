local CrystalConfig = require(game.ReplicatedStorage.Config.CrystalConfig)

local CrystalSystem = {}

local function finiteNumber(value)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return nil end
	return number
end

local function validUnlockLevel(id)
	local raw = finiteNumber(CrystalConfig.UnlockLevels[id])
	if raw == nil or raw < 1 or raw % 1 ~= 0 then return nil end
	return math.floor(raw)
end

local function hasDefinition(id)
	return type(CrystalConfig.Definitions) == "table" and type(CrystalConfig.Definitions[id]) == "table"
end

local function hasCombatConfig(id)
	return type(CrystalConfig.BasicAttack) == "table"
		and type(CrystalConfig.BasicAttack[id]) == "table"
		and type(CrystalConfig.Abilities) == "table"
		and type(CrystalConfig.Abilities[id]) == "table"
		and type(CrystalConfig.Passives) == "table"
		and type(CrystalConfig.Passives[id]) == "table"
end

local function copyTable(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = type(child) == "table" and copyTable(child) or child end
	return result
end

local function validProfileCrystals(profile)
	return type(profile) == "table" and type(profile.Crystals) == "table"
end

function CrystalSystem.Exists(id)
	return type(id) == "string" and validUnlockLevel(id) ~= nil and hasDefinition(id) and hasCombatConfig(id)
end

function CrystalSystem.GetDefinition(id)
	if not CrystalSystem.Exists(id) then return nil end
	return copyTable(CrystalConfig.Definitions[id])
end

function CrystalSystem.GetBasicAttack(id)
	if not CrystalSystem.Exists(id) then return nil end
	return copyTable(CrystalConfig.BasicAttack[id])
end

function CrystalSystem.GetAbility(id)
	if not CrystalSystem.Exists(id) then return nil end
	return copyTable(CrystalConfig.Abilities[id])
end

function CrystalSystem.GetPassive(id)
	if not CrystalSystem.Exists(id) then return {} end
	return copyTable(CrystalConfig.Passives[id] or {})
end

function CrystalSystem.Owns(profile, id)
	if not CrystalSystem.Exists(id) or not validProfileCrystals(profile) then return false end
	return type(profile.Crystals.Owned) == "table" and table.find(profile.Crystals.Owned, id) ~= nil
end

function CrystalSystem.Unlock(profile, id)
	if not CrystalSystem.Exists(id) or not validProfileCrystals(profile) or CrystalSystem.Owns(profile, id) then return false end
	local requiredLevel = validUnlockLevel(id)
	if not requiredLevel then return false end
	local playerLevel = math.max(1, math.floor(finiteNumber(profile.Level) or 1))
	if playerLevel < requiredLevel then return false end
	if type(profile.Crystals.Owned) ~= "table" then profile.Crystals.Owned = {} end
	table.insert(profile.Crystals.Owned, id)
	return true
end

function CrystalSystem.Equip(profile, id)
	if not CrystalSystem.Owns(profile, id) then return false end
	profile.Crystals.Equipped = id
	return true
end

function CrystalSystem.GetEquipped(profile)
	if not validProfileCrystals(profile) then return nil end
	local equipped = profile.Crystals.Equipped
	return CrystalSystem.Exists(equipped) and equipped or nil
end

return CrystalSystem
