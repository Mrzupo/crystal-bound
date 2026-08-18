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
- `QuestRequest` has a dedicated weak-key rate limit inside the single Bootstrap handler.
- `GetPlayerData` and `GetQuestData` now also have dedicated weak-key server rate limits and PlayerRemoving cleanup.
- RemoteEvent and RemoteFunction ownership/direction rules are protected by CI contracts.
- Server-confirmed `CombatFeedback` remains the sole authoritative source for hit presentation.
- Server-generated Crystal combat VFX remain removed; presentation is client-side.
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
- Shop, Crafting and Health Potion transactions validate before mutation and protect their mutation paths with server rate limits; Crafting and Shop roll back failed final mutations.
- Economy sell accounting now reports the **actual** Money delta after MaxMoney clamping rather than the requested sale value.
- `StatusSpeedGuardV2` now tracks and disconnects per-player event connections on Leave/Respawn, removing a connection leak.
- Persistence reconciliation clamps Level/XP/Money/Inventory/Crystal ownership/mastery/quest state, while `SafeProfileStore` atomically claims and refreshes `SessionLock` ownership.
- SessionLock age now clamps future timestamps to avoid clock-skew extending a lock incorrectly.
- Daily Bounty and Achievement rewards are idempotent and now have explicit reward contracts.
- `QuestHUDPresenter.client.lua` presents server-structured quest state and is now event-driven rather than polling once per second; `QuestMenu` has a local load debounce.
- `StatusMessages.client.lua` now preserves high-priority messages when the HUD overflows.
- `default.project.json` now identifies the DataModel as `Crystal Bound` and includes all current controllers/services/assets.
- `InventoryConfig` now defines the official `Common → Uncommon → Rare → Epic → Legendary → Mythic → Divine` rarity ladder; `Ancient` remains outside rarity semantics.
- WorldDecor/WorldTheme are one-shot/idempotent initialization scripts; portal level gates are protected by a WorldConfig/Bootstrap contract.
- Enemy death cleanup, AI termination, status cleanup and respawn callback behavior are protected by a dedicated lifecycle contract.
- The legacy `StatusSpeedGuard.server.lua` duplicate was removed; `StatusSpeedGuardV2.server.lua` is the sole runtime implementation.
- Studio testing is documented in `STUDIO_PLAYTEST.md` and now covers Consumables, World initialization, Boss Phase 2, Enemy lifecycle and HUD regressions.

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
- Quest completion, reward idempotency, persistence session locks, status-effect bounds, Dodge bounds, transaction rollback, enemy config, progression config, rarity semantics, world initialization, portal levels, enemy lifecycle, player-health sync and project identity are protected by dedicated CI workflows.

## Quality / limitations
- No real Roblox Studio runtime playtest has been executed in this environment.
- No Luau interpreter is available here; validation is static/structural.
- Current GitHub Actions status may have no run yet for the latest commit; do not call CI green without a verified run.
- Actual authored Roblox Animation/Sound assets are still absent.
- Presentation VFX are still placeholder-level.
- `ClientBootstrap` was recently simplified while fixing the Guardian model-name lookup; the HUD layout should be reviewed during Studio playtest.

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
