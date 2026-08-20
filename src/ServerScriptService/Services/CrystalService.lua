local CrystalSystem = require(game.ReplicatedStorage.Modules.CrystalSystem)
local CrystalService = {}

function CrystalService.GetOwnedCrystals(profile)
	if type(profile) ~= "table" or type(profile.Crystals) ~= "table" or type(profile.Crystals.Owned) ~= "table" then return {} end
	local result = {}
	for _, crystalId in ipairs(profile.Crystals.Owned) do
		if CrystalSystem.Exists(crystalId) and not table.find(result, crystalId) then
			table.insert(result, crystalId)
		end
	end
	return result
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
