local CrystalSystem = require(game.ReplicatedStorage.Modules.CrystalSystem)
local CrystalService = {}
function CrystalService.GetOwnedCrystals(profile) return profile.Crystals.Owned end
function CrystalService.OwnsCrystal(profile, id) return CrystalSystem.Owns(profile, id) end
function CrystalService.UnlockCrystal(profile, id) return CrystalSystem.Unlock(profile, id) end
function CrystalService.EquipCrystal(profile, id) return CrystalSystem.Equip(profile, id) end
function CrystalService.GetEquippedCrystal(profile) return profile.Crystals.Equipped end
return CrystalService
