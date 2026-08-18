return {
	UnlockLevels = {
		EMBER = 1,
		TIDE = 3,
		GALE = 5,
	},
	BasicAttack = {
		EMBER = { Damage = 14, Range = 16, Cooldown = 0.55 },
		TIDE = { Damage = 12, Range = 17, Cooldown = 0.65 },
		GALE = { Damage = 11, Range = 20, Cooldown = 0.45 },
	},
	Abilities = {
		EMBER = { Name = "Flame Burst", Damage = 28, Range = 22, Cooldown = 4 },
		TIDE = { Name = "Tidal Pulse", Damage = 22, Range = 18, Cooldown = 4 },
		GALE = { Name = "Gale Strike", Damage = 24, Range = 24, Cooldown = 3 },
	},
	Passives = {
		EMBER = { DamageMultiplier = 1.15, WalkSpeedBonus = 0, MaxHealthBonus = 0 },
		TIDE = { DamageMultiplier = 1.0, WalkSpeedBonus = 0, MaxHealthBonus = 25 },
		GALE = { DamageMultiplier = 1.0, WalkSpeedBonus = 4, MaxHealthBonus = 0 },
	},
}
