local EnemyConfig = {
	DefaultHealth = 100,
	DefaultLevel = 1,
	Types = {
		TrainingDummy = { DisplayName = "Training Dummy", Health = 100, Level = 1, XP = 25, Money = 10, Respawn = 3, AggroRange = 0, AttackRange = 0, AttackDamage = 0, AttackCooldown = 0, Drop = nil, DropChance = 0 },
		Emberling = { DisplayName = "Emberling", Health = 160, Level = 3, XP = 50, Money = 18, Respawn = 5, AggroRange = 35, AttackRange = 5, AttackDamage = 8, AttackCooldown = 1.5, Special = { Cooldown = 6, Range = 14, BonusDamage = 6, BurnDamage = 2, BurnTicks = 3, BurnInterval = 0.6 }, Drop = "EmberShard", DropChance = 0.85 },
		Tidecrawler = { DisplayName = "Tidecrawler", Health = 220, Level = 6, XP = 75, Money = 28, Respawn = 7, AggroRange = 40, AttackRange = 5, AttackDamage = 12, AttackCooldown = 1.7, Special = { Cooldown = 6, Range = 10, BonusDamage = 3, SlowMultiplier = 0.65, SlowDuration = 1.5 }, Drop = "TidePearl", DropChance = 0.8 },
		Galewisp = { DisplayName = "Galewisp", Health = 300, Level = 10, XP = 100, Money = 40, Respawn = 9, AggroRange = 45, AttackRange = 7, AttackDamage = 16, AttackCooldown = 1.8, Special = { Cooldown = 6, Range = 18, BonusDamage = 8, TeleportOffset = 4 }, Drop = "GaleFeather", DropChance = 0.72 },
		CrystalBat = { DisplayName = "Crystal Bat", Health = 380, Level = 15, XP = 145, Money = 55, Respawn = 10, AggroRange = 50, AttackRange = 7, AttackDamage = 20, AttackCooldown = 1.5, Special = { Cooldown = 6, Range = 12, BonusDamage = 5 }, Drop = "AncientShard", DropChance = 0.7 },
		AncientGolem = { DisplayName = "Ancient Golem", Health = 650, Level = 18, XP = 260, Money = 90, Respawn = 16, AggroRange = 55, AttackRange = 8, AttackDamage = 28, AttackCooldown = 2.0, Special = { Cooldown = 6, Range = 10, BonusDamage = 10, Radius = 10 }, Drop = "AncientShard", DropChance = 0.95 },
	}
}

local function finiteNumber(value, fallback)
	local number = tonumber(value)
	if type(number) ~= "number" or number ~= number or number == math.huge or number == -math.huge then return fallback end
	return number
end

local function clone(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = clone(child) end
	return result
end

function EnemyConfig.Get(typeId)
	if type(typeId) ~= "string" then return nil end
	local source = EnemyConfig.Types[typeId]
	if type(source) ~= "table" then return nil end
	local result = clone(source)
	result.Health = math.clamp(finiteNumber(source.Health, EnemyConfig.DefaultHealth), 1, 1000000)
	result.Level = math.clamp(math.floor(finiteNumber(source.Level, EnemyConfig.DefaultLevel)), 1, 100)
	result.XP = math.clamp(math.floor(finiteNumber(source.XP, 0)), 0, 1000000)
	result.Money = math.clamp(math.floor(finiteNumber(source.Money, 0)), 0, 1000000)
	result.Respawn = math.clamp(finiteNumber(source.Respawn, 10), 1.5, 600)
	result.AggroRange = math.clamp(finiteNumber(source.AggroRange, 0), 0, 1000)
	result.AttackRange = math.clamp(finiteNumber(source.AttackRange, 0), 0, 1000)
	result.AttackDamage = math.clamp(finiteNumber(source.AttackDamage, 0), 0, 1000)
	result.AttackCooldown = math.clamp(finiteNumber(source.AttackCooldown, 1), 0.25, 60)
	result.DropChance = math.clamp(finiteNumber(source.DropChance, 0), 0, 1)
	if type(result.Special) == "table" then
		result.Special.Cooldown = math.clamp(finiteNumber(result.Special.Cooldown, 6), 0.25, 60)
		result.Special.Range = math.clamp(finiteNumber(result.Special.Range, 0), 0, 1000)
		result.Special.BonusDamage = math.clamp(finiteNumber(result.Special.BonusDamage, 0), 0, 1000)
		if result.Special.BurnDamage ~= nil then result.Special.BurnDamage = math.clamp(finiteNumber(result.Special.BurnDamage, 3), 1, 100) end
		if result.Special.BurnTicks ~= nil then result.Special.BurnTicks = math.clamp(math.floor(finiteNumber(result.Special.BurnTicks, 3)), 1, 10) end
		if result.Special.BurnInterval ~= nil then result.Special.BurnInterval = math.clamp(finiteNumber(result.Special.BurnInterval, 0.7), 0.2, 3) end
		if result.Special.SlowMultiplier ~= nil then result.Special.SlowMultiplier = math.clamp(finiteNumber(result.Special.SlowMultiplier, 0.8), 0.01, 1) end
		if result.Special.SlowDuration ~= nil then result.Special.SlowDuration = math.clamp(finiteNumber(result.Special.SlowDuration, 1), 0.1, 10) end
		if result.Special.TeleportOffset ~= nil then result.Special.TeleportOffset = math.clamp(finiteNumber(result.Special.TeleportOffset, 4), 0, 100) end
		if result.Special.Radius ~= nil then result.Special.Radius = math.clamp(finiteNumber(result.Special.Radius, 10), 0, 1000) end
	end
	return result
end

function EnemyConfig.IsValid(typeId)
	return type(typeId) == "string" and EnemyConfig.Types[typeId] ~= nil
end

return EnemyConfig
