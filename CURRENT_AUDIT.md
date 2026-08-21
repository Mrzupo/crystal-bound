# Crystal Bound — Current Audit

Date: 2026-08-21
Branch: `agent/complete-crystal-bound-foundation`
Base: `main`

## Verified
- `main` remains untouched by this workstream.
- `default.project.json` is the active Rojo source of truth; legacy root SaveSystem/Crystal registry/legacy StatusSpeedGuard mappings remain excluded.
- `Bootstrap.server.lua` is the single canonical profile-load owner with one `PlayerAdded` path plus startup catch-up and per-Player deduplication.
- `PlayerService.Load()` uses a per-UserId in-flight guard. A second concurrent load for the same UserId is rejected with `Profile load already in progress`; the current runtime does not implement a newer-load-takes-over model.
- Every successful-but-aborted profile load path releases the exact SessionLock token returned by that load.
- `SafeProfileStore.Load()` now catches `PlayerData.Reconcile()` failures after a successful DataStore lock claim and releases that exact claimed SessionLock token before returning failure.
- `PlayerService` checks `player.Parent` before installing a loaded profile and again immediately after installation; startup failure only kicks a still-present Player.
- `PlayerService` marks `Closing` before final removal; normal gameplay `GetProfile`/Sync/Save/Refresh/Heal paths reject closing players.
- `ProfileLoaded` is server-owned, starts false, becomes true only after initial profile/Character initialization succeeds, becomes false again during Player removal and on every new Character until that Character has been synced.
- `DamageService` requires `ProfileLoaded=true` for Player attackers and Player targets; `DodgeService`, `QuestService`, `DailyBountyService`, `CrystalAbilityService` and StatusEffectService use the same readiness boundary where they mutate player-specific gameplay state.
- Shutdown blocks new loads and removes loaded profiles through the normal Save/Release path while separately draining pending loads.
- `SafeProfileStore` uses callback-local retry flags, session tokens and lock ownership checks; Save snapshots `clone(profile)` inside the `UpdateAsync` callback.
- `PlayerService.saveConsistently()` uses bounded profile-revision settle passes, so a save is not reported successful when the profile changed during a settled save pass.
- `DamageService` is the only direct `Humanoid:TakeDamage()` owner.
- Damage requests require finite positive bounded amounts, known DamageTypes, valid attacker/target context and server-side range checks.
- Environmental damage requires `Attacker == nil`; PvP is rejected in the current PvE foundation.
- NPC attacker/target identity is exact: relevant NPC Models must be direct children of `Workspace.NPCs`; normal enemies use `Enemy=true` and Boss models are also valid through `BossId`.
- Last-attacker attribution is instance/session-bound and restored when no damage is actually applied; Boss models are valid authoritative attackers as well.
- Dodge uses finite direction validation, server cooldowns, tokenized invulnerability expiry and current-character Humanoid validation.
- `DodgeRemote.server.lua` rejects new Dodge requests during global shutdown or when the player no longer has an accessible profile.
- Player Health mutation is centralized in `PlayerService.Heal()`; NPC/Boss services only initialize NPC Humanoid health.
- `StatusEffectService` uses Humanoid-scoped replacement tokens for Slow/Burn delayed callbacks, rejects new effects after the published shutdown flag or when a Player Character is not ProfileLoaded, and stops delayed callbacks at the shutdown boundary without introducing a PlayerService module cycle.
- `StatusSpeedGuardV2` derives WalkSpeed server-side and enforces bounded position authority with Character-bound portal grace; both enforcement loops and deferred Character refreshes stop when global shutdown begins.
- Portal authority is owned by `WorldTheme.server.lua`; Bootstrap defines portal geometry but does not register teleport authority.
- Portal cooldown callbacks are generation-safe: a delayed callback can clear only the cooldown generation that created it, so an old pre-respawn callback cannot clear a new Character's cooldown.
- `WorldTheme` portal-touch/deferred arrival logic and its periodic state monitor stop during global shutdown.
- `NPCMenuBridge` deferred dialog opening is Character-bound, and open menu attributes are cleared again on CharacterAdded so stale UI state cannot survive a respawn.
- Character-bound PlayerService health/Animator sync aborts on global shutdown or non-ready Characters before touching Character gameplay state.
- Crystal ownership/equip/unlock and Crystal Mastery read/write paths require canonical Crystal validity and actual ownership.
- `CrystalAbilityService.Execute()` is defense-in-depth bound to the exact current Player profile, `ProfileLoaded`, canonical equipped/owned Crystal identity and a live direct-child NPC target for GALE.
- Inventory snapshots are detached and pure; Shop/Crafting/UseItem paths validate inputs before mutation and roll back partial transaction failures.
- Shop and Crafting explicitly remove any partial inventory insertion before refunding/reversing a failed transaction, matching the inventory rollback contract.
- Quest completion requires the objective for multi-step quests and is idempotent through QuestSystem state checks.
- `QuestService` start/complete/next-quest mutations require the exact current Player profile and `ProfileLoaded=true`.
- Daily Bounty state and reward values are reconstructed from canonical config; payout only claims after a full reward transaction succeeds.
- `DailyBountyService.AddProgress()` now requires the exact current Player profile and `ProfileLoaded=true` before mutating progress or paying the reward.
- Persisted Daily Bounty state enforces `Claimed => Progress >= Goal`; corrupt `Claimed=true` / incomplete-goal state is normalized back to unclaimed during `PlayerData.Reconcile()`.
- Enemy AI loops stop on global shutdown; delayed enemy respawn callbacks cannot create new NPCs after shutdown begins.
- Guardian creation, AI and delayed respawn stop on global shutdown.
- Guardian Arena phase-2 hazard damage and its periodic loop stop on global shutdown, and active hazard visuals are disabled when the loop exits.
- Enemy and Guardian rewards preserve XP/Loot/progression when Money is capped; Money is bounded centrally by EconomyService.
- Guardian telegraphs are bound to the original Guardian and target Character instances; delayed impacts are canceled for dead/replaced instances, remain limited to the 8-stud impact zone, and pass the current Guardian-to-target distance to DamageService.
- TIDE Tidal Pulse is targetless on PC, mobile and server routing and does not consume its server cooldown when no health can actually be healed.
- GALE splash damage is centered on the selected enemy and uses the configured AoE radius while keeping the primary attacker-to-target validation separate from secondary splash range.
- NPC Pathfinding revalidates NPC liveness after yielded `ComputeAsync()` work.
- `WorldDecor` and `WorldTheme` use idempotency/lifecycle markers and per-player cleanup state.
- RemoteFunction ownership is contract-checked to one server handler per named function; important RemoteEvents have explicit direction/rate-limit contracts.

