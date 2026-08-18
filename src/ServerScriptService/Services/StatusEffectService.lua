local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DodgeService = require(script.Parent.DodgeService)
local DamageService = require(script.Parent.DamageService)
local DamageTypes = require(ReplicatedStorage.Modules.Combat.DamageTypes)
local MovementConfig = require(ReplicatedStorage.Config.MovementConfig)

local StatusEffectService = {}
local active = setmetatable({}, { __mode = "k" })

local BASE_WALK_SPEED = math.max(1, tonumber(MovementConfig.BaseWalkSpeed) or 16)
local MIN_WALK_SPEED = math.max(1, tonumber(MovementConfig.MinWalkSpeed) or 6)
local MIN_SLOW_MULTIPLIER = math.clamp(tonumber(MovementConfig.MinSlowMultiplier) or 0.2, 0.01, 1)
local MAX_SLOW_MULTIPLIER = math.clamp(tonumber(MovementConfig.MaxSlowMultiplier) or 1, MIN_SLOW_MULTIPLIER, 10)

local function stateFor(humanoid)
	active[humanoid] = active[humanoid] or {}
	return active[humanoid]
end

local function getCurrentBaseWalkSpeed(humanoid, fallback)
	local character = humanoid and humanoid.Parent
	local player = character and Players:GetPlayerFromCharacter(character)
	if player then
		return BASE_WALK_SPEED + math.max(0, tonumber(player:GetAttribute("WalkSpeedBonus")) or 0)
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
	state.Burn = nil
	humanoid:SetAttribute("CrystalBoundSlowMultiplier", nil)
	if humanoid.Parent and humanoid.Health > 0 and state.BaseWalkSpeed then
		humanoid.WalkSpeed = math.max(MIN_WALK_SPEED, getCurrentBaseWalkSpeed(humanoid, state.BaseWalkSpeed))
	end
	state.BaseWalkSpeed = nil
end

function StatusEffectService.ApplySlow(humanoid, multiplier, duration)
	if not humanoid or humanoid.Health <= 0 or isPlayerDodging(humanoid) then return false end
	multiplier = math.clamp(tonumber(multiplier) or 0.8, MIN_SLOW_MULTIPLIER, MAX_SLOW_MULTIPLIER)
	duration = math.clamp(tonumber(duration) or 1, 0.1, 10)
	local state = stateFor(humanoid)
	local token = {}
	if not state.BaseWalkSpeed then state.BaseWalkSpeed = getCurrentBaseWalkSpeed(humanoid) end
	state.Slow = token
	humanoid:SetAttribute("CrystalBoundSlowMultiplier", multiplier)
	humanoid.WalkSpeed = math.max(MIN_WALK_SPEED, state.BaseWalkSpeed * multiplier)
	task.delay(duration, function()
		if humanoid.Parent and humanoid.Health > 0 and state.Slow == token then
			humanoid:SetAttribute("CrystalBoundSlowMultiplier", nil)
			humanoid.WalkSpeed = math.max(MIN_WALK_SPEED, getCurrentBaseWalkSpeed(humanoid, state.BaseWalkSpeed))
			state.Slow = nil
			state.BaseWalkSpeed = nil
		end
	end)
	return true
end

function StatusEffectService.ApplyBurn(humanoid, damagePerTick, ticks, interval, attacker, range)
	if not humanoid or humanoid.Health <= 0 or isPlayerDodging(humanoid) then return false end
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
