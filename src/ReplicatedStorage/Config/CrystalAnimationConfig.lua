-- Presentation-only configuration.
-- AssetName values resolve authored Roblox objects under ReplicatedStorage.Assets.
-- AnimationId/SoundId remain optional fallbacks until real assets are published.
-- Never place gameplay authority, damage, hit timing, or cooldown decisions here.
return {
	EMBER = {
		Basic = {
			AssetName = "EMBER_Basic",
			AnimationId = "",
			PlaybackSpeed = 1.0,
			FadeTime = 0.08,
			VFXScale = 0.38,
			VFXOffset = 3.0,
			SoundAssetName = "EMBER_Basic",
			SoundId = "",
			SoundVolume = 0.45,
		},
		Ability = {
			AssetName = "EMBER_FlameBurst",
			AnimationId = "",
			PlaybackSpeed = 1.0,
			FadeTime = 0.06,
			VFXScale = 0.70,
			VFXOffset = 4.5,
			SoundAssetName = "EMBER_FlameBurst",
			SoundId = "",
			SoundVolume = 0.60,
		},
	},
	TIDE = {
		Basic = {
			AssetName = "TIDE_Basic",
			AnimationId = "",
			PlaybackSpeed = 1.0,
			FadeTime = 0.08,
			VFXScale = 0.38,
			VFXOffset = 3.0,
			SoundAssetName = "TIDE_Basic",
			SoundId = "",
			SoundVolume = 0.45,
		},
		Ability = {
			AssetName = "TIDE_TidalPulse",
			AnimationId = "",
			PlaybackSpeed = 1.0,
			FadeTime = 0.06,
			VFXScale = 0.70,
			VFXOffset = 4.5,
			SoundAssetName = "TIDE_TidalPulse",
			SoundId = "",
			SoundVolume = 0.60,
		},
	},
	GALE = {
		Basic = {
			AssetName = "GALE_Basic",
			AnimationId = "",
			PlaybackSpeed = 1.05,
			FadeTime = 0.08,
			VFXScale = 0.38,
			VFXOffset = 3.0,
			SoundAssetName = "GALE_Basic",
			SoundId = "",
			SoundVolume = 0.45,
		},
		Ability = {
			AssetName = "GALE_GaleStrike",
			AnimationId = "",
			PlaybackSpeed = 1.0,
			FadeTime = 0.06,
			VFXScale = 0.70,
			VFXOffset = 4.5,
			SoundAssetName = "GALE_GaleStrike",
			SoundId = "",
			SoundVolume = 0.60,
		},
	},
}
