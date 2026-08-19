local CrystalConfig = require(game.ReplicatedStorage.Config.CrystalConfig)

local CrystalSystem = {}

local function finiteNumber(value)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return nil end
	return number
end

local function validProfileCrystals(profile)
	return type(profile) == "table" and type(profile.Crystals) == "table"
end

function CrystalSystem.Exists(id)
	return type(id) == "string" and CrystalConfig.UnlockLevels[id] ~= nil
end

function CrystalSystem.GetDefinition(id)
	if not CrystalSystem.Exists(id) then return nil end
	return CrystalConfig.Definitions[id]
end

function CrystalSystem.GetBasicAttack(id)
	if not CrystalSystem.Exists(id) then return nil end
	return CrystalConfig.BasicAttack[id]
end

function CrystalSystem.GetAbility(id)
	if not CrystalSystem.Exists(id) then return nil end
	return CrystalConfig.Abilities[id]
end

function CrystalSystem.GetPassive(id)
	if not CrystalSystem.Exists(id) then return {} end
	return CrystalConfig.Passives[id] or {}
end

function CrystalSystem.Owns(profile, id)
	if not CrystalSystem.Exists(id) or not validProfileCrystals(profile) then return false end
	return type(profile.Crystals.Owned) == "table" and table.find(profile.Crystals.Owned, id) ~= nil
end

function CrystalSystem.Unlock(profile, id)
	if not CrystalSystem.Exists(id) or not validProfileCrystals(profile) or CrystalSystem.Owns(profile, id) then return false end
	local requiredRaw = finiteNumber(CrystalConfig.UnlockLevels[id])
	if not requiredRaw or requiredRaw < 1 then return false end
	local requiredLevel = math.floor(requiredRaw)
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
