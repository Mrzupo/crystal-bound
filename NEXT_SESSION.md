# Crystal Bound — Session Handoff

## Branch
- Branch: `agent/complete-crystal-bound-foundation`
- Base: `main`
- Current compare: **1110 commits ahead, 29 commits behind** `main` (verified with GitHub compare).
- `main` is restored to verified baseline commit `b4877299d51a083f1bf5adfdf1fc152c6a5c1d17`.

## Current state
The branch contains the complete Rojo project foundation plus the current gameplay stack. The repository is in a **hardening + integration + combat presentation** phase, moving toward Roblox Studio runtime verification.

Authoritative design context remains intact: PvE-first open-world action RPG; White Queen intro; first-loss setup; Ancient Crystal lore; Ancient as category, not rarity; Common → Divine rarity ladder; multiple-world long-term mystery; no-Codex working mode.

## Major verified systems
- Server-authoritative `CombatService` + `DamageService`.
- Canonical `CrystalConfig` + `CrystalSystem` + `CrystalMastery`.
- TIDE/GALE level gates enforced inside `CrystalSystem.Unlock()` as well as request-layer checks.
- Central QuestSystem / QuestService completion and rewards.
- SafeProfileStore session lock, refresh heartbeat, save snapshots, retries and corrupted-value protection.
- Economy, Inventory, Shop, Crafting and Consumables with validation, rate limits and rollback.
- Crystal Mastery upgrade transactions verify each material removal and roll back partial consumption or failed upgrades.
- Enemy AI, Pathfinding, status effects and lifecycle cleanup.
- Guardian phase system, arena hazard and exact-instance-bound telegraphs.
- Daily Bounty canonicalized from config even for existing same-day profiles.
- Achievement Titles derived from earned Achievement IDs.
- PC/Mobile controls and UI.
- Server-confirmed CombatFeedback presentation.
- Server-owned character Animator for client animation playback.
- One-shot confirmed Crystal VFX bridge.
- Server-enforced WalkSpeed baseline and Slow modifiers, with immediate correction of server-observed speed changes and stale-respawn listener protection.

## Latest hardening work
- Damage input boundaries reject non-positive, non-finite and oversized values at the canonical validator, including attacker range.
- Combat request config is runtime-bounded for Damage/Range/Cooldown; malformed enemy XP/Money no longer marks a defeat as rewarded.
- Shop and Crafting request quantities are strict positive integers; fractional requests are rejected instead of floored.
- Crafting input/output multiplication is finite/integer-bounded before material mutation.
- Unknown EnemyConfig IDs no longer fall back to TrainingDummy; NPC runtime boundaries reject them cleanly.
- Enemy XP/Money/Loot rewards use canonical `EnemyConfig`; no Crystal-based fallback rewards.
- Combat defeat rewards have explicit `DeathRewarded` idempotency.
- NPC special attacks clamp runtime ranges/cooldowns and Gale teleport offsets to bounded values.
- Enemy special-effect config contracts cover BonusDamage, BurnDamage/BurnTicks/BurnInterval and SlowMultiplier/SlowDuration.
- Enemy AI startup is idempotent via an `AIStarted` model guard, preventing duplicate attack/movement loops.
- Inventory corrupt stacks are clamped before mutation.
- Quest progress rejects invalid/non-finite/non-integer increments.
- CrystalSystem, PlayerData and CrystalMastery accept only complete Crystal configurations with finite integer UnlockLevels plus Definition/BasicAttack/Ability/Passive data.
- Crystal mastery persistence drops malformed/incomplete Crystal IDs and falls back Equipped state to the first valid owned Crystal.
- Crystal mastery growth and bonus configuration are finite-safe and bounded for damage, ability damage, health, movement speed and XP growth.
- Daily Bounty payout has one server owner and marks the bounty claimed before payout; Bounty goals must map to canonical EnemyConfig entries.
- Achievement payout has one server owner and only pays newly unlocked achievements.
- Guardian phase-2 multipliers, attack values, shockwave radius/damage, ArenaHazard interval and telegraph values are runtime-bounded and backed by semantic contracts.
- Guardian telegraph binds to the exact Guardian instance.
- NPC Burn/Slow only apply after confirmed damage.
- NPCMenuBridge validates server-side interaction distance before opening NPC menus.
- PlayerService Save/Remove guarantees operation-lock release and preserves persistent locks after failed final saves/releases.
- SessionHeartbeat kicks after two consecutive Refresh failures to protect the save-session lock.
- `StatusSpeedGuardV2` continuously restores server-derived WalkSpeed, immediately corrects property changes, and prevents stale Character listeners across respawns.
- `PositionCheckInterval` is actually honored by movement authority rather than masked by a hardcoded interval.
- DodgeService explicitly disconnects CharacterAdded listeners on leave/rebind, bounds cooldown/boost/invulnerability/direction inputs and retains weak player state.
- Bootstrap and major server Remote entrypoints fail fast on mismatched Remote classes instead of silently binding the wrong type.
- Remote type contracts cover Bootstrap, CombatFeedback, Shop, Crafting, Dodge, Consumables, NPCDialog and AvailableQuests entrypoints.
- RemoteFunction contracts enforce single ownership, request-rate guards and non-internal data snapshots.
- Portal contracts verify canonical `WorldConfig` gates, server destination arrival and lifecycle cleanup.
- WorldInit contract verifies canonical four-island IDs, bounded level/size config and WorldTheme portal ownership.
- Inventory contract validates item type/rariy/stack/sell-price semantics.
- Shop/Crafting contracts validate canonical inventory IDs and economy limits.
- XPConfig.GetRequiredXP now clamps level/growth/required-XP math.
- Workflow path self-check validates referenced repository files exist.
- Studio playtest matrix covers transaction, persistence, movement-security, Crystal configuration, NPC interaction, reward-idempotency and Remote-type cases.

