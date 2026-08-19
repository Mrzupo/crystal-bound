# Crystal Bound — Current Audit

Date: 2026-08-19
Branch: `agent/complete-crystal-bound-foundation`
Base: `main`
Current compare: **996 commits ahead, 29 commits behind** `main`.
`main` remains at verified commit `b4877299d51a083f1bf5adfdf1fc152c6a5c1d17`.

## Verified
- `main` remains untouched; development work is isolated on the feature branch.
- `default.project.json` maps the active Rojo runtime tree and explicitly registers `ConfirmedCombatVFXBridge.client.lua`.
- Legacy `SaveSystem.lua` is absent.
- Legacy Crystal registry/definition modules are absent from the active project tree.
- Legacy `StatusSpeedGuard` is not loaded; V2 is the active runtime implementation.
- `DamageService` is the only direct `Humanoid:TakeDamage()` implementation path in `src`.
- Damage requests require known damage types, valid attackers/targets, positive bounded range and finite damage.
- Dodge state resets on respawn and is cleaned on leave; attacker-based Dodge damage normalizes Range before comparison.
- Shop, Crafting and Consumable transactions validate before mutation and use rollback/rate-limit protections.
- Shop and Crafting request amounts are strict positive integers; fractional amounts are rejected instead of floored.
- Crystal Mastery upgrades verify every material removal and roll back already-consumed materials if any removal or the final upgrade fails.
- CrystalSystem only treats Crystal IDs as valid when UnlockLevel is finite/integer and Definition, BasicAttack, Ability and Passive blocks all exist.
- PlayerData rejects malformed persisted Crystal ownership, equipped IDs and Mastery keys using the same complete-config Crystal boundary; malformed equipped state falls back to the first valid owned Crystal instead of blindly restoring EMBER.
- CrystalMastery applies the same complete Crystal-config validation before using a Crystal ID.
- CrystalConfig CI enforces semantic Damage/Range/Cooldown/HealAmount/UnlockLevel bounds.
- Combat modifier CI enforces Critical probability 0..1 and multiplier 1..10.
- Economy config CI validates StartingMoney/MinMoney/MaxMoney relationships instead of hardcoding balance values.
- Inventory stacks are clamped and AddItem never reports a negative added amount from corrupted over-cap state.
- Quest progress rejects invalid/non-finite/non-integer increments.
- Unknown EnemyConfig IDs no longer fall back to TrainingDummy; NPC runtime boundaries reject them cleanly.
- Enemy XP/Money/Loot rewards use canonical `EnemyConfig`; unknown enemy types and implicit Crystal-based fallback rewards are rejected.
- NPC special attacks clamp runtime ranges/cooldowns and Gale teleport offsets to bounded values.
- `CrystalService` is the sole server-facing Crystal ownership wrapper and delegates mutation to `CrystalSystem`.
- Achievement Titles are derived from earned Achievement IDs; achievement Money rewards are granted only for newly unlocked IDs and have one server payout owner.
- Daily Bounty Goal/Reward values are canonicalized from `DailyBountyConfig`; payout has one server owner and completion is claimed before payout.
- Guardian telegraphs are bound to the concrete Guardian instance, preventing old-boss attacks after a respawn.
- `BossService.CreateGuardian()` is idempotent for an existing `CrystalGuardian` model with the same name; the respawn path rechecks the parent before recreating the boss.
- NPC Burn/Slow only apply after the base damage call actually succeeds.
- Enemy respawn configuration is protected by CI against values shorter than NPC cleanup time.
- Session heartbeat failure state uses weak keys; heartbeat kicks after two consecutive refresh failures to protect the save-session lock.
- `PlayerService.Save/Remove` guarantee operation-lock release and clean local player state after final-save failures while retaining the persistent session lock.
- Final player removal treats a failed `SafeProfileStore.Release()` as a failed removal and retains the persistent session lock.
- `PlayerService.Load` now rejects a player that leaves while the yieldable profile load is in flight, and releases the claimed persistent session lock instead of installing an orphaned in-memory profile.
- The load lifecycle is checked again immediately after `Profiles[player]` is populated; a leave race removes the in-memory profile and releases the persistent lock before returning.
- `SessionHeartbeat.server.lua` now registers `game:BindToClose()` and runs the canonical `PlayerService.Remove()` path for loaded profiles during server shutdown, with a bounded shutdown wait.
- `StatusSpeedGuardV2` continuously enforces the server-derived base WalkSpeed even when no Slow effect is active, immediately corrects server-observed `WalkSpeed` property changes, and prevents stale Character listeners across respawns.
- `StatusSpeedGuardV2` now also applies conservative server-side position authority using observed displacement bounds and server rollback, without creating a second server entry-point.
- Movement configuration centralizes observed-speed, displacement-tolerance, position-check interval and portal-arrival tolerance values.
- Server portal movement grace is destination-bound: `WorldTheme.server.lua` only authorizes known portal destinations for players who meet the canonical level requirement, and `StatusSpeedGuardV2` accepts a large displacement only when the server-observed position lands near that expected destination.
- Dodge no longer has a generic movement/teleport grace path; its server velocity remains subject to the same positional authority.
- `DodgeService` explicitly disconnects CharacterAdded listeners on leave/rebind while retaining weak player state.
- Dodge request directions are server-validated as finite `Vector3` values and bounded by `MaxDirectionMagnitude` before movement is applied.
- Bootstrap and all major server Remote entrypoints now fail fast on mismatched Remote classes instead of silently binding the wrong type.
- Critical RemoteEvent/RemoteFunction types are statically verified from `default.project.json` and per-entrypoint fail-fast guards are covered by CI.
- Crystal Animation Controller no longer creates a local Animator; PlayerService creates the Animator server-side.
- Confirmed Crystal VFX follow a server-confirmed presentation flow; gameplay authority never depends on local VFX state.
- CombatPresentation keeps a single Character HealthChanged connection across respawns.
- NPC dialog closes cleanly when transitioning into Quest/Crystal/Shop/Inventory/Crafting menus.
- NPCMenuBridge validates server-side interaction distance before opening NPC menus.
- PC and mobile input can request presentation locally, but gameplay authority remains server-side and VFX require server confirmation before actual VFX playback.
- Combat defeat rewards are sourced from canonical EnemyConfig and guarded by `DeathRewarded` idempotency.
- Environmental/Boss hazard contracts validate attacker-less Environmental damage against current `BossArena` semantics rather than stale exact calls.
- RemoteFunction contract uses the actual Bootstrap request-interval guards.
- Portal contract verifies gates consume canonical `WorldConfig` level fields.
- Status effects use weak Humanoid state, token-based cancellation for Slow/Burn, and explicit `Clear()` cleanup; a lifecycle contract now protects those invariants.
- `HitboxService.GetEnemyModels()` resolves targets only from `Workspace.NPCs`, requires `Model` + `Enemy == true`, living Humanoids and bounded radius; a dedicated regression contract now protects that boundary.
- Quest completion is owned by `QuestService`; `QuestSystem.Complete()` now has a dedicated single-owner regression contract alongside the existing quest active-state checks.
- `movement-authority-contract.yml` now protects both server WalkSpeed and position authority plus verified portal-arrival semantics and explicitly forbids generic movement grace.
- `boss-creation-idempotency.yml` protects Guardian duplicate-creation and respawn ownership.
- `session-shutdown-contract.yml` protects the canonical server shutdown save/release path.
- Stale CI contracts were corrected where they still asserted retired inline values or variable names; the active contracts now inspect current config-driven runtime paths.
- `contract-path-validation.yml` validates that workflow-referenced repository paths exist.
- Additional contracts protect strict crafting input boundaries, final player-remove/session-release semantics, PlayerService load lifecycle, Crystal upgrade material transaction rollback, StatusSpeedGuard baseline/immediate/stale-character enforcement, complete Crystal ID validation, NPC menu interaction distance, Achievement reward ownership, Daily Bounty reward ownership, Dodge listener lifecycle and input boundaries, Hitbox PvE target boundaries, Quest completion ownership, Remote type initialization, combat reward idempotency, Guardian creation idempotency, server shutdown persistence, NPC special movement bounds, attacker-context/range validation, and semantic balancing bounds.
- Studio playtest checklist covers Damage bounds, Crystal upgrade rollback, fractional transaction rejection, final session-release failure, baseline WalkSpeed enforcement, malformed/incomplete Crystal config, NPC interaction distance and movement/respawn checks.