## Contract changes in this hardening pass
- `.github/workflows/pve-attacker-context-validation.yml` checks exact `Workspace.NPCs` parent identity, explicit BossId attacker validity, and `ProfileLoaded` Player readiness in the central DamageService.
- `.github/workflows/player-load-rejoin-race-contract.yml` matches runtime duplicate-load rejection rather than claiming superseded loads.
- `.github/workflows/player-load-lifecycle-contract.yml` covers Closing/shutdown/parent guards, ProfileLoaded lifecycle, post-load race protection and initial Sync rollback.
- `.github/workflows/player-health-connection-lifecycle.yml` covers Character-bound ProfileLoaded invalidation and readiness during respawn.
- `.github/workflows/player-derived-attribute-authority-contract.yml` keeps ProfileLoaded single-owner authority in PlayerService and requires DamageService/DodgeService to respect it.
- `.github/workflows/quest-completion-ownership.yml` now covers exact Player/profile ownership and ProfileLoaded for QuestService mutations.
- `.github/workflows/quest-chain-config-validation.yml` enforces the linear, single-root, acyclic quest dependency graph required by QuestSystem.GetChainOrder().
- `.github/workflows/persistence-reconcile-contract.yml` and `player-data-reconciliation-contract.yml` guard the Daily Bounty impossible-state invariant.
- `.github/workflows/daily-bounty-state-write-ownership.yml` now covers Player/profile/ProfileLoaded ownership for Daily Bounty mutation/reward.
- `.github/workflows/profile-store-session-contract.yml` guards exact SessionLock release when `PlayerData.Reconcile()` fails after a successful load claim.
- `.github/workflows/player-remove-release-contract.yml` matches the combined Shutdown/Closing/Saving guard in `GetProfile()`.
- `.github/workflows/inventory-transaction-rollback.yml` is satisfied by explicit partial-insertion rollback in Shop and Crafting.
- `.github/workflows/world-init-validation.yml` guards tokenized portal cooldown expiry and WorldTheme shutdown lifecycle.
- `.github/workflows/menu-attribute-contract.yml` guards Character-bound deferred NPC dialog opening and respawn menu cleanup.
- `.github/workflows/enemy-lifecycle-validation.yml` requires shutdown-safe enemy AI and respawn behavior.
- `.github/workflows/boss-active-spawn-contract.yml` requires shutdown-safe Guardian creation, AI and respawn behavior.
- `.github/workflows/movement-authority-contract.yml` requires shutdown-aware WalkSpeed/position loops and Character-bound deferred binds.
- `.github/workflows/boss-attack-contract.yml` requires shutdown-safe Guardian telegraph and Arena hazard behavior plus the corrected telegraph-to-DamageService range handoff.
- `.github/workflows/dodge-input-boundary.yml` requires a profile/shutdown gate at the mutating Dodge Remote and Service boundary.
- `.github/workflows/status-effect-lifecycle-contract.yml` covers Player ProfileLoaded readiness for new Slow/Burn effects in addition to lifecycle cleanup.
- `.github/workflows/status-effect-stale-callback-contract.yml` covers Humanoid-scoped replacement tokens plus the server-published shutdown boundary.
- `.github/workflows/tide-self-ability-contract.yml` covers targetless TIDE semantics.
- `.github/workflows/crystal-ability-context-contract.yml` covers exact Player profile ownership, ProfileLoaded and live NPC target context inside the AbilityService itself.
- `STUDIO_PLAYTEST.md`, `TESTING.md`, `TODO.md`, and `NEXT_SESSION.md` are synchronized with the current lifecycle/transaction hardening state.