## Security / authority rules
- `DamageService` is the only direct `Humanoid:TakeDamage()` path in `src`.
- Known DamageTypes only.
- Positive finite damage and bounded range only.
- PvP damage blocked in current PvE-first combat path.
- Client cannot authoritatively grant Crystals, items, Money, XP, damage or quest completion.
- Server derives and enforces WalkSpeed; local movement presentation cannot become authoritative speed.
- Animation/VFX never decide gameplay.
- Critical RemoteFunctions have single `OnServerInvoke` ownership.
- Important Remotes are rate-limited and per-player cleanup is contract-checked.

## Open decisions / limitations
- No actual Roblox Studio runtime playtest has been executed here.
- No Luau interpreter is available in this environment.
- Latest Combined Status is not verified through the available GitHub connector; recent status queries return no status objects.
- Authored Roblox Animation/Sound assets are still missing.
- Current VFX remain procedural/placeholder-level.
- TIDE/GALE currently use level-gated prototype unlocks, while the master design lists Mining, Digging, Bosses, Dungeons, World Events and Quests as long-term Crystal acquisition activities. Decide the final model before building acquisition content.
- Story remains fixed: White Queen, first loss, unknown world, Ancient Crystal lore, multiple future worlds and delayed second-world reveal.
- Conservative server movement-position anti-teleport foundations are present, but thresholding and interaction with Roblox network ownership/physics still require real Studio multiplayer validation before calling exploit-resistance complete.

## Next steps
1. Continue concrete static audits where risk remains.
2. Move toward Roblox Studio runtime validation.
3. Add authored EMBER Basic + Flame Burst animation/VFX/audio assets first.
4. Repeat the asset contract for TIDE and GALE.
5. Keep gameplay authority in server systems; animation/VFX never decide damage, timing or rewards.

## Do not do
- Do not merge, reset or force-update `main` from this workstream.
- Do not reintroduce legacy SaveSystem or legacy Crystal registries.
- Do not add duplicate `OnServerInvoke` handlers.
- Do not call CI green without verified evidence.
- Do not rewrite the fixed story.
- Do not treat Ancient as a rarity.
- Do not develop the second world early.