## Important open decisions / limitations
- No real Roblox Studio runtime playtest has been executed here.
- No Luau interpreter is available in this environment.
- The current head has no reported Combined Status checks and no PR-triggered workflow runs available through the connector; do not call CI green without an actual status result.
- Authored Roblox Animation/Sound assets are still absent.
- Current VFX are still procedural/placeholder presentation.
- TIDE/GALE currently unlock through level gates; the master design also plans Mining, Digging, Bosses, Dungeons, World Events and Quests as long-term Crystal acquisition activities. Do not silently replace one model with another; decide the final model first.
- White Queen intro/story implementation has not been replaced or rewritten; the story rules remain unchanged.
- The conservative server movement-position anti-teleport foundation is now present, but its thresholding and interaction with Roblox network ownership/physics still require real Studio multiplayer validation before calling the exploit-resistance complete.

## Next technical direction
1. Continue concrete static audits where risk remains, prioritizing server authority, persistence and lifecycle races.
2. Move toward Roblox Studio runtime validation, especially movement correction, portal arrivals, Dodge velocity, shutdown saves and multi-player contention.
3. Add authored EMBER Basic + Flame Burst animation/VFX/audio assets first.
4. Repeat the asset contract for TIDE and GALE.
5. Keep gameplay authority in server systems; animation/VFX never decide damage, timing or rewards.
