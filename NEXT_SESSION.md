# Crystal Bound — Session Handoff

## Branch
- Branch: `agent/complete-crystal-bound-foundation`
- Base: `main`
- Current compare: verify exact count with GitHub compare; branch remains ahead and diverged from `main`.
- `main` has not been merged/overwritten.

## Current state
The branch contains the complete Rojo project foundation plus the current gameplay stack. The repository is in a **hardening + integration + combat presentation** phase rather than a blank-project phase.

The authoritative design context remains intact: PvE-first open-world action RPG; White Queen intro; first-loss setup; Ancient Crystal lore; Ancient as category, not rarity; Common → Divine rarity ladder; multiple-world long-term mystery; no-Codex working mode.

## Recent implementation work
- Server-authoritative combat remains centered on `CombatService` + `DamageService`.
- Crystal-specific server ability behavior is isolated in `CrystalAbilityService`.
- `CombatService` handles validation, cooldowns, damage orchestration, feedback, progression and rewards; `CrystalAbilityService` handles TIDE heal and GALE splash behavior.
- `CRYSTAL_POWER` progresses through `QuestSystem.Advance()` and only completes at its goal.
- `GALE` splash uses `DamageService.ProcessDamage()` and returns verified hit results to `CombatService` for feedback/rewards.
- Invalid equipped crystals normalize to `EMBER`; unknown crystal mastery keys are removed during profile reconciliation.
- `CrystalSystem` and `CrystalMastery` now use the canonical `CrystalConfig` instead of removed legacy Crystal definition modules.
- `CrystalConfig.Definitions`, `UnlockLevels`, `BasicAttack`, `Abilities` and `Passives` are now the canonical Crystal data sources.
- `CrystalMastery` uses the canonical `CrystalUpgradeConfig` caps and rejects malformed mastery cost definitions instead of silently inventing a minimum cost.
- `CrystalUpgradeConfig` now exposes `MaxExperience` and its CI contract validates MaxLevel, MaxExperience and all three positive base costs.
- `QuestSystem` now owns the canonical quest chain order through `GetChainOrder()`; `QuestService` no longer maintains a second order list.
- `QuestRequest` has a dedicated weak-key rate limit inside the single Bootstrap handler.
- `GetPlayerData` and `GetQuestData` now also have dedicated weak-key server rate limits and PlayerRemoving cleanup.
- RemoteEvent and RemoteFunction ownership/direction rules are protected by CI contracts.
- Server-confirmed `CombatFeedback` remains the sole authoritative source for hit presentation.
- PC and mobile combat input defensively validate Enemy targets, living humanoids and local Crystal range before playing local presentation.
- PC and mobile Ability input both honor the server-provided `AbilityCooldownEnd` plus a local cooldown guard. These checks are only presentation/input throttles and do not replace server validation.
- `ClientBootstrap` uses `CrystalConfig.BasicAttack` and `CrystalConfig.Abilities` as defined by the config contract.
- `CrystalConfig.UnlockLevels` is the single source of truth for EMBER/TIDE/GALE level gates; `InventoryMenu` also consumes the shared table.
- `CrystalMastery.Upgrade()` is the central mastery-level mutation.
- `QuestService.Complete()` now requires objective progress to reach the quest goal, except for the two explicit server-triggered one-step quests `FIRST_FIGHT` and `GUARDIAN_TRIAL`.
- NPC normal attacks and special attacks carry the concrete NPC as attacker, use `Physical` damage and pass their real attack range; Emberling burn ticks preserve NPC attacker context.
- Guardian normal attacks and telegraphs preserve the Guardian attacker and use `Physical` / `BossShockwave` damage types with explicit ranges.
- `CrystalAbilityService` defensively validates player/target instances plus finite/clamped damage and range inputs before executing server abilities.
- Status effects have bounded Slow/Burn duration, tick count, damage and interval; tokenized callbacks prevent stale effect cleanup from cancelling newer effects.
- Dodge validates finite vectors, resets on respawn, cleans state on leave and routes actual damage through `DamageService`.
- `DodgeService.ApplyDamage()` now requires an explicit positive range for non-environmental attacker damage; the old 1000-stud fallback is restricted away from PvE attackers.
- Central `DamageValidators` now requires an explicit known `DamageType`; ambiguous nil-type damage requests are rejected.
- Shop, Crafting and Health Potion transactions validate before mutation and protect their mutation paths with server rate limits; Crafting and Shop roll back failed final mutations.
- Inventory amounts are now strictly positive for Add/Remove/Has; invalid non-positive amounts are rejected instead of becoming `+1`.
- Economy sell accounting now reports the **actual** Money delta after MaxMoney clamping rather than the requested sale value.
- Selling is now atomic: if the full sale value cannot be credited, the sold items are restored and the transaction fails.
- Daily Bounty completion messages now report the **actual** Money delta after MaxMoney clamping.
- `EconomyService.RemoveMoney()`, `CanAfford()` and `GetMoney()` now defensively normalize corrupted Money values.
- `StatusSpeedGuardV2` now tracks and disconnects per-player event connections on Leave/Respawn, removing a connection leak.
- Persistence reconciliation clamps Level/XP/Money/Inventory/Crystal ownership/mastery/quest state, while `SafeProfileStore` atomically claims and refreshes `SessionLock` ownership.
- `XPConfig.MaxExperience` is the canonical player XP cap and is consumed by `XPService` + `PlayerData.Reconcile()`.
- `CrystalUpgradeConfig.MaxExperience` is the canonical Crystal Mastery XP cap and is consumed by `CrystalMastery` + `PlayerData.Reconcile()`.
- SessionLock age now clamps future timestamps to avoid clock-skew extending a lock incorrectly.
- `SafeProfileStore.Save()` now snapshots the live profile **inside** the `UpdateAsync` callback, preventing stale pre-yield profile snapshots from overwriting mutations that occur during a DataStore save.
- Daily Bounty and Achievement rewards are idempotent and now have explicit reward contracts; Achievement reward money is paid once during `PlayerService.Sync()` when a new achievement is unlocked.
- Achievement definitions and Titles are canonical in `AchievementSystem`; `PlayerData` and `AchievementMenu` consume them instead of maintaining independent lists.
- `MASTER_OF_ONE` achievement text is derived from the configured mastery MaxLevel.
- `QuestMenu` uses structured server quest data and has a local load debounce; its `loadData()` callback scope bug was fixed with a local forward declaration.
- The duplicate Quest HUD presenter was removed; `ClientBootstrap` is now the sole Quest HUD presentation owner.
- `ClientBootstrap` renders structured `GetQuestData()` responses instead of the old `result.Text` shape.
- `StatusMessages.client.lua` now preserves high-priority messages when the HUD overflows.
- `default.project.json` now identifies the DataModel as `Crystal Bound` and no longer maps removed legacy Crystal registry/definition modules, the duplicate Quest HUD presenter, or root-level legacy runtime stubs.
- `CrystalAnimationConfig` has a complete six-entry presentation contract for EMBER/TIDE/GALE Basic/Ability actions, with asset/sound names and bounded presentation fields protected by CI.
- `CrystalAnimationController` local cooldowns are keyed by `Crystal + Action`, preventing a Crystal switch from inheriting the previous Crystal's local presentation cooldown.
- Unreferenced legacy Crystal modules (`CrystalDefinitions`, `CrystalTypes`, `CrystalUtils`, `BaseCrystal`, `AbilityRegistry`, `PassiveRegistry`) were removed; `CrystalAbilityService` is the active server ability layer.
- Obsolete root runtime stubs (`Bootstrap.server.lua`, `Constants.lua`, `Enums.lua`, `Utility.lua`) were removed because the project is now driven by the Rojo `src/` tree.
- WorldDecor/WorldTheme are one-shot/idempotent initialization scripts; portal level gates are protected by a WorldConfig/Bootstrap contract.
- Enemy death cleanup, AI termination, status cleanup and respawn callback behavior are protected by a dedicated lifecycle contract.
- The legacy `StatusSpeedGuard.server.lua` duplicate was removed; `StatusSpeedGuardV2.server.lua` is the sole runtime implementation.
- Shop and Crafting both consume shared server/UI configs; Shop UI and ClientBootstrap share the same `ShopConfig.SellOrder`.
- Inventory Rarity data is explicitly Common → Uncommon → Rare → Epic → Legendary → Mythic → Divine.
- The main project-validation workflow was corrected to validate all seven rarity levels instead of the obsolete five-level ladder.
- Studio testing is documented in `STUDIO_PLAYTEST.md` and covers Consumables, World initialization, Boss Phase 2, Enemy lifecycle and HUD regressions.

