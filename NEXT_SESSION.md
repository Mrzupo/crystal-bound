# Crystal Bound — Session Handoff

## Branch
- Branch: `agent/complete-crystal-bound-foundation`
- Base: `main`
- Current compare: **778 commits ahead, 28 commits behind** `main` (verified with GitHub compare).
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
- `CrystalUpgradeConfig` exposes `MaxExperience` and its CI contract validates MaxLevel, MaxExperience and all three positive base costs.
- `QuestSystem` owns the canonical quest chain order through `GetChainOrder()`; `QuestService` no longer maintains a second order list.
- `QuestRequest`, `GetPlayerData` and `GetQuestData` use dedicated weak-key server rate limits and PlayerRemoving cleanup.
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
- `DodgeService.ApplyDamage()` requires an explicit positive range for non-environmental attacker damage; the old 1000-stud fallback is restricted away from PvE attackers.
- Central `DamageValidators` requires an explicit known `DamageType`; ambiguous nil-type damage requests are rejected.
- Shop, Crafting and Health Potion transactions validate before mutation and protect their mutation paths with server rate limits; Crafting and Shop roll back failed final mutations.
- Inventory amounts are strictly positive for Add/Remove/Has; invalid non-positive amounts are rejected.
- Economy sell accounting reports the actual Money delta after MaxMoney clamping; selling is atomic with item rollback on failed credit.
- Daily Bounty completion messages report the actual Money delta after MaxMoney clamping.
- `StatusSpeedGuardV2` tracks and disconnects per-player event connections on Leave/Respawn.
- Persistence reconciliation clamps Level/XP/Money/Inventory/Crystal ownership/mastery/quest state, while `SafeProfileStore` atomically claims and refreshes `SessionLock` ownership.
- `XPConfig.MaxExperience` is the canonical player XP cap and is consumed by `XPService` + `PlayerData.Reconcile()`.
- `CrystalUpgradeConfig.MaxExperience` is the canonical Crystal Mastery XP cap and is consumed by `CrystalMastery` + `PlayerData.Reconcile()`.
- SessionLock age clamps future timestamps to avoid clock-skew extending a lock incorrectly.
- `SafeProfileStore.Save()` snapshots the live profile inside the `UpdateAsync` callback.
- Daily Bounty and Achievement rewards are idempotent; Achievement reward money is paid once during `PlayerService.Sync()` for newly unlocked achievements.
- Achievement definitions and Titles are canonical in `AchievementSystem`; `PlayerData` and `AchievementMenu` consume them.
- `MASTER_OF_ONE` text is derived from configured mastery MaxLevel.
- `QuestMenu` uses structured server quest data and local debouncing; the old scope bug was fixed.
- Duplicate Quest HUD presenter was removed; `ClientBootstrap` is the sole Quest HUD presentation owner.
- `StatusMessages.client.lua` preserves high-priority messages when the HUD overflows.
- `default.project.json` identifies the DataModel as `Crystal Bound` and no longer maps removed legacy Crystal modules or root runtime stubs.
- `CrystalAnimationConfig` has a six-entry presentation contract for EMBER/TIDE/GALE Basic/Ability actions.
- `CrystalAnimationController` local cooldowns are keyed by Crystal + Action.
- **Animation ownership fix:** the client animation controller no longer creates a local `Animator`. `PlayerService` now ensures the character has a server-owned `Animator` on initial character load, respawn and normal sync, so client-loaded player animations can replicate correctly.
- Unreferenced legacy Crystal modules were removed; `CrystalAbilityService` is the active server ability layer.
- WorldDecor/WorldTheme are one-shot/idempotent; portal gates use central WorldConfig.
- Enemy lifecycle, AI cleanup, status cleanup and respawn callback behavior are protected by contracts.
- The legacy StatusSpeedGuard duplicate was removed; V2 is the sole runtime implementation.
- Shop and Crafting both consume shared server/UI configs.
- Inventory Rarity data is Common → Uncommon → Rare → Epic → Legendary → Mythic → Divine.
- Project validation was corrected to validate the full seven-level rarity ladder.
- `STUDIO_PLAYTEST.md` documents the end-to-end manual test plan.

## Security / authority contracts
- `DamageService` is the only direct `Humanoid:TakeDamage()` path in `src`.
- `DamageService` validates attackers, targets, damage types, amount, range and dodge state.
- `DamageService` returns actual applied HP delta.
- Environmental damage is the only attacker-less damage type.
- `CombatFeedback` is server-published only.
- Critical RemoteFunctions have unique `OnServerInvoke` ownership and server rate limits.
- Critical RemoteEvents have unique server handler ownership.
- Shop/Crafting/Consumable/Dodge/Quest/NPC remotes have request limits and relevant validation.
- Quest completion, reward idempotency, persistence session locks, persistence save-snapshot timing, status-effect bounds, Dodge bounds, PvE damage range, explicit damage types, transaction rollback, enemy config, progression config, rarity semantics, world initialization, portal levels, enemy lifecycle, player-health sync, project identity, presentation assets, legacy Crystal cleanup and root legacy cleanup are protected by dedicated CI workflows.

## Quality / limitations
- No real Roblox Studio runtime playtest has been executed in this environment.
- No Luau interpreter is available here; validation is static/structural.
- The latest commit currently has **no verified Combined Status checks** available through the connector; do not call CI green without a verified status.
- The Actions run helper available here only exposes PR-triggered workflow runs, so absence from that helper is not proof that push-triggered CI never ran.
- Actual authored Roblox Animation/Sound assets are still absent.
- Presentation VFX are still placeholder-level.
- `ClientBootstrap` HUD layout should be reviewed during Studio playtest.

## Exact next steps
1. Continue static auditing of `CombatService`, `CrystalAbilityService`, `BossService`, `StatusEffectService`, `NPCService`, menus and `default.project.json`.
2. Verify combat/damage/feedback/remote/progression/presentation/persistence contracts after further edits.
3. Add authored Animation/Sound objects under the configured asset names.
4. Build the first real EMBER Basic + Flame Burst assets, then repeat for TIDE and GALE.
5. Keep animation markers presentation-only; never make them gameplay authority.
6. Prepare the first Roblox Studio runtime playtest and record actual Output/runtime issues.

## Do not do
- Do not merge into `main`.
- Do not add duplicate `OnServerInvoke` handlers.
- Do not reintroduce legacy SaveSystem or legacy StatusSpeedGuard into Rojo.
- Do not claim runtime-tested or CI-green without verified evidence.
- Do not change White Queen intro, first-loss setup, Ancient Crystal lore, Ancient category semantics, rarity ladder, or long-term second-world plan without explicit approval.
- Do not place gameplay authority into client animation markers.
- Do not recreate server-side cosmetic combat VFX in `CombatService`.
