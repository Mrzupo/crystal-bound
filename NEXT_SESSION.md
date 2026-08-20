# Crystal Bound — Session Handoff

## Branch
- Branch: `agent/complete-crystal-bound-foundation`
- Base: `main`
- Current compare: **1404 commits ahead, 30 commits behind** `main` (verified with GitHub compare).
- Current compared main base: `4b72e6213dd764d1ab30eb8f425f9c107369642e`.

## Current state
The branch contains the complete Rojo project foundation plus the current gameplay stack and is in the hardening + integration phase ahead of real Roblox Studio runtime verification.

Authoritative design context remains intact: PvE-first open-world action RPG; White Queen intro; first-loss setup; Ancient Crystal lore; Ancient as category, not rarity; Common → Divine rarity ladder; multiple-world long-term mystery; no-Codex working mode.

## Major verified systems
- Server-authoritative `CombatService` + `DamageService`.
- Canonical `CrystalConfig` + `CrystalSystem` + `CrystalMastery`.
- TIDE/GALE level gates enforced inside `CrystalSystem.Unlock()` as well as request-layer checks.
- Central QuestSystem / QuestService completion and rewards.
- SafeProfileStore session lock with per-player token, per-load token generation, callback-local retry state isolation, save snapshots and profile-revision settle passes.
- Canonical Economy, Inventory, Shop, Crafting and Consumables with validation, rate limits and rollback.
- Crystal Mastery upgrade transactions verify each material removal and roll back partial consumption or failed upgrades.
- Enemy AI, Pathfinding, status effects and lifecycle cleanup.
- Guardian phase system, arena hazard and exact-instance-bound telegraphs.
- Daily Bounty canonicalized from config and safe around wallet caps.
- Achievement Titles derived from earned Achievement IDs; Achievement unlocks are idempotent and not blocked by wallet capacity.
- PC/Mobile controls and UI.
- Server-confirmed CombatFeedback presentation.
- Server-owned character Animator for client animation playback.
- One-shot confirmed Crystal VFX bridge.
- Server-enforced WalkSpeed baseline and Slow modifiers, with separate configurable position-authority cadence.

## Latest hardening work
- Bootstrap is the single startup profile-load owner: canonical `PlayerAdded` handler plus explicit loading of players already present after world initialization, with per-Player deduplication.
- Redundant `PlayerLoadCatchup.server.lua` was removed from the repository and Rojo tree to avoid two concurrent startup load owners.
- `PlayerService.Load()` rejects a second simultaneous load for the same UserId before replacing `LoadingByUserId[userId]`.
- Bootstrap checks `player.Parent` before `Kick()` on load failure.
- Superseded successful profile loads release the exact per-load session token before returning.
- `PlayerService` marks a player `Closing` before final removal work; external `GetProfile`/Sync/Save/Refresh/Heal paths reject closing players.
- `PlayerService.Heal()` is the canonical player Health mutation owner; Tide and Health Potion use it.
- `UseItemRemote` rolls the potion back if no health can actually be applied.
- Health Authority CI allows direct Player Health writes only in PlayerService and NPC/Boss spawn-time health initialization.
- Quest completion validates objective/reward data before committing state but no longer blocks valid quest completion on a full Money wallet; XP remains fully awarded and EconomyService caps Money.
- Achievement unlocks are one-shot/idempotent and no longer blocked by wallet capacity; EconomyService caps the Money reward.
- Daily Bounty still requires full wallet capacity before payout because its claim is tied to a specific daily reward transaction and it rolls progress back on payout failure.
- Enemy and Guardian rewards preserve XP/Loot when Money is capped; Guardian additionally preflights the combined Boss + active Guardian Trial Money cap.
- Shop purchase and inventory selling remain rollback-safe around Money and stack capacity.
- `EnemyConfig.Get()` returns a detached recursive config clone and centrally normalizes Respawn.
- `StatusSpeedGuardV2` runs separate speed and position-enforcement cadences; `PositionCheckInterval` is currently 0.15 s.
- Missing Humanoid/RootPart resets movement position state; portal grace remains Character-bound.
- Dodge invulnerability end tasks use per-player tokens.
- CharacterAdded health binding checks exact Character identity before/after Humanoid acquisition.
- Guardian telegraph windups are bound to the original Guardian and original target Character instances.
- AI pathfinding revalidates NPC liveness after yielded `ComputeAsync()` work.
- Inventory UI and server responses use detached `InventoryService.GetInventory()` snapshots; `InventoryRequest` is Client → Server and `InventoryChanged` is Server → Client.
- NPC dialog/config snapshots are detached and server-distance gated.

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
- Latest Combined Status/workflow-run queries provide no verified CI run/status; do not call CI green without actual evidence.
- Authored Roblox Animation/Sound assets are still missing; current VFX remain procedural/placeholder-level.
- Movement/physics thresholds still require real Roblox Studio multiplayer validation, especially Dodge velocity, portal grace and Roblox network-ownership interactions.
- `GetPlayerData`/`GetQuestData` return Roblox-serialized profile subsets; no server-side table reference crosses the network boundary.
- TIDE/GALE currently use level-gated prototype unlocks while the long-term design lists Mining, Digging, Bosses, Dungeons, World Events and Quests as acquisition activities; decide the final model before building acquisition content.
- Story remains fixed: White Queen, first loss, unknown world, Ancient Crystal lore, multiple future worlds and delayed second-world reveal.

## Next steps
1. Continue concrete static audits and eliminate newly introduced authority/config drift.
2. Move toward Roblox Studio multiplayer validation.
3. Add authored EMBER Basic + Flame Burst animation/VFX/audio assets first, then repeat the asset contract for TIDE/GALE.
4. Keep gameplay authority in server systems; animation/VFX never decide damage, timing or rewards.

## Do not do
- Do not merge, reset or force-update `main` from this workstream.
- Do not reintroduce legacy SaveSystem or legacy Crystal registries.
- Do not add duplicate `OnServerInvoke` handlers.
- Do not call CI green without verified evidence.
- Do not rewrite the fixed story.
- Do not treat Ancient as a rarity.
- Do not develop the second world early.
