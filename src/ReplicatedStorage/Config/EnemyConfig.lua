local EnemyConfig = {
	DefaultHealth = 100,
	DefaultLevel = 1,
	Types = {
		TrainingDummy = { DisplayName = "Training Dummy", Health = 100, Level = 1, XP = 25, Money = 10, Respawn = 3, AggroRange = 0, AttackRange = 0, AttackDamage = 0, AttackCooldown = 0, Drop = nil, DropChance = 0 },
		Emberling = { DisplayName = "Emberling", Health = 160, Level = 3, XP = 50, Money = 18, Respawn = 5, AggroRange = 35, AttackRange = 5, AttackDamage = 8, AttackCooldown = 1.5, Drop = "EmberShard", DropChance = 0.85 },
		Tidecrawler = { DisplayName = "Tidecrawler", Health = 220, Level = 6, XP = 75, Money = 28, Respawn = 7, AggroRange = 40, AttackRange = 5, AttackDamage = 12, AttackCooldown = 1.7, Drop = "TidePearl", DropChance = 0.8 },
		Galewisp = { DisplayName = "Galewisp", Health = 300, Level = 10, XP = 100, Money = 40, Respawn = 9, AggroRange = 45, AttackRange = 7, AttackDamage = 16, AttackCooldown = 1.8, Drop = "GaleFeather", DropChance = 0.72 },
		CrystalBat = { DisplayName = "Crystal Bat", Health = 380, Level = 15, XP = 145, Money = 55, Respawn = 10, AggroRange = 50, AttackRange = 7, AttackDamage = 20, AttackCooldown = 1.5, Drop = "AncientShard", DropChance = 0.7 },
		AncientGolem = { DisplayName = "Ancient Golem", Health = 650, Level = 18, XP = 260, Money = 90, Respawn = 16, AggroRange = 55, AttackRange = 8, AttackDamage = 28, AttackCooldown = 2.0, Drop = "AncientShard", DropChance = 0.95 },
	}
}

function EnemyConfig.Get(typeId)
	return EnemyConfig.Types[typeId] or EnemyConfig.Types.TrainingDummy
end

return EnemyConfig
