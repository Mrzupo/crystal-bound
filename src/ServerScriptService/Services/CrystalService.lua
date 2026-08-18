local CrystalSystem = require(game.ReplicatedStorage.Modules.CrystalSystem)
local CrystalService = {}

function CrystalService.GetOwnedCrystals(profile)
	if type(profile) ~= "table" or type(profile.Crystals) ~= "table" then return {} end
	return type(profile.Crystals.Owned) == "table" and profile.Crystals.Owned or {}
end

function CrystalService.OwnsCrystal(profile, id)
	return CrystalSystem.Owns(profile, id)
end

function CrystalService.UnlockCrystal(profile, id)
	return CrystalSystem.Unlock(profile, id)
end

function CrystalService.EquipCrystal(profile, id)
	return CrystalSystem.Equip(profile, id)
end

function CrystalService.GetEquippedCrystal(profile)
	return CrystalSystem.GetEquipped(profile)
end

return CrystalService
