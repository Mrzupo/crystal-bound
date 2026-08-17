local EnemyConfig = {
	DefaultHealth = 100,
	DefaultLevel = 1,
	Types = {
		TrainingDummy = {
			DisplayName = "Training Dummy",
			Health = 100,
			Level = 1,
			XP = 25,
			Money = 10,
			Respawn = 3,
			AggroRange = 0,
			AttackRange = 0,
			AttackDamage = 0,
			AttackCooldown = 0,
			Drop = nil,
		},
		Emberling = {
			DisplayName = "Emberling",
			Health = 160,
			Level = 3,
			XP = 50,
			Money = 18,
			Respawn = 5,
			AggroRange = 35,
			AttackRange = 5,
			AttackDamage = 8,
			AttackCooldown = 1.5,
			Drop = "EmberShard",
		},
		Tidecrawler = {
			DisplayName = "Tidecrawler",
			Health = 220,
			Level = 6,
			XP = 75,
			Money = 28,
			Respawn = 7,
			AggroRange = 40,
			AttackRange = 5,
			AttackDamage = 12,
			AttackCooldown = 1.7,
			Drop = "TidePearl",
		},
		Galewisp = {
			DisplayName = "Galewisp",
			Health = 300,
			Level = 10,
			XP = 100,
			Money = 40,
			Respawn = 9,
			AggroRange = 45,
			AttackRange = 7,
			AttackDamage = 16,
			AttackCooldown = 1.8,
			Drop = "GaleFeather",
		},
	},
}

function EnemyConfig.Get(typeId)
	return EnemyConfig.Types[typeId] or EnemyConfig.Types.TrainingDummy
end

return EnemyConfig