## Security / authority contracts
- `DamageService` is the only direct `Humanoid:TakeDamage()` path in `src`.
- `DamageService` validates attackers, targets, damage types, amount, range and dodge state.
- `DamageService` returns actual applied HP delta.
- Server-only weak-state attacker attribution uses immutable UserIds for player attackers.
- Environmental damage is the only attacker-less damage type; its explicit bypass is protected by CI.
- `CombatFeedback` is server-published only.
- Critical RemoteFunctions have unique `OnServerInvoke` ownership and server rate limits.
- Critical RemoteEvents have unique server handler ownership.
- Shop/Crafting/Consumable/Dodge/Quest/NPC remotes have request limits and relevant validation.
- Quest completion, reward idempotency, persistence session locks, persistence save-snapshot timing, status-effect bounds, Dodge bounds, PvE damage range, explicit damage types, transaction rollback, enemy config, progression config, rarity semantics, world initialization, portal levels, enemy lifecycle, player-health sync, project identity, presentation assets, legacy Crystal cleanup and root legacy cleanup are protected by dedicated CI workflows.

## Quality / limitations
- No real Roblox Studio runtime playtest has been executed in this environment.
- No Luau interpreter is available here; validation is static/structural.
- Current GitHub Actions status may have no run yet for the latest commit; do not call CI green without verified evidence.
- Actual authored Roblox Animation/Sound assets are still absent.
- Presentation VFX are still placeholder-level.
- `ClientBootstrap` HUD layout should be reviewed during Studio playtest.

## Exact next steps
1. Continue static auditing of `CombatService`, `CrystalAbilityService`, `BossService`, `StatusEffectService`, `NPCService`, menus and `default.project.json`.
2. Verify all combat/damage/feedback/remote/progression/presentation/persistence CI contracts after further edits.
3. Add authored Animation/Sound objects under the configured asset names.
4. Build the first real EMBER Basic + Flame Burst assets, then repeat for TIDE and GALE.
5. Keep animation markers presentation-only; never make them gameplay authority.
6. Prepare the first Roblox Studio runtime playtest and record actual issues.

## Do not do
- Do not merge into `main`.
- Do not add duplicate `OnServerInvoke` handlers.
- Do not reintroduce legacy SaveSystem or legacy StatusSpeedGuard into Rojo.
- Do not claim runtime-tested or CI-green without verified evidence.
- Do not change White Queen intro, first-loss setup, Ancient Crystal lore, Ancient category semantics, rarity ladder, or long-term second-world plan without explicit approval.
- Do not place gameplay authority into client animation markers.
- Do not recreate server-side cosmetic combat VFX in `CombatService`.
