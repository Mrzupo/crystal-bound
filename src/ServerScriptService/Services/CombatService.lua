local DamageService = require(script.Parent.DamageService)
local CombatService = {}
function CombatService.HandleRequest(request) return DamageService.ProcessDamage(request) end
return CombatService
