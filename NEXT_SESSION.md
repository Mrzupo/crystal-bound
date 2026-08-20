# Crystal Bound — Session Handoff

## Branch
- Branch: `agent/complete-crystal-bound-foundation`
- Base: `main`
- Current compare: **1448 commits ahead, 38 commits behind** `main` (verified with GitHub compare).
- Current compared main base: `18f0f27fcbcb4fd6384f45ecd1d0632f9edad02d`.

## Current state
The branch contains the complete Rojo project foundation plus the current gameplay stack and is in the hardening + integration phase ahead of real Roblox Studio runtime verification.

Authoritative design context remains intact: PvE-first open-world action RPG; White Queen intro; first-loss setup; Ancient Crystal lore; Ancient as category, not rarity; Common → Divine rarity ladder; multiple-world long-term mystery; no-Codex working mode.

## Major verified systems
- Server-authoritative `CombatService` + `DamageService`.
- Canonical `CrystalConfig` + `CrystalSystem` + `CrystalMastery`.
- TIDE/GALE level gates enforced inside `CrystalSystem.Unlock()` as well as request-layer checks.
- Central QuestSystem / QuestService completion and rewards.
- SafeProfileStore session lock with active per-player tokens, separate per-load claim tokens, callback-local retry-state isolation, callback-time snapshots and profile-revision save settling.
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
- `PlayerService.Load()` uses a per-UserId generation token: a newer load supersedes an older load for the same UserId, and every superseded/aborted successful load releases the exact SessionLock token it acquired.
- Bootstrap checks `player.Parent` before `Kick()` on load failure.
- `PlayerService` marks a player `Closing` before final removal work; external `GetProfile`/Sync/Save/Refresh/Heal paths reject closing players.
- Shutdown now uses `PlayerService.HasLoadedProfile()` so `BeginShutdown()` cannot hide profiles from the final Save/Release sweep.
- `PlayerService.Heal()` is the canonical player Health mutation owner; TIDE and Health Potion use it.
- `UseItemRemote` rolls the potion back if no health can actually be applied.
- Health Authority CI allows direct Player Health writes only in PlayerService and NPC/Boss spawn-time health initialization.
- `PlayerService.saveConsistently()` returns failure if all bounded revision-settle passes still detect profile changes, so AutosaveOk/LastSaveOk cannot falsely report a stale snapshot as consistent.
- Quest completion validates objective/reward data before committing state but no longer blocks valid quest completion on a full Money wallet; XP remains fully awarded and EconomyService caps Money.
- Achievement unlocks are one-shot/idempotent and no longer blocked by wallet capacity; EconomyService caps the Money reward.
- Daily Bounty requires full wallet capacity before payout because its claim is tied to a specific daily reward transaction and rolls progress back on payout failure.
- Enemy and Guardian rewards preserve XP/Loot/quest progression when Money is capped; EconomyService alone caps Money.
- Guardian Rewarded state is only committed for a valid loaded player/profile and validated reward configuration.
- Shop purchase and inventory selling remain rollback-safe around Money and stack capacity.
- `EnemyConfig.Get()` returns a detached recursive config clone and centrally normalizes Respawn.
- Enemy Mastery XP is derived from canonical Enemy XP with no arbitrary minimum fallback.
- `StatusSpeedGuardV2` runs separate speed and position-enforcement cadences; `PositionCheckInterval` is currently 0.15 s.
- `StatusEffectService` restores Slow expiry speed with the same canonical `MaxWalkSpeedBonus` cap used by PlayerService/MovementConfig.
- Missing Humanoid/RootPart resets movement position state; portal grace is Character-bound and clears through centralized `WorldTheme.clearPortalState()` on respawn/leave.
- Dodge invulnerability end tasks use per-player tokens and `ApplyDamage()` requires the current Player Character Humanoid.
- CharacterAdded health binding checks exact Character identity before/after Humanoid acquisition.
- Guardian telegraph windups are bound to the original Guardian and original target Character instances.
- AI pathfinding revalidates NPC liveness after yielded `ComputeAsync()` work.
- `PlayerData.Reconcile()` uses canonical `CrystalSystem.Exists()` validity, finite/integer progression thresholds, canonical Achievement title validation, quest prerequisite repair, daily-bounty definition repair and persistent-stat bounds.
- `CrystalMastery` mutation/read paths require actual Crystal ownership instead of relying only on Remote-layer checks.
- CrystalConfig completeness is contract-checked across Definition, UnlockLevel, BasicAttack, Ability and Passive sources.
- Inventory UI and server responses use detached `InventoryService.GetInventory()` snapshots; `InventoryRequest` is Client → Server and `InventoryChanged` is Server → Client.
- `InventoryConfig.GetItemConfig()` now returns a detached item snapshot and has a dedicated config-snapshot contract.
- NPC dialog/config snapshots are detached and server-distance gated.
- RemoteFunction contracts now require a single server owner per named RemoteFunction, and critical RemoteEvent contracts require a single server handler.
- `STUDIO_PLAYTEST.md` contains explicit same-UserId superseded-load, player-leave-during-load and shutdown-race cases for real runtime validation.

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
- A concrete autosave gameplay race remains: current `PlayerService.Saving` blocks `GetProfile()` during an autosave, so an NPC/Boss death callback arriving during the save can lose its reward lookup. The intended fix is to allow gameplay profile reads during Save and settle the save on a full pre/post-profile snapshot. The larger PlayerService write was attempted but blocked by the repository tool, so this fix is **not applied yet**.
- `GetPlayerData`/`GetQuestData` return Roblox-serialized profile subsets; no server-side table reference crosses the network boundary.
- TIDE/GALE currently use level-gated prototype unlocks while the long-term design lists Mining, Digging, Bosses, Dungeons, World Events and Quests as acquisition activities; decide the final model before building acquisition content.
- Story remains fixed: White Queen, first loss, unknown world, Ancient Crystal lore, multiple future worlds and delayed second-world reveal.

## Next steps
1. Apply the pending autosave gameplay/save-settle fix when a safe repository write path is available.
2. Continue concrete static audits and eliminate newly introduced authority/config drift.
3. Move toward Roblox Studio multiplayer validation.
4. Add authored EMBER Basic + Flame Burst animation/VFX/audio assets first, then repeat the asset contract for TIDE/GALE.

## Do not do
- Do not merge, reset or force-update `main` from this workstream.
- Do not reintroduce legacy SaveSystem or legacy Crystal registries.
- Do not add duplicate `OnServerInvoke` handlers.
- Do not call CI green without verified evidence.
- Do not rewrite the fixed story.
- Do not treat Ancient as a rarity.
- Do not develop the second world early.
