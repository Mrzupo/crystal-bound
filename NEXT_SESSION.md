# Crystal Bound — Session Handoff

## Branch
- Branch: `agent/complete-crystal-bound-foundation`
- Base: `main`
- Current compare: verify with GitHub compare before continuing.
- `main` remains untouched by this workstream.

## Current state
The branch contains the complete Rojo project foundation plus the current gameplay stack and is in the hardening + integration phase ahead of real Roblox Studio runtime verification.

Authoritative design context remains intact: PvE-first open-world action RPG; White Queen intro; first-loss setup; Ancient Crystal lore; Ancient as category, not rarity; Common → Divine rarity ladder; multiple-world long-term mystery; no-Codex working mode.

## Major verified systems
- Server-authoritative `CombatService` + `DamageService`.
- Canonical `CrystalConfig` + `CrystalSystem` + `CrystalMastery`.
- TIDE/GALE level gates enforced inside `CrystalSystem.Unlock()` as well as request-layer checks.
- Central QuestSystem / QuestService completion and rewards.
- SafeProfileStore session lock with active per-player tokens, callback-local retry-state isolation, callback-time save snapshots and profile-revision save settling.
- Canonical Economy, Inventory, Shop, Crafting and Consumables with validation, rate limits and rollback.
- Shop and Crafting explicitly roll back partial inventory insertion before reversing a failed transaction.
- Crystal Mastery upgrade transactions verify each material removal and roll back partial consumption or failed upgrades.
- Enemy AI, Pathfinding, status effects and lifecycle cleanup.
- Enemy and Guardian respawns are suppressed once global server shutdown begins.
- Guardian Arena hazard damage and its periodic loop stop on global shutdown.
- Status-effect application and delayed Burn/Slow callbacks stop on global shutdown.
- Guardian phase system, arena hazard and exact-instance-bound telegraphs.
- Daily Bounty canonicalized from config and safe around wallet caps.
- Daily Bounty reconcile additionally repairs corrupt persisted `Claimed=true` state when `Progress < Goal`.
- Achievement Titles derived from earned Achievement IDs; Achievement unlocks are idempotent and not blocked by wallet capacity.
- PC/Mobile controls and UI.
- Server-confirmed CombatFeedback presentation.
- Server-owned character Animator for client animation playback.
- One-shot confirmed Crystal VFX bridge.
- Server-enforced WalkSpeed baseline and Slow modifiers, with separate configurable position-authority cadence; movement enforcement stops during shutdown.
- Portal cooldown expiry is generation-safe across respawn/rejoin; WorldTheme portal state monitoring also stops during shutdown.
- NPC menu state is Character-bound and cleared on respawn/leave.

