# Crystal Bound — Current Audit

Date: 2026-08-20
Branch: `agent/complete-crystal-bound-foundation`
Base: `main`
Current compare: **1345 commits ahead, 30 commits behind** `main` (verified with GitHub compare).
`main` remains untouched by this workstream; the current compared base is `4b72e6213dd764d1ab30eb8f425f9c107369642e`.

## Verified
- Active Rojo tree is `default.project.json`; legacy root SaveSystem/Crystal registry/legacy StatusSpeedGuard paths are not loaded.
- Dedicated `PlayerLifecycle.server.lua` owns normal `Players.PlayerRemoving` → `PlayerService.Remove()` persistence/release.
- `PlayerLoadCatchup.server.lua` covers players entering during Bootstrap world initialization with a bounded 30-second scan, while refusing to become a second `PlayerAdded` owner, skipping active loads and known failed loads.
- `PlayerService.Load()` uses a per-UserId load-generation token and shutdown gate so stale/rejoined loads cannot mutate or release a newer session.
- `PlayerService` CharacterAdded callbacks re-check the exact Character instance before binding Humanoid/health state, preventing stale-respawn callback races.
- Shutdown blocks new loads, drains pending profile loads, saves/releases loaded profiles through `PlayerService.Remove()`, and has a bounded timeout.
- `SessionHeartbeat` refreshes the session lock and performs 60-second autosaves through `PlayerService`, with independent failure counters and protective kicks.
- `SafeProfileStore` snapshots profile state inside `UpdateAsync` callbacks and resets Load/Save/Refresh/Release result flags on every callback invocation and outer retry, preventing stale callback state from leaking across DataStore retries.
- `DamageService` is the sole direct `Humanoid:TakeDamage()` owner; damage types, attackers, targets, ranges and amounts are server-validated.
- Environmental damage is strictly `Attacker == nil` in both the generic validator and final `DamageService` gate.
- NPC attackers must be live, parented, `Enemy == true` models inside `Workspace.NPCs`; Player-vs-Player damage is rejected.
- Last-attacker attribution is instance/session-bound, pinned before lethal `TakeDamage()`, restored on zero-applied damage and cleared after successful enemy reward processing.
- Dodge validates finite directions, bounded ranges and cooldowns; respawn/leave cleanup clears ForceField, invulnerability and state.
- Dodge invulnerability end-tasks use per-player tokens, so stale delayed callbacks cannot cancel a later dodge after re-dodge or respawn.
- `StatusSpeedGuardV2` enforces server-derived WalkSpeed and bounded position authority with rollback, portal-arrival grace and respawn reset.
- Movement speed refresh and position enforcement now run on separate cadences; `PositionCheckInterval` is honored exactly instead of being masked by the 0.25-second enforcement loop.
- Slow multiplier movement authority is sourced from server-only `StatusEffectService` state; `StatusSpeedGuardV2` no longer trusts the Humanoid `CrystalBoundSlowMultiplier` attribute for gameplay.
- Missing Humanoid/RootPart resets the movement position snapshot, preventing stale `sampleDt` from inflating teleport tolerance.
- Portal authority belongs only to `WorldTheme.server.lua`; Bootstrap is definition-only and cannot register a second teleport handler.
- Portal destination vectors and canonical WorldConfig level gates are protected against Bootstrap/WorldTheme drift by contract.
- Client authority contracts reject direct client Health/MaxHealth/WalkSpeed/CFrame/PivotTo/AssemblyLinearVelocity mutations.
- PC/mobile clients request actions only; gameplay damage, cooldowns, ownership and rewards remain server-side.
- Crystal ownership is canonicalized by `CrystalSystem`; `GetEquipped()` requires actual ownership and `CrystalService` returns filtered/deduplicated owned-crystal snapshots.
- Crystal Equipped, Owned and Mastery mutation ownership has explicit regression contracts; repair/reconcile writes are the only documented exceptions.
- `PlayerData.Reconcile()` normalizes persisted numeric values, Crystal ownership/equip/mastery, inventory, quests, islands, bounty and SessionLock data.
- CrystalMastery rejects malformed IDs, bounds XP/costs/bonuses and never falls back to EMBER for invalid mutation IDs.
- Crystal ability services independently revalidate equipped/owned Crystal context, target type, range and numeric bounds.
- Economy, Inventory, XP, Quest, Achievement, persistent combat Stats, Daily Bounty and Crystal progression mutations have explicit server ownership contracts.
- Shop and Crafting require positive integers, canonical IDs, bounded totals and rollback-safe mutations.
- Crafting output multiplication is validated before inventory-space error formatting or material mutation, closing malformed-config overflow paths.
- Shop buying, item use, crafting, enemy rewards and Guardian rewards consume/restore canonical detached inventory snapshots rather than exposing live profile tables to clients.
- Quest completion validates reward data and Money capacity before persistent completion state is committed.
- Daily Bounty validates Money capacity before payout, only marks `Claimed` after a full reward is actually granted, and rolls progress back safely on failed payout.
- Enemy defeat rewards use canonical `EnemyConfig`; full Money wallets no longer block XP/Loot rewards.
- Economy item selling now checks wallet capacity before consuming inventory and restores both Money and inventory on any unexpected partial payout, closing the full-wallet sale replay exploit.
- Guardian rewards use canonical config, keep XP/Drop when the wallet is full, and only set `Rewarded` when a valid player profile exists.
- Guardian creation is idempotent and destroys a corrupt/non-boss object occupying the reserved `CrystalGuardian` name before spawning the canonical boss, preventing duplicate-name identity collisions.
- Guardian telegraph impacts are bound to the original Character instance, preventing an old windup from damaging a freshly respawned Character.
- Guardian phase values and telegraph lifecycle are contract-protected.
- NPC AI is server-only, bounded by aggro/attack/special ranges, uses weak-key path caches and clears path/status state on death.
- AI pathfinding validates that the NPC is still live after the yielded `ComputeAsync()` call, preventing stale path results from being applied after death/destroy.
- `EnemyConfig.Get()` returns a detached deep copy, including nested `Special` config, while centrally normalizing Respawn.
- Status effects use Humanoid-keyed token cancellation; Slow/Burn tasks stop on death/destroy or token replacement.
- NPC dialog requests require canonical NPC identity, server distance and rate-limit checks; config getters return detached copies.
- RemoteEvents/RemoteFunctions are type-validated and have dedicated single-owner/rate-limit contracts.
- `InventoryRequest` is request-only; `InventoryChanged` is the server-to-client inventory snapshot event used by `InventoryMenu`.
- `GetPlayerData` has an explicit public-data exposure contract excluding SessionLock/SessionId/operation internals and now returns a detached deep-copy snapshot.
- `GetQuestData` returns detached Active/Completed/Progress/Definitions snapshots; a dedicated quest-data exposure contract protects this boundary.
- `InventoryService.GetInventory()` returns a detached normalized snapshot; legacy `InventorySystem` is blocked from becoming a ServerScriptService authority bypass.
- Server and client NPC/menu bridges enforce single-open menu state; local menu close/toggle clears the corresponding `Open*` attribute, and listeners ignore `nil` so clearing one menu cannot open another.
- `WorldDecor` is idempotent via readiness markers and bounded waits; `WorldTheme` deduplicates portal bindings and cleans player state.
- AI pathfinding uses finite-validated destinations, quantized cache keys, weak Model keys and bounded recomputation.

## Open decisions / limitations
- No real Roblox Studio runtime playtest has been executed here.
- No Luau interpreter or Rojo CLI runtime validation is available here.
- The latest Combined Status query returned no status objects and the latest commit-specific workflow-run query returned no runs; CI is therefore not called green.
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