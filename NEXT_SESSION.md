# Crystal Bound — Session Handoff

## Branch
- Branch: `agent/complete-crystal-bound-foundation`
- Base: `main`
- Current compare: **1317 commits ahead, 30 commits behind** `main` (verified with GitHub compare).
- Current compared main base: `4b72e6213dd764d1ab30eb8f425f9c107369642e`.

## Current state
The branch contains the complete Rojo project foundation plus the current gameplay stack and is in the hardening + integration phase ahead of real Roblox Studio runtime verification.

Authoritative design context remains intact: PvE-first open-world action RPG; White Queen intro; first-loss setup; Ancient Crystal lore; Ancient as category, not rarity; Common → Divine rarity ladder; multiple-world long-term mystery; no-Codex working mode.

## Major verified systems
- Server-authoritative `CombatService` + `DamageService`.
- Canonical `CrystalConfig` + `CrystalSystem` + `CrystalMastery`.
- TIDE/GALE level gates enforced inside `CrystalSystem.Unlock()` as well as request-layer checks.
- Central QuestSystem / QuestService completion and rewards.
- SafeProfileStore session lock, refresh heartbeat, autosave, callback-local retry state isolation, save snapshots, retries and corrupted-value protection.
- Economy, Inventory, Shop, Crafting and Consumables with validation, rate limits and rollback.
- Crystal Mastery upgrade transactions verify each material removal and roll back partial consumption or failed upgrades.
- Enemy AI, Pathfinding, status effects and lifecycle cleanup.
- Guardian phase system, arena hazard and exact-instance-bound telegraphs.
- Daily Bounty canonicalized from config even for existing same-day profiles and safe around wallet caps.
- Achievement Titles derived from earned Achievement IDs.
- PC/Mobile controls and UI.
- Server-confirmed CombatFeedback presentation.
- Server-owned character Animator for client animation playback.
- One-shot confirmed Crystal VFX bridge.
- Server-enforced WalkSpeed baseline and Slow modifiers, with immediate correction of property changes and separate configurable position-authority cadence.

## Latest hardening work
- Bootstrap is now the single startup profile-load owner: canonical `PlayerAdded` handler plus explicit loading of players already present after world initialization.
- Redundant `PlayerLoadCatchup.server.lua` was removed to avoid concurrent startup Load owners; the project no longer maps or references it.
- Bootstrap load failure handling checks `player.Parent` before calling `Kick()`.
- Enemy defeat rewards no longer reject the entire XP/Loot reward when the Money wallet is full; EconomyService alone caps Money.
- Guardian rewards use the same wallet-cap-safe semantics and never set `Rewarded` when no valid loaded player profile exists.
- Daily Bounty checks wallet capacity before payout and marks `Claimed` only after the complete reward is actually granted; failed payout restores progress to goal-1.
- Crafting validates multiplied output/input totals before inventory-space formatting or mutation, preventing malformed-config overflow paths.
- Shop purchases validate multiplication, affordability and stack capacity before mutation and roll back Money if inventory insertion unexpectedly fails.
- Inventory selling now checks wallet capacity before consuming inventory and rolls both Money and inventory back on unexpected partial payout, closing the full-wallet sale replay exploit.
- Inventory UI and server responses use detached `InventoryService.GetInventory()` snapshots; `InventoryRequest` is Client → Server and `InventoryChanged` is Server → Client.
- Player Health is centralized through `PlayerService.Heal()`; Tide and Health Potion healing route through it, and Potion consumption rolls back if no healing is applied.
- Health authority CI now rejects direct Player Health/MaxHealth writes outside PlayerService while allowing NPC/Boss health initialization.
- `EnemyConfig.Get()` returns a detached recursive config clone and clamps Respawn into the 1.5..600 second runtime range.
- `StatusSpeedGuardV2` now has separate loops: WalkSpeed refresh at 0.25 s and position enforcement at the configured `MovementConfig.PositionCheckInterval` (currently 0.15 s).
- Missing Humanoid/RootPart resets movement position state so stale `sampleDt` cannot inflate teleport tolerance.
- Dodge invulnerability end tasks use per-player tokens, preventing stale delayed callbacks from cancelling a newer dodge after re-dodge or respawn.
- CharacterAdded health binding checks the exact Character instance before/after yielding for the Humanoid, preventing stale-respawn bindings.
- Guardian telegraph impacts are bound to the original Character instance, preventing an old windup from damaging a freshly respawned Character.
- AI pathfinding revalidates the NPC after yielded `ComputeAsync()` work before publishing the result.
- `SafeProfileStore` resets Load/Save/Refresh/Release success flags on every `UpdateAsync` callback invocation as well as before outer retries, preventing stale callback state after internal datastore retries.
- Menu/dialog contracts explicitly treat `INVENTORY` as the combined `OpenCrystalMenu` inventory+crystals menu alias.

## Security / authority rules
- `DamageService` is the only direct `Humanoid:TakeDamage()` owner.
- Player Health changes are owned by PlayerService; NPCService/BossService only initialize NPC health.
- Known DamageTypes only; positive finite damage and bounded ranges only.
- PvP damage blocked in current PvE-first combat path.
- Client cannot authoritatively grant Crystals, items, Money, XP, damage or quest completion.
- Server derives and enforces WalkSpeed; local movement presentation cannot become authoritative speed.
- Animation/VFX never decide gameplay.
- Critical RemoteFunctions have single `OnServerInvoke` ownership.
- Important Remotes are rate-limited and per-player cleanup is contract-checked.

## Open decisions / limitations
- No actual Roblox Studio runtime playtest has been executed here.
- No Luau interpreter or Rojo CLI runtime validation is available here.
- Latest commit workflow-run/Combined Status queries provide no verified CI run/status; do not call CI green without actual evidence.
- Authored Roblox Animation/Sound assets are still missing; current VFX remain procedural/placeholder-level.
- Movement/physics thresholds still require real Roblox Studio multiplayer validation, especially Dodge velocity, portal grace and Roblox network-ownership interactions.
- TIDE/GALE currently use level-gated prototype unlocks while the long-term design lists Mining, Digging, Bosses, Dungeons, World Events and Quests as acquisition activities; decide the final model before building acquisition content.
- Story remains fixed: White Queen, first loss, unknown world, Ancient Crystal lore, multiple future worlds and delayed second-world reveal.

## Next steps
1. Continue concrete static audits where risk remains.
2. Move toward Roblox Studio multiplayer validation.
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
