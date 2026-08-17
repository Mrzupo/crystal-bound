local Config = require(game.ReplicatedStorage.Config.EconomyConfig)
local EconomyService = {}
function EconomyService.AddMoney(profile, amount) profile.Money = math.clamp(profile.Money + amount, Config.MinMoney, Config.MaxMoney); return profile.Money end
function EconomyService.RemoveMoney(profile, amount) if profile.Money < amount then return false end; profile.Money -= amount; return true end
function EconomyService.GetMoney(profile) return profile.Money end
function EconomyService.CanAfford(profile, amount) return profile.Money >= amount end
return EconomyService