## Latest hardening work
- Bootstrap is the single startup profile-load owner: canonical `PlayerAdded` handler plus explicit loading of players already present after startup, with per-Player deduplication.
- Redundant `PlayerLoadCatchup.server.lua` was removed from the repository and Rojo tree to avoid two concurrent startup load owners.
- `PlayerService.Load()` uses a per-UserId in-flight guard: a second concurrent load for the same UserId is rejected until the current load finishes. Do not describe this as a superseding-load implementation; the current runtime intentionally blocks the second load rather than taking over its lock.
- Every aborted successful load path releases the exact SessionLock token it acquired before returning.
- Bootstrap checks `player.Parent` before `Kick()` on load failure.
- `PlayerService` marks a player `Closing` before final removal work; external `GetProfile`/Sync/Save/Refresh/Heal paths reject closing players.
- `PlayerService.GetProfile()` also rejects ordinary gameplay access during `Saving` and global shutdown; final removal uses explicit internal save access.
- Shutdown uses `PlayerService.HasLoadedProfile()` so `BeginShutdown()` cannot hide profiles from the final Save/Release sweep.
- `PlayerService.Heal()` is the canonical player Health mutation owner; TIDE and Health Potion use it.
- `UseItemRemote` rolls the potion back if no health can actually be applied.
- `PlayerService.saveConsistently()` returns failure if all bounded revision-settle passes still detect profile changes, so AutosaveOk/LastSaveOk cannot falsely report a stale snapshot as consistent.
- Quest completion validates objective/reward data before committing state but no longer blocks valid quest completion on a full Money wallet; XP remains fully awarded and EconomyService caps Money.
- Achievement unlocks are one-shot/idempotent and no longer blocked by wallet capacity; EconomyService caps the Money reward.
- Daily Bounty requires full wallet capacity before payout because its claim is tied to a specific daily reward transaction and rolls progress back on payout failure.
- Persisted Daily Bounty corruption with `Claimed=true` before the Goal is now repaired during reconcile rather than leaving the bounty permanently unclaimable.
- Enemy and Guardian rewards preserve XP/Loot/quest progression when Money is capped; EconomyService alone caps Money.
- Guardian reward ownership is restricted by loaded-player, Closing and shutdown checks while preserving autosave-settle behavior.
- Shop purchase and inventory selling remain rollback-safe around Money and stack capacity; partial purchase insertion now explicitly rolls back inserted items before the Money refund.
- Crafting validates recipe/output bounds and now explicitly rolls back partial output insertion before restoring consumed inputs.
- Enemy delayed respawn callbacks check `PlayerService.ShuttingDown` so shutdown cannot create fresh NPC instances.
- Enemy AI loops stop on global shutdown.
- Guardian creation and AI stop on global shutdown, and the delayed Guardian respawn callback also checks the shutdown state.
- Guardian Arena hazard loop stops and disables active hazard visuals on global shutdown.
- `StatusEffectService` now rejects new effects during shutdown and aborts delayed Burn/Slow callbacks at their next lifecycle boundary.
- `EnemyConfig.Get()` returns a detached recursive config clone and centrally normalizes Respawn.
- Enemy Mastery XP is derived from canonical Enemy XP with no arbitrary minimum fallback.
- `StatusSpeedGuardV2` runs separate speed and position-enforcement cadences and rejects stale Character deferred binds.
- `StatusEffectService` restores Slow expiry speed with the same canonical `MaxWalkSpeedBonus` cap used by PlayerService/MovementConfig.
- Missing Humanoid/RootPart resets movement position state; portal grace is Character-bound and clears through centralized `WorldTheme` state cleanup on respawn/leave.
- Dodge invulnerability end tasks use per-player tokens and `ApplyDamage()` requires the current Player Character Humanoid.
- CharacterAdded health binding checks exact Character identity before/after Humanoid acquisition.
- Guardian telegraph windups are bound to the original Guardian and original target Character instances.
- AI pathfinding revalidates NPC liveness after yielded `ComputeAsync()` work.
- `PlayerData.Reconcile()` uses canonical `CrystalSystem.Exists()` validity, finite/integer progression thresholds, canonical Achievement title validation, quest prerequisite repair, daily-bounty definition repair and persistent-stat bounds.
- `CrystalMastery` mutation/read paths require actual Crystal ownership instead of relying only on Remote-layer checks.
- CrystalConfig completeness is contract-checked across Definition, UnlockLevel, BasicAttack, Ability and Passive sources.
- Inventory UI and server responses use detached `InventoryService.GetInventory()` snapshots; `InventoryRequest` is Client → Server and `InventoryChanged` is Server → Client.
- NPC dialog/config snapshots are detached and server-distance gated.
- RemoteFunction contracts require a single server owner per named RemoteFunction, and critical RemoteEvent contracts require a single server handler.
- PvE damage contracts require exact NPC model identity under `Workspace.NPCs`; stale descendant-only assumptions were removed from the attacker/target contract.

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
- Current GitHub workflow-run queries provide no verified run for the latest hardening commits; CI must not be called green.
- Movement/physics thresholds still require real Roblox multiplayer validation, especially Dodge velocity, portal grace, portal cooldown generation handling, movement/status-effect shutdown and Roblox network-ownership interactions.
- The generalized `PlayerService.Saving` gameplay-read gate remains intentionally conservative. Ordinary `GetProfile()` callers are blocked during autosave; selected server reward paths have explicit autosave-safe access and are covered by settle/revision behavior.
- `GetPlayerData`/`GetQuestData` return detached server-serialized subsets; no server-side table reference crosses the network boundary.
- Authored Roblox Animation/Sound assets are still pending; current VFX remain procedural/placeholder-level.
- TIDE/GALE currently use level-gated prototype unlocks while the long-term design lists Mining, Digging, Bosses, Dungeons, World Events and Quests as future Crystal acquisition activities.
- Story remains fixed: White Queen, first loss, unknown world, Ancient Crystal lore, multiple future worlds and delayed second-world reveal.

## Next steps
1. Continue concrete static audits and eliminate newly introduced authority/config drift.
2. Move to Roblox Studio multiplayer validation when executable runtime access is available.
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
