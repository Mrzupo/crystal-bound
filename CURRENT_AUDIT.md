# Crystal Bound — Current Audit

Date: 2026-08-20
Branch: `agent/complete-crystal-bound-foundation`
Base: `main`
Current compare: **1223 commits ahead, 29 commits behind** `main`.
`main` remains untouched at verified commit `b4877299d51a083f1bf5adfdf1fc152c6a5c1d17`.

## Verified
- Active Rojo tree is `default.project.json`; legacy root SaveSystem/Crystal registry/legacy StatusSpeedGuard paths are not loaded.
- `DamageService` is the sole direct `Humanoid:TakeDamage()` owner; damage types, attackers, targets, ranges and amounts are server-validated.
- Environmental damage is strictly `Attacker == nil`; attacker-attributed PvE damage uses canonical attacker validation.
- NPC attackers must be live, parented, `Enemy == true` models inside `Workspace.NPCs`; Player-vs-Player damage is rejected.
- Last-attacker attribution is instance/session-bound, pinned before lethal `TakeDamage()`, restored on zero-applied damage and cleared after successful enemy reward processing.
- Dodge validates finite directions, bounded ranges and cooldowns; respawn/leave cleanup clears ForceField, invulnerability and state.
- `StatusSpeedGuardV2` enforces server-derived WalkSpeed and bounded position authority with rollback, portal-arrival grace and respawn reset.
- Portal authority belongs only to `WorldTheme.server.lua`; Bootstrap is definition-only and cannot register a second teleport handler.
- Client authority contracts reject direct client Health/MaxHealth/WalkSpeed/CFrame/PivotTo/AssemblyLinearVelocity mutations.
- PC/mobile clients request actions only; gameplay damage, cooldowns, ownership and rewards remain server-side.
- Crystal ownership is canonicalized by `CrystalSystem`; `GetEquipped()` requires actual ownership and `CrystalService` returns filtered/deduplicated owned-crystal snapshots.
- `PlayerData.Reconcile()` normalizes persisted numeric values, Crystal ownership/equip/mastery, inventory, quests, islands, bounty and SessionLock data.
- Crystal Equipped, Owned and Mastery write ownership is protected by dedicated contracts; repair/reconcile writes are explicit exceptions.
- Crystal ability services independently revalidate equipped/owned Crystal context, target type, range and numeric bounds.
- Economy, Inventory, XP, Quest, Achievement, Stats, Daily Bounty and Crystal progression mutations have explicit server ownership contracts.
- Shop and Crafting require positive integers, canonical IDs, bounded totals and rollback-safe mutations.
- Crafting additionally requires `recipe.Output == outputId` to prevent corrupted recipe identity drift.
- Consumable use validates canonical config ItemId, possession, live/not-full Humanoid state and bounded heal amount before consuming inventory.
- Quest progress rejects invalid increments; completion is owned by `QuestService` and validates reward data before commit.
- Special one-step quests are owner-gated to actual Combat/Boss server contexts.
- Achievement unlocks are idempotent and reward payout has one server owner.
- Daily Bounty is canonical-config driven, detached on public `Get()` and fail-safe around Money caps.
- Guardian creation is idempotent and active from the loaded BossTelegraph path; reward config, Drop registration, Phase 2 values and telegraph lifecycle are contract-protected.
- Boss telegraphs are tied to the concrete Guardian instance and revalidate Player/Character state before delayed impact.
- NPC AI is server-only, bounded by aggro/attack/special ranges, uses weak-key path caches and clears path/status state on death.
- Status effects use Humanoid-keyed token cancellation; Slow/Burn tasks stop on death/destroy or token replacement.
- `NPCDialogConfig.Get()` returns a detached deep copy.
- NPC dialog requests require canonical NPC identity, server distance and rate-limit checks.
- Server and client NPC/menu bridges enforce single-open menu state; Quest/Shop/Inventory/Crafting/Achievement/NPCDialog menus clear their `Open*` attribute on local close/toggle transitions.
- RemoteEvents/RemoteFunctions are type-validated and have dedicated single-owner/rate-limit contracts.
- `GetPlayerData` has an explicit public-data exposure contract excluding SessionLock/SessionId/operation internals.
- `InventoryService.GetInventory()` returns a detached normalized snapshot.
- Legacy `InventorySystem` is blocked from becoming a ServerScriptService authority bypass.
- `SafeProfileStore` protects current-server SessionLock ownership for Load/Save/Refresh/Release and reconciles data at the persistence boundary.
- `PlayerService.RefreshSession()` serializes heartbeat refresh with Save/Remove through the common operation lock.
- `PlayerService.Load()` now has a per-UserId load-generation guard to prevent stale loads/rejoin races from mutating a newer session.
- Server shutdown now blocks new profile loads, tracks pending loads, waits for both load-drain and profile-removal completion, and retains a bounded shutdown timeout.
- `WorldDecor` is idempotent via readiness markers and bounded waits; `WorldTheme` deduplicates portal bindings and cleans player state.
- AI pathfinding uses finite-validated destinations, quantized cache keys, weak Model keys and bounded recomputation.

## Important open decisions / limitations
- No real Roblox Studio runtime playtest has been executed here.
- No Luau interpreter or Rojo CLI runtime validation is available here.
- The current head has no reported Combined Status checks and no PR-triggered workflow runs available through the connector; do not call CI green without an actual status result.
- Authored Roblox Animation/Sound assets are still absent; current VFX remain procedural/placeholder presentation.
- Movement/physics thresholds still require real Roblox Studio multiplayer validation, especially Dodge velocity, portal grace and network ownership interactions.
- TIDE/GALE currently unlock through level gates; the long-term design includes Mining, Digging, Bosses, Dungeons, World Events and Quests as future acquisition activities. Do not silently replace the chosen acquisition model.
- White Queen intro/story rules remain unchanged.

## Next technical direction
1. Continue concrete static audits and eliminate newly introduced authority/config drift.
2. Move to Roblox Studio multiplayer validation when executable runtime access is available.
3. Add authored EMBER Basic + Flame Burst animation/VFX/audio assets first, then repeat asset contracts for TIDE/GALE.
4. Keep gameplay authority in server systems; animation/VFX never decide damage, timing or rewards.
