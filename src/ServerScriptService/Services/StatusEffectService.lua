local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DodgeService = require(script.Parent.DodgeService)
local DamageService = require(script.Parent.DamageService)
local DamageTypes = require(ReplicatedStorage.Modules.Combat.DamageTypes)
local MovementConfig = require(ReplicatedStorage.Config.MovementConfig)

local StatusEffectService = {}
local active = setmetatable({}, { __mode = "k" })

local function finiteNumber(value, fallback)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then
		return fallback
	end
	return number
end

local BASE_WALK_SPEED = math.max(1, finiteNumber(MovementConfig.BaseWalkSpeed, 16))
local MIN_WALK_SPEED = math.max(1, finiteNumber(MovementConfig.MinWalkSpeed, 6))
local MAX_WALK_SPEED_BONUS = math.clamp(finiteNumber(MovementConfig.MaxWalkSpeedBonus, 20), 0, 100)
local MIN_SLOW_MULTIPLIER = math.clamp(finiteNumber(MovementConfig.MinSlowMultiplier, 0.2), 0.01, 1)
local MAX_SLOW_MULTIPLIER = math.clamp(finiteNumber(MovementConfig.MaxSlowMultiplier, 1), MIN_SLOW_MULTIPLIER, 10)

local function isShuttingDown()
	return ReplicatedStorage:GetAttribute("CrystalBoundShuttingDown") == true
end

local function stateFor(humanoid)
	active[humanoid] = active[humanoid] or {}
	return active[humanoid]
end

local function getCurrentBaseWalkSpeed(humanoid, fallback)
	local character = humanoid and humanoid.Parent
	local player = character and Players:GetPlayerFromCharacter(character)
	if player then
		local bonus = math.clamp(math.max(0, finiteNumber(player:GetAttribute("WalkSpeedBonus"), 0)), 0, MAX_WALK_SPEED_BONUS)
		return BASE_WALK_SPEED + bonus
	end
	return fallback or humanoid.WalkSpeed
end

local function isPlayerDodging(humanoid)
	local character = humanoid and humanoid.Parent
	local player = character and Players:GetPlayerFromCharacter(character)
	return player ~= nil and DodgeService.IsInvulnerable(player)
end

local function clearState(humanoid, state)
	if not state then return end
	state.Slow = nil
	state.SlowMultiplier = nil
	state.Burn = nil
	humanoid:SetAttribute("CrystalBoundSlowMultiplier", nil)
	if humanoid.Parent and humanoid.Health > 0 and state.BaseWalkSpeed then
		humanoid.WalkSpeed = math.max(MIN_WALK_SPEED, getCurrentBaseWalkSpeed(humanoid, state.BaseWalkSpeed))
	end
	state.BaseWalkSpeed = nil
end

function StatusEffectService.GetSlowMultiplier(humanoid)
	if not humanoid then return nil end
	local state = active[humanoid]
	local slow = state and state.SlowMultiplier
	if slow == nil then return nil end
	return math.clamp(finiteNumber(slow, 1), MIN_SLOW_MULTIPLIER, MAX_SLOW_MULTIPLIER)
end

function StatusEffectService.ApplySlow(humanoid, multiplier, duration)
	if isShuttingDown() or not humanoid or humanoid.Health <= 0 or isPlayerDodging(humanoid) then return false end
	multiplier = math.clamp(finiteNumber(multiplier, 0.8), MIN_SLOW_MULTIPLIER, MAX_SLOW_MULTIPLIER)
	duration = math.clamp(finiteNumber(duration, 1), 0.1, 10)
	local state = stateFor(humanoid)
	local token = {}
	if not state.BaseWalkSpeed then state.BaseWalkSpeed = getCurrentBaseWalkSpeed(humanoid) end
	state.Slow = token
	state.SlowMultiplier = multiplier
	humanoid:SetAttribute("CrystalBoundSlowMultiplier", multiplier)
	humanoid.WalkSpeed = math.max(MIN_WALK_SPEED, state.BaseWalkSpeed * multiplier)
	task.delay(duration, function()
		if humanoid.Parent and state.Slow == token then
			humanoid:SetAttribute("CrystalBoundSlowMultiplier", nil)
			if not isShuttingDown() and humanoid.Health > 0 and state.BaseWalkSpeed then
				humanoid.WalkSpeed = math.max(MIN_WALK_SPEED, getCurrentBaseWalkSpeed(humanoid, state.BaseWalkSpeed))
			end
			state.Slow = nil
			state.SlowMultiplier = nil
			state.BaseWalkSpeed = nil
		end
	end)
	return true
end

function StatusEffectService.ApplyBurn(humanoid, damagePerTick, ticks, interval, attacker, range)
	if isShuttingDown() or not humanoid or humanoid.Health <= 0 or isPlayerDodging(humanoid) then return false end
	damagePerTick = math.clamp(finiteNumber(damagePerTick, 3), 1, 100)
	local normalizedTicks = finiteNumber(ticks, 3)
	if normalizedTicks == nil or normalizedTicks < 1 or normalizedTicks % 1 ~= 0 then return false end
	ticks = math.clamp(normalizedTicks, 1, 10)
	interval = math.clamp(finiteNumber(interval, 0.7), 0.2, 3)
	local state = stateFor(humanoid)
	local token = {}
	state.Burn = token
	task.spawn(function()
		for _ = 1, ticks do
			task.wait(interval)
			if isShuttingDown() or not humanoid.Parent or humanoid.Health <= 0 or state.Burn ~= token then break end
			local character = humanoid.Parent
			local player = character and Players:GetPlayerFromCharacter(character)
			if player then
				DodgeService.ApplyDamage(player, humanoid, damagePerTick, attacker, "Physical", range)
			else
				DamageService.ProcessDamage({
					Attacker = attacker,
					Target = character,
					Amount = damagePerTick,
					Range = range or 0,
					DamageType = attacker and DamageTypes.Physical or DamageTypes.Environmental,
				})
			end
		end
		if state.Burn == token then state.Burn = nil end
	end)
	return true
end

function StatusEffectService.Clear(humanoid)
	if not humanoid then return end
	local state = active[humanoid]
	if state then clearState(humanoid, state) end
	active[humanoid] = nil
end

return StatusEffectService