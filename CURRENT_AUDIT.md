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
- `PlayerService` checks `player.Parent` before installing a loaded profile and again immediately after installation; startup failure only kicks a still-present Player.
- `PlayerService` marks `Closing` before final removal; normal gameplay `GetProfile`/Sync/Save/Refresh/Heal paths reject closing players.
- Shutdown blocks new loads and removes loaded profiles through the normal Save/Release path while separately draining pending loads.
- `SafeProfileStore` uses callback-local retry flags, session tokens and lock ownership checks; Save snapshots `clone(profile)` inside the `UpdateAsync` callback.
- `PlayerService.saveConsistently()` uses bounded profile-revision settle passes, so a save is not reported successful when the profile changed during a settled save pass.
- `DamageService` is the only direct `Humanoid:TakeDamage()` owner.
- Damage requests require finite positive bounded amounts, known DamageTypes, valid attacker/target context and server-side range checks.
- Environmental damage requires `Attacker == nil`; PvP is rejected in the current PvE foundation.
- NPC attacker/target identity is exact: relevant NPC Models must be direct children of `Workspace.NPCs`; stale descendant-only assumptions were removed from the PvE attacker-context contract.
- Last-attacker attribution is instance/session-bound and restored when no damage is actually applied.
- Dodge uses finite direction validation, server cooldowns, tokenized invulnerability expiry and current-character Humanoid validation.
- Player Health mutation is centralized in `PlayerService.Heal()`; NPC/Boss services only initialize NPC Humanoid health.
- `StatusEffectService` uses Humanoid-scoped replacement tokens for Slow/Burn delayed callbacks and clears state on lifecycle cleanup.
- `StatusSpeedGuardV2` derives WalkSpeed server-side and enforces bounded position authority with Character-bound portal grace.
- Portal authority is owned by `WorldTheme.server.lua`; Bootstrap defines portal geometry but does not register teleport authority.
- Crystal ownership/equip/unlock and Crystal Mastery read/write paths require canonical Crystal validity and actual ownership.
- Inventory snapshots are detached and pure; Shop/Crafting/UseItem paths validate inputs before mutation and roll back partial transaction failures.
- Quest completion requires the objective for multi-step quests and is idempotent through QuestSystem state checks.
- Daily Bounty state and reward values are reconstructed from canonical config; payout only claims after a full reward transaction succeeds.
- Enemy and Guardian rewards preserve XP/Loot/progression when Money is capped; Money is bounded centrally by EconomyService.
- Guardian telegraphs are bound to the original Guardian and target Character instances, preventing stale delayed impacts on replacement instances.
- NPC Pathfinding revalidates NPC liveness after yielded `ComputeAsync()` work.
- `WorldDecor` and `WorldTheme` use idempotency/lifecycle markers and per-player cleanup state.
- RemoteFunction ownership is contract-checked to one server handler per named function; important RemoteEvents have explicit direction/rate-limit contracts.

## Contract changes in this hardening pass
- `.github/workflows/pve-attacker-context-validation.yml` now checks exact `Workspace.NPCs` parent identity instead of the weaker descendant-only assumption.
- `.github/workflows/player-load-rejoin-race-contract.yml` now matches the actual runtime: duplicate same-UserId loads are rejected while the first load is in flight, rather than claiming superseded loads.
- `NEXT_SESSION.md` is synchronized to the same load-concurrency semantics.

## Open / runtime-only limitations
- No real Roblox Studio runtime playtest has been executed from this environment.
- No Luau interpreter or Rojo CLI runtime validation is available here.
- Latest checked workflow-run queries do not provide a verified green CI run for this hardening work; CI is not claimed green.
- Movement physics/network ownership thresholds still require real Roblox multiplayer validation, especially Dodge velocity, portal grace and position correction.
- Ordinary `PlayerService.GetProfile()` callers are conservatively blocked during autosave; selected server reward paths intentionally use an autosave-safe loaded-profile path and rely on revision-settle behavior.
- Authored Roblox Animation/Sound assets remain pending; current VFX are procedural/placeholder presentation.
- TIDE/GALE remain level-gated prototype unlocks until the final Crystal acquisition design is decided.

## Runtime test priority
1. Boot/profile loading and Player leave during load.
2. Autosave mutation/settle and final Release failure behavior.
3. Combat range, PvP rejection, Dodge and NPC/Boss attacker identity.
4. Enemy death/respawn and Guardian telegraph replacement races.
5. Portal movement authority and Dodge/network ownership.
6. Shop/Crafting/Consumables and transaction rollback.

## Do not do
- Do not reset, force-push or otherwise rewrite `main` from this workstream.
- Do not call CI green without verified workflow evidence.
- Do not reintroduce legacy persistence/Crystal registries.
- Do not treat Ancient as a rarity.
- Do not develop the second world early.
- Do not allow client presentation/animation/VFX to become gameplay authority.
