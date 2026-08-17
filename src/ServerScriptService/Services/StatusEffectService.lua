local Debris = game:GetService("Debris")

local StatusEffectService = {}
local active = setmetatable({}, { __mode = "k" })

local function stateFor(humanoid)
	active[humanoid] = active[humanoid] or {}
	return active[humanoid]
end

function StatusEffectService.ApplySlow(humanoid, multiplier, duration)
	if not humanoid or humanoid.Health <= 0 then return false end
	multiplier = math.clamp(tonumber(multiplier) or 0.8, 0.2, 1)
	duration = math.clamp(tonumber(duration) or 1, 0.1, 10)
	local state = stateFor(humanoid)
	local token = {}
	state.Slow = token
	local baseSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = math.max(6, baseSpeed * multiplier)
	task.delay(duration, function()
		if humanoid.Parent and humanoid.Health > 0 and state.Slow == token then
			humanoid.WalkSpeed = baseSpeed
			state.Slow = nil
		end
	end)
	return true
end

function StatusEffectService.ApplyBurn(humanoid, damagePerTick, ticks, interval)
	if not humanoid or humanoid.Health <= 0 then return false end
	damagePerTick = math.clamp(tonumber(damagePerTick) or 3, 1, 100)
	ticks = math.clamp(math.floor(tonumber(ticks) or 3), 1, 10)
	interval = math.clamp(tonumber(interval) or 0.7, 0.2, 3)
	local state = stateFor(humanoid)
	local token = {}
	state.Burn = token
	task.spawn(function()
		for _ = 1, ticks do
			task.wait(interval)
			if not humanoid.Parent or humanoid.Health <= 0 or state.Burn ~= token then break end
			humanoid:TakeDamage(damagePerTick)
		end
		if state.Burn == token then state.Burn = nil end
	end)
	return true
end

function StatusEffectService.Clear(humanoid)
	active[humanoid] = nil
end

return StatusEffectService
