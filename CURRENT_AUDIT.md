# Crystal Bound — Current Audit

Date: 2026-08-20
Branch: `agent/complete-crystal-bound-foundation`
Base: `main`
Current compare: **1426 commits ahead, 35 commits behind** `main` (verified with GitHub compare).
`main` remains untouched by this workstream; the current compared base is `0e0bf1d1dd0ce62b08d06414dcc09268155e3550`.

## Verified
- Active Rojo tree is `default.project.json`; legacy root SaveSystem/Crystal registry/legacy StatusSpeedGuard paths are not loaded.
- `Bootstrap.server.lua` is the single canonical profile-load owner: one `loadPlayer()` path serves `PlayerAdded` and already-present players after startup, with per-Player deduplication.
- No separate `PlayerLoadCatchup.server.lua` exists or is loaded; startup catch-up is intentionally owned by Bootstrap.
- `PlayerService.Load()` uses a per-UserId load-generation token; a newer load supersedes an older load for the same UserId, and every superseded/aborted successful load releases the specific SessionLock token it acquired before returning.
- `PlayerService` re-checks Player/Profile closing state after waiting on the operation lock before Refresh/Save, preventing heartbeat/autosave access after `Remove()` begins.
- `PlayerService.saveConsistently()` uses bounded revision-settle passes and returns failure if the final pass still detects an in-memory revision change, preventing stale autosave success reporting.
- Dedicated `PlayerLifecycle.server.lua` owns normal `Players.PlayerRemoving` → `PlayerService.Remove()` persistence/release.
- Shutdown blocks new loads, drains pending profile loads, saves/releases loaded profiles through `PlayerService.Remove()`, and has a bounded timeout.
- `SessionHeartbeat` refreshes the session lock and performs 60-second autosaves through `PlayerService`, with independent failure counters and protective kicks.
- `SafeProfileStore` snapshots profile state inside `UpdateAsync` callbacks and resets Load/Save/Refresh/Release result flags on every callback invocation and outer retry.
- `SafeProfileStore` separates per-load claim tokens from the active per-Player Save/Refresh token; `Release(player, expectedToken)` cannot release a different active token.
- `DamageService` is the sole direct `Humanoid:TakeDamage()` owner; damage types, attackers, targets, ranges and amounts are server-validated.
- Environmental damage is strictly `Attacker == nil` in both the generic validator and final `DamageService` gate.
- NPC attackers must be live, parented, `Enemy == true` models inside `Workspace.NPCs`; Player-vs-Player damage is rejected.
- Last-attacker attribution is instance/session-bound, pinned before lethal `TakeDamage()`, restored on zero-applied damage and cleared after successful enemy reward processing.
- Dodge validates finite directions, bounded ranges and cooldowns; `ApplyDamage()` additionally requires the supplied Humanoid to be the current Player Character's Humanoid.
- Dodge invulnerability end-tasks use per-player tokens, so stale delayed callbacks cannot cancel a later dodge after re-dodge or respawn.
- `StatusSpeedGuardV2` enforces server-derived WalkSpeed and bounded position authority with rollback, portal-arrival grace and respawn reset.
- Slow multiplier movement authority is sourced from server-only `StatusEffectService`; neither `PlayerService` nor `StatusSpeedGuardV2` trusts the Humanoid `CrystalBoundSlowMultiplier` attribute for gameplay.
- `StatusEffectService.Clear()` clears the server-owned SlowMultiplier and all delayed Slow/Burn state; token cancellation remains Humanoid-keyed.
- `StatusEffectService` restores player base speed using the canonical `MaxWalkSpeedBonus` cap during Slow expiry.
- Portal authority belongs only to `WorldTheme.server.lua`; Bootstrap is definition-only and cannot register a second teleport handler.
- Portal destination vectors and canonical WorldConfig level gates are protected against Bootstrap/WorldTheme drift by contract.
- Client authority contracts reject direct client Health/MaxHealth/WalkSpeed/CFrame/PivotTo/AssemblyLinearVelocity mutations.
- PC/mobile clients request actions only; gameplay damage, cooldowns, ownership and rewards remain server-side.
- Player Health mutation is centralized in `PlayerService.Heal()` for player healing; NPCService/BossService retain only spawn-time NPC health initialization.
- `CrystalAbilityService` TIDE healing and `UseItemRemote` Health Potion healing both route through `PlayerService.Heal()` with actual-applied rollback handling for potion consumption.
- Crystal ownership is canonicalized by `CrystalSystem`; `GetEquipped()` requires actual ownership and `CrystalService` returns filtered/deduplicated owned-crystal snapshots.
- Crystal Equipped, Owned and Mastery mutation ownership has explicit regression contracts; repair/reconcile writes are the only documented exceptions.
- `CrystalMastery` requires actual crystal ownership for XP, bonuses, upgrade-cost reads and upgrades, independent of request-layer checks.
- `CrystalMastery` enemy mastery rewards are derived from canonical Enemy XP with no arbitrary minimum fallback.
- `PlayerData.Reconcile()` uses the same `CrystalSystem.Exists()` completeness rule as runtime Crystal ownership, preventing partially defined crystal IDs from entering persisted ownership.
- `CrystalConfig` has a completeness contract requiring identical crystal IDs across Definitions, UnlockLevels, BasicAttack, Abilities and Passives.
- `PlayerData.Reconcile()` normalizes Level/XP/Money, Inventory, Crystal ownership/mastery, persistent combat Stats, Quest prerequisites/progress, Achievement/Title state, Daily Bounty definitions and SessionLock data.
- Persisted player XP and CrystalMastery XP are capped below their current level's next threshold; MaxLevel/mastery-cap state forces XP to zero.
- Invalid persisted Achievement IDs are dropped; Titles are reconstructed only from valid persisted Achievements and validated through `AchievementSystem.IsValidTitle()`.
- Persisted DailyBounty EnemyType/Goal/Reward are reconstructed from `DailyBountyConfig`; new profiles receive a concrete valid first-bounty default.
- CrystalMastery rejects malformed IDs, bounds XP/costs/bonuses and never falls back to EMBER for invalid mutation IDs.
- Crystal ability services independently revalidate equipped/owned Crystal context, target type, range and numeric bounds.
- Economy, Inventory, XP, Quest, Achievement, persistent combat Stats, Daily Bounty and Crystal progression mutations have explicit server ownership contracts.
- Shop and Crafting require positive integers, canonical IDs, bounded totals and rollback-safe mutations.
- Crafting output multiplication is validated before inventory-space error formatting or material mutation.
- Shop buying, item use, crafting, enemy rewards and Guardian rewards use canonical detached inventory snapshots rather than exposing live profile tables to clients.
- `GetPlayerData` and `GetQuestData` return detached profile subsets and exclude persistence internals.
- Quest completion validates reward data before state commit; a full Money wallet no longer blocks valid quest completion. XP remains fully awarded and `EconomyService` alone caps the Money portion.
- Daily Bounty validates Money capacity before payout, only marks `Claimed` after a full reward is actually granted, and rolls progress back safely on failed payout.
- Enemy defeat rewards use canonical `EnemyConfig`; full Money wallets no longer block XP/Loot rewards.
- Achievement unlocks are one-shot/idempotent and no longer gated by wallet capacity; `EconomyService` alone caps the Money reward.
- Economy item selling checks wallet capacity before consuming inventory and restores both Money and inventory on unexpected partial payout.
- Guardian rewards use canonical config, bounded XP/Money and registered Drop IDs; a full Money wallet only caps the Money portion and does not block XP, Drop, Boss stats or active Guardian Trial completion.
- Guardian creation is idempotent and destroys a corrupt/non-boss object occupying the reserved `CrystalGuardian` name before spawning the canonical boss.
- Guardian telegraph impacts are bound to the original Guardian and original Character instances, preventing stale windups from damaging respawned Players or replacement Guardians.
- NPC AI is server-only, bounded by aggro/attack/special ranges, uses weak-key path caches and clears path/status state on death.
- AI pathfinding validates that NPCs are still live after yielded `ComputeAsync()` calls before publishing results.
- `EnemyConfig.Get()` returns detached deep copies, including nested `Special` config, while normalizing Respawn.
- NPC dialog requests require canonical NPC identity, server distance and rate-limit checks; config getters return detached copies.
- RemoteEvents/RemoteFunctions are type-validated and have dedicated single-owner/rate-limit contracts.
- `InventoryService.GetInventory()` returns a detached normalized snapshot; legacy `InventorySystem` is blocked from becoming a ServerScriptService authority bypass.
- Shop, UseItem, Crafting, Combat and Guardian server→client inventory outputs use detached InventoryService snapshots.
- `InventoryRequest` is Client→Server only; `InventoryChanged` is Server→Client only.
- Server and client NPC/menu bridges enforce single-open menu state; local menu close/toggle clears `Open*` attributes and listeners ignore `nil`.
- `WorldDecor` is idempotent via readiness markers and bounded waits; `WorldTheme` deduplicates portal bindings and cleans player state.
- AI pathfinding uses finite-validated destinations, quantized cache keys, weak Model keys and bounded recomputation.

