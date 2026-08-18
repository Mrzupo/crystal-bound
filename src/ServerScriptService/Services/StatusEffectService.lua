local Players = game:GetService("Players")
local DodgeService = require(script.Parent.DodgeService)

local StatusEffectService = {}
local active = setmetatable({}, { __mode = "k" })

local function stateFor(humanoid)
	active[humanoid] = active[humanoid] or {}
	return active[humanoid]
end

local function getCurrentBaseWalkSpeed(humanoid, fallback)
	local character = humanoid and humanoid.Parent
	local player = character and Players:GetPlayerFromCharacter(character)
	if player then
		return 16 + math.max(0, tonumber(player:GetAttribute("WalkSpeedBonus")) or 0)
	end
	return fallback or humanoid.WalkSpeed
end

local function getPlayer(humanoid)
	local character = humanoid and humanoid.Parent
	return character and Players:GetPlayerFromCharacter(character)
end

function StatusEffectService.ApplySlow(humanoid, multiplier, duration)
	if not humanoid or humanoid.Health <= 0 then return false end
	local player = getPlayer(humanoid)
	if player and DodgeService.IsInvulnerable(player) then return false end
	multiplier = math.clamp(tonumber(multiplier) or 0.8, 0.2, 1)
	duration = math.clamp(tonumber(duration) or 1, 0.1, 10)
	local state = stateFor(humanoid)
	local token = {}
	if not state.BaseWalkSpeed then state.BaseWalkSpeed = getCurrentBaseWalkSpeed(humanoid) end
	state.Slow = token
	humanoid:SetAttribute("CrystalBoundSlowMultiplier", multiplier)
	humanoid.WalkSpeed = math.max(6, state.BaseWalkSpeed * multiplier)
	task.delay(duration, function()
		if humanoid.Parent and humanoid.Health > 0 and state.Slow == token then
			humanoid:SetAttribute("CrystalBoundSlowMultiplier", nil)
			humanoid.WalkSpeed = getCurrentBaseWalkSpeed(humanoid, state.BaseWalkSpeed)
			state.Slow = nil
			state.BaseWalkSpeed = nil
		end
	end)
	return true
end

function StatusEffectService.ApplyBurn(humanoid, damagePerTick, ticks, interval)
	if not humanoid or humanoid.Health <= 0 then return false end
	local player = getPlayer(humanoid)
	if player and DodgeService.IsInvulnerable(player) then return false end
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
			local character = humanoid.Parent
			local player = character and Players:GetPlayerFromCharacter(character)
			if player then
				DodgeService.ApplyDamage(player, humanoid, damagePerTick)
			else
				humanoid:TakeDamage(damagePerTick)
			end
		end
		if state.Burn == token then state.Burn = nil end
	end)
	return true
end

function StatusEffectService.Clear(humanoid)
	if not humanoid then return end
	local state = active[humanoid]
	if state then
		humanoid:SetAttribute("CrystalBoundSlowMultiplier", nil)
		if humanoid.Parent and humanoid.Health > 0 and state.Slow and state.BaseWalkSpeed then
			humanoid.WalkSpeed = getCurrentBaseWalkSpeed(humanoid, state.BaseWalkSpeed)
		end
	end
	active[humanoid] = nil
end

return StatusEffectService