## Open / runtime-only limitations
- No real Roblox Studio runtime playtest has been executed from this environment.
- No Luau interpreter or Rojo CLI runtime validation is available here.
- Latest checked workflow-run queries do not provide a verified green CI run for this hardening work; CI is not claimed green.
- Movement physics/network ownership thresholds still require real Roblox multiplayer validation, especially Dodge velocity, portal grace and position correction.
- Ordinary `PlayerService.GetProfile()` callers are conservatively blocked during autosave; selected server reward paths intentionally use an autosave-safe loaded-profile path and rely on revision-settle behavior.
- Authored Roblox Animation/Sound assets remain pending; current VFX are procedural/placeholder presentation.
- TIDE/GALE remain level-gated prototype unlocks while the long-term Crystal acquisition design remains undecided.
- The initial PlayerService Sync-failure path releases the session lock and removes the profile but still leaves some presentation-only initialization cleanup to Roblox object teardown; this is a low-priority cleanup, not an authority bypass.

## Runtime test priority
1. Boot/profile loading and Player leave during load.
2. Autosave mutation/settle and final Release failure behavior.
3. Combat range, PvP rejection, Dodge, ProfileLoaded readiness and NPC/Boss attacker identity.
4. Respawn readiness: verify Player ProfileLoaded turns false on CharacterAdded and true only after server Character sync.
5. Enemy death/respawn, shutdown-respawn suppression and Guardian telegraph replacement races.
6. Portal movement authority, stale cooldown callbacks across respawn, NPC menu Character lifecycle, movement shutdown and Dodge/network ownership.
7. Shop/Crafting/Consumables and transaction rollback.
8. Guardian Arena hazard shutdown behavior when executable Studio testing is available.
9. StatusEffect Burn/Slow shutdown/readiness behavior in real Studio runtime.

## Do not do
- Do not reset, force-push or otherwise rewrite `main` from this workstream.
- Do not call CI green without verified workflow evidence.
- Do not reintroduce legacy persistence/Crystal registries.
- Do not treat Ancient as a rarity.
- Do not develop the second world early.
- Do not allow client presentation/animation/VFX to become gameplay authority.