## Open decisions / limitations
- No real Roblox Studio runtime playtest has been executed here.
- No Luau interpreter or Rojo CLI runtime validation is available here.
- The latest Combined Status query returned no status objects and commit-specific workflow-run queries returned no runs; CI is therefore not called green.
- Authored Roblox Animation/Sound assets are still absent; current VFX remain procedural/placeholder presentation.
- Movement/physics thresholds still require real Roblox Studio multiplayer validation, especially Dodge velocity, portal grace and Roblox network-ownership interactions.
- `GetPlayerData`/`GetQuestData` return Roblox-serialized profile subsets with detached server-side snapshots; no server-side table reference crosses the network boundary.
- TIDE/GALE currently unlock through level gates; the long-term design includes Mining, Digging, Bosses, Dungeons, World Events and Quests as future Crystal acquisition activities.
- White Queen intro/story rules remain unchanged.

## Next technical direction
1. Continue concrete static audits and eliminate newly introduced authority/config drift.
2. Move to Roblox Studio multiplayer validation when executable runtime access is available.
3. Add authored EMBER Basic + Flame Burst animation/VFX/audio assets first, then repeat asset contracts for TIDE/GALE.
4. Keep gameplay authority in server systems; animation/VFX never decide damage, timing or rewards.

## Do not do
- Do not merge, reset or force-update `main` from this workstream.
- Do not reintroduce legacy SaveSystem or legacy Crystal registries.
- Do not add duplicate `OnServerInvoke` handlers.
- Do not call CI green without verified evidence.
- Do not rewrite the fixed story.
- Do not treat Ancient as a rarity.
- Do not develop the second world early.
