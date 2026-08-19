# Crystal Bound — Session Handoff

## Branch
- Branch: `agent/complete-crystal-bound-foundation`
- Base: `main`
- Current compare: **956 commits ahead, 29 commits behind** `main` (verified with GitHub compare).
- `main` remains at verified commit `b4877299d51a083f1bf5adfdf1fc152c6a5c1d17`.

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
- Damage input boundaries reject non-positive, non-finite and oversized values at the canonical validator.
- Shop and Crafting request quantities are strict positive integers; fractional requests are rejected instead of floored.
- Unknown EnemyConfig IDs no longer fall back to TrainingDummy; NPC runtime boundaries reject them cleanly.
- Enemy XP/Money/Loot rewards use canonical `EnemyConfig`; no Crystal-based fallback rewards.
- Combat defeat rewards have explicit `DeathRewarded` idempotency.
- NPC special attacks clamp runtime ranges/cooldowns and Gale teleport offsets to bounded values.
- Inventory corrupt stacks are clamped before mutation.
- Quest progress rejects invalid/non-finite/non-integer increments.
- CrystalSystem, PlayerData and CrystalMastery accept only complete Crystal configurations with finite integer UnlockLevels plus Definition/BasicAttack/Ability/Passive data.
- Crystal mastery persistence drops malformed/incomplete Crystal IDs and falls back Equipped state to the first valid owned Crystal.
- Daily Bounty payout has one server owner and marks the bounty claimed before payout.
- Achievement payout has one server owner and only pays newly unlocked achievements.
- Guardian telegraph binds to the exact Guardian instance.
- Environmental damage contracts follow the current attacker-less BossArena implementation.
- NPC Burn/Slow only apply after confirmed damage.
- NPCMenuBridge validates server-side interaction distance before opening NPC menus.
- PlayerService Save/Remove guarantees operation-lock release and preserves persistent locks after failed final saves/releases.
- SessionHeartbeat kicks after two consecutive Refresh failures to protect the save-session lock.
- `StatusSpeedGuardV2` continuously restores server-derived WalkSpeed, immediately corrects property changes, and prevents stale Character listeners across respawns.
- DodgeService explicitly disconnects CharacterAdded listeners on leave/rebind while retaining weak player state.
- Bootstrap and the major server Remote entrypoints now fail fast on mismatched Remote classes instead of silently destroying/binding the wrong type.
- Remote type contract covers Bootstrap, CombatFeedback, Shop, Crafting, Dodge, Consumables, NPCDialog and AvailableQuests entrypoints.
- RemoteFunction contract now matches the actual Bootstrap rate-limit variable names.
- Portal contract now verifies portal gates consume canonical `WorldConfig` level fields instead of hardcoded numeric assertions.
- Stale CI contracts were corrected where they still asserted retired inline values or variable names; current contracts now inspect the active config-driven code paths.
- A workflow self-check validates that workflow-referenced repository paths exist.
- Studio playtest matrix covers the latest transaction, persistence, movement-security, Crystal configuration, NPC interaction, reward-idempotency and Remote-type cases.
- README, DESIGN, TESTING, TODO, CHANGELOG and CURRENT_AUDIT are aligned with the current architecture.

## Security / authority rules
- `DamageService` is the only direct `Humanoid:TakeDamage()` path in `src`.
- Known DamageTypes only.
- Positive finite damage and bounded range only.
- PvP damage blocked in current PvE-first combat path.
- Client cannot authoritatively grant Crystals, items, Money, XP, damage or quest completion.
- Server derives and enforces WalkSpeed; local movement presentation cannot become authoritative speed.
- Animation/VFX never decide gameplay.
- Critical RemoteFunctions have single `OnServerInvoke` ownership.
- Important Remotes are rate-limited.

## Open decisions / limitations
- No actual Roblox Studio runtime playtest has been executed here.
- No Luau interpreter is available in this environment.
- Latest Combined Status is not verified through the available GitHub connector.
- Authored Roblox Animation/Sound assets are still missing.
- Current VFX remain procedural/placeholder-level.
- TIDE/GALE currently use level-gated prototype unlocks, while the master design lists Mining, Digging, Bosses, Dungeons, World Events and Quests as long-term Crystal acquisition activities. Decide the final model before building acquisition content.
- Story remains fixed: White Queen, first loss, unknown world, Ancient Crystal lore, multiple future worlds and delayed second-world reveal.
- A conservative server movement-position anti-teleport system has not been added; WalkSpeed authority and server-side range checks are hardened, but true exploit-driven position spoofing remains a runtime concern to validate in Studio.

## Next steps
1. Continue only concrete static audits where risk remains.
2. Move toward Roblox Studio runtime validation.
3. Add authored EMBER Basic + Flame Burst animation/VFX/audio assets first.
4. Repeat the asset contract for TIDE and GALE.
5. Test combat, boss, AI, persistence, movement and mobile with real Studio Output.
6. Decide final Crystal acquisition model before Mining/Digging implementation.

## Do not do
- Do not merge into `main`.
- Do not reintroduce legacy SaveSystem or legacy Crystal registries.
- Do not add duplicate `OnServerInvoke` handlers.
- Do not call CI green without verified evidence.
- Do not rewrite the fixed story.
- Do not treat Ancient as a rarity.
- Do not develop the second world early.
