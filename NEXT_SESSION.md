# Crystal Bound — Session Handoff

## Branch
- Branch: `agent/complete-crystal-bound-foundation`
- Base: `main`
- Current compare: verify exact count with GitHub compare; branch remains ahead and 13 commits behind `main`.
- `main` has not been merged/overwritten.

## Current state
The branch contains the complete Rojo project foundation plus the current gameplay stack. The repository is in a **hardening + integration + combat presentation** phase rather than a blank-project phase.

The authoritative design context remains intact: PvE-first open-world action RPG; White Queen intro; first-loss setup; Ancient Crystal lore; Ancient as category, not rarity; Common → Divine rarity ladder; multiple-world long-term mystery; no-Codex working mode.

## Recent implementation work
- Server-authoritative combat remains centered on `CombatService` + `DamageService`.
- Crystal-specific server ability behavior is isolated in `CrystalAbilityService`.
- `CombatService` handles validation, cooldowns, damage orchestration, feedback, progression and rewards; `CrystalAbilityService` handles TIDE heal and GALE splash behavior.
- `CRYSTAL_POWER` progresses through `QuestSystem.Advance()` and only completes at its goal.
- GALE splash uses `DamageService.ProcessDamage()` and returns verified hit results to `CombatService` for feedback/rewards.
- Invalid equipped crystals normalize to `EMBER`; unknown crystal mastery keys are removed during profile reconciliation.
- `QuestRequest` has a dedicated weak-key rate limit inside the single Bootstrap handler.
- RemoteEvent ownership and direct-damage rules are protected by CI contracts.
- Server-confirmed `CombatFeedback` remains the sole authoritative source for hit presentation.
- Server-generated Crystal combat VFX remain removed; presentation is client-side.
- PC and mobile combat input defensively validate Enemy targets, living humanoids and local Crystal range before playing local presentation.
- PC and mobile Ability input both honor the server-provided `AbilityCooldownEnd` plus a local cooldown guard. These checks are only presentation/input throttles and do not replace server validation.
- `ClientBootstrap` uses `CrystalConfig.BasicAttack` (singular) and `CrystalConfig.Abilities` as defined by the config contract.
- `CrystalConfig.UnlockLevels` is now the single source of truth for EMBER/TIDE/GALE level gates; Bootstrap no longer owns a separate unlock-level table.
- `InventoryMenu` now consumes the shared `CrystalConfig.UnlockLevels` rather than a duplicated client unlock table.
- `CrystalMastery.Upgrade()` is now the central mastery-level mutation; Bootstrap no longer increments mastery directly.
- `crystal-config-validation.yml` protects the required UnlockLevels/BasicAttack/Abilities/Passives contract and prevents duplicate client/server unlock tables.
- `progression-boundary.yml` protects AchievementSystem checking, Daily Bounty one-time claiming, Enemy reward guards and Boss reward guards.
- `crystal-ability-boundary.yml` protects the server CrystalAbilityService boundary.
- `pve-attacker-context-validation.yml` now protects NPC/Boss/status-effect attacker context.
- NPC normal attacks and special attacks now carry the concrete NPC as attacker, use `Physical` damage and pass their real attack range; Emberling burn ticks preserve the NPC attacker context.
- Guardian normal attacks and telegraphs now preserve the Guardian attacker and use `Physical` / `BossShockwave` damage types with explicit ranges.
- `combat-validation-contract.yml` protects shared Hitbox/DamageService validation bounds.
- `boss-client-contract.yml` protects the `CrystalGuardian` model identity between server and client.
- `feedback-remote-direction-validation.yml` protects `CombatFeedback` as server-to-client only.
- `client-presentation-authority-validation.yml` protects client combat presentation from gameplay authority references.
- `presentation-asset-contract.yml` protects the six required Crystal animation/sound asset names.
- `QuestMenu` now has a local load debounce so rapid open/refresh cycles do not create overlapping quest RemoteFunction calls.
- AnimationController clears stale tracks on character generation changes and uses CrystalConfig cooldowns for local animation throttling.
- VFXController uses authored Sound assets when available, with safe ID fallbacks and short-lived cosmetic parts.
- Guardian BossBar work remains throttled to 0.1 s and currently resolves the server-spawned `CrystalGuardian` model name.
- Cooldown UI remains idle-throttled (0.25 s idle / 0.1 s active).

## Security / authority contracts
- `DamageService` is the only direct `Humanoid:TakeDamage()` path in `src`.
- `DamageService` validates attackers, targets, damage types, amount, range and dodge state.
- `DamageService` returns actual applied HP delta.
- Server-only weak-state attacker attribution uses immutable UserIds for player attackers.
- Environmental damage is the only attacker-less damage type.
- `CombatFeedback` is server-published only.
- Critical RemoteFunctions have unique `OnServerInvoke` ownership.
- Critical RemoteEvents have unique server handler ownership.
- Shop/Crafting/Consumable/Dodge/Quest/NPC remotes have request limits and relevant validation.

## Quality / limitations
- No real Roblox Studio runtime playtest has been executed in this environment.
- No Luau interpreter is available here; validation is static/structural.
- Latest GitHub combined status currently returns no statuses for the working commit; do not call CI green without a verified run.
- Actual authored Roblox Animation/Sound assets are still absent.
- Presentation VFX are still placeholder-level.
- `StatusSpeedGuard.server.lua` may physically exist but is not referenced by Rojo.
- `ClientBootstrap` was recently simplified while fixing the Guardian model-name lookup; combat/input/remote behavior remains present, but the HUD layout differs from the older parent version and should be reviewed during Studio playtest.

## Exact next steps
1. Continue static auditing of `CrystalAnimationController`, `CrystalVFXController`, `CombatPresentation`, `CombatService`, `CrystalAbilityService`, `BossService`, `StatusEffectService`, `NPCService` and `default.project.json`.
2. Verify all combat/damage/feedback/remote/progression/presentation CI contracts after further edits.
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
