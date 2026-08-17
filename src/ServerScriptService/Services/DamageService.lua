local Validators = require(game.ReplicatedStorage.Modules.Combat.DamageValidators)
local DamageResult = require(game.ReplicatedStorage.Modules.Combat.DamageResult)
local DamageService = {}
function DamageService.ValidateRequest(request) return Validators.IsValid(request) end
function DamageService.CanDamage(request) return Validators.IsValid(request) and request.Attacker ~= request.Target end
function DamageService.ProcessDamage(request) if not DamageService.CanDamage(request) then return DamageResult.new(false, 0, "Invalid request") end; return DamageResult.new(true, request.Amount) end
function DamageService.ApplyDamage(request) return DamageService.ProcessDamage(request) end
return DamageService
