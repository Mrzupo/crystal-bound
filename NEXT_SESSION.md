# Crystal Bound — Session Handoff

## Branch
- Branch: `agent/complete-crystal-bound-foundation`
- Base: `main`
- Current compare: **verify exact count with GitHub compare; branch remains ahead and 13 commits behind `main`**.
- `main` has not been merged/overwritten.

## Current state
The branch contains the complete Rojo project foundation plus the current gameplay stack. The repository is now in a **hardening + integration + combat presentation** phase rather than a blank-project phase.

The current master design context is authoritative: Crystal Bound is an original PvE-first open-world action RPG; the White Queen intro, first-loss setup, Ancient Crystal lore, Ancient-as-category (not rarity), Common→Divine rarity ladder, multiple-world long-term mystery, and no-Codex working mode must remain intact.

## Implemented systems
- PlayerData schema reconciliation and persistent SafeProfileStore
- Session lock + timeout + heartbeat + release on shutdown
- Autosave and save/remove race protection
- XP/level/economy/inventory
- Crystal system: EMBER, TIDE, GALE
- Crystal Mastery + upgrades
- Server-authoritative combat and hitboxes
- Critical hits
- Dodge with temporary ForceField invulnerability
- Burn/Slow status effects
- Enemy AI, pathfinding fallback, obstacle steering, jump waypoints
- Crystal Guardian + arena + phase 2 + telegraphed attack
- Quests, automatic quest chain, centralized quest completion/rewards
- Daily Bounty
- Achievements + Titles
- NPC dialogs for Keeper/Trader
- Shop + selling + Health Potion
- Crafting
- Inventory item rarities/drop chances
- Mobile/PC UI and controls
- World decoration/themes
- GitHub CI for Rojo mapping, JSON, require paths, gameplay references, remote references, profile migration IDs, balancing invariants and reviewed direct `TakeDamage()` paths
- CI guard ensuring `RemoteFunction.OnServerInvoke` ownership is unique
- CI guard ensuring critical RemoteEvent server ownership is unique
- Repo-wide direct damage audit that permits `Humanoid:TakeDamage()` only inside `DamageService`
- CI audit enforcing server-only `CombatFeedback` publication

## Important recent fixes
- `PlayerData` whitelists valid Titles and `UnlockedIslands` during reconciliation.
- `PlayerData.Reconcile()` now strips unknown crystal mastery keys instead of persisting phantom crystal data.
- Invalid equipped-crystal data is normalized to `EMBER`.
- `HitboxService` rejects invalid/negative/non-finite radius values.
- `CombatModifierService` finite-safely normalizes mastery level before critical calculation.
- `CombatService` has a small request-rate guard in addition to action cooldowns.
- `QuestRequest` now has a dedicated weak-key rate-limit gate in its single Bootstrap handler.
- `CRYSTAL_POWER` quest progression is now advanced with `QuestSystem.Advance()` on a real Ability use and only completes when its goal is reached; it is no longer blindly completed on every Ability hit.
- GALE splash damage goes through `DamageService.ProcessDamage()` rather than bypassing the central damage validator.
- Guardian shockwave NPC damage now also goes through `DamageService.ProcessDamage()` instead of a direct `Humanoid:TakeDamage()` path.
- Burn damage now goes through `DamageService.ProcessDamage()` for NPC targets instead of bypassing the central damage validator.
- `DodgeService` no longer directly calls `Humanoid:TakeDamage()`; its damage helper routes through `DamageService` and keeps backwards-compatible NPC/Boss callers using the explicit `Environmental` damage type when no source model is supplied.
- `DamageService` now accepts living Player characters as valid targets for server-side NPC/Boss damage while retaining Enemy/Boss target validation.
- `DamageService` now accepts only living Player or server-marked living Enemy/Boss models as attackers when an attacker is supplied.
- `DamageValidators` rejects missing attackers for every damage type except `Environmental`.
- `DamageValidators` rejects unknown `DamageType` values.
- Central damage types explicitly include `CrystalAbilitySplash` and `BossShockwave`.
- `DamageService` returns the actually applied HP delta instead of the requested amount.
- `DamageService` tracks the last valid attacker in server-only weak state; player attackers are stored by immutable UserId so a player death during a boss defeat race does not erase attribution.
- `BossService` uses the server-only damage attribution state for Guardian rewards and clears it on defeat.
- `CrystalSystem` now defensively rejects invalid IDs and malformed `profile.Crystals` data instead of throwing.
- Server-side procedural Crystal Combat VFX were removed from `CombatService`; the server no longer creates transient VFX Parts/Tweens for crystal hits.
- Added a dedicated `CombatFeedback` RemoteEvent for server-confirmed hit presentation.
- `CombatService` fires `CombatFeedback` only after `DamageService.ProcessDamage()` succeeds with applied damage and includes the verified target, attacker id, action, crystal id, critical state and applied damage amount.
- Dodge results with zero applied damage no longer produce confirmed-hit feedback or CRITICAL HIT messaging.
- `CombatPresentation.client.lua` consumes only the server-confirmed `CombatFeedback` event for damage numbers, hit flashes, impact visuals and crystal-specific ability accents.
- Confirmed-hit presentation is locally culled beyond 220 studs.
- NPC-side `LastHitCrystal` / `LastHitCritical` / `LastAttackerUserId` presentation attributes are no longer used by the combat presentation path.
- Added `combat-presentation-validation.yml` to guard the client/server presentation boundary, required mappings, authored asset naming contracts and the absence of client-side `TakeDamage()`.
- Added `damage-path-validation.yml` to explicitly protect reviewed Boss/Combat damage boundaries.
- Added `direct-damage-audit.yml` to reject any direct `Humanoid:TakeDamage()` call outside `DamageService` across the whole `src` tree.
- Added `feedback-authority-audit.yml` to ensure `CombatFeedback` is server-published only and has no server receive handler.
- `ClientBootstrap.client.lua` throttles Guardian BossBar work to a 0.1-second interval instead of doing the expensive BossBar lookup/update every rendered frame.
- `CooldownAuthority.client.lua` now polls the UI at 0.25 s while idle and 0.1 s only during an active ability cooldown, instead of a permanent 0.05 s loop.
- Added `CrystalAnimationConfig.lua` as presentation-only configuration for Basic/Ability animation asset IDs, asset names, VFX values and sound asset names for EMBER/TIDE/GALE.
- `CrystalAnimationController.client.lua` loads authored `Animation` objects from `ReplicatedStorage.Assets.Animations` by configured `AssetName` and safely falls back to `AnimationId`.
- `CrystalVFXController.client.lua` loads authored `Sound` objects from `ReplicatedStorage.Assets.Sounds` by configured `SoundAssetName` and safely falls back to `SoundId`.
- The animation controller handles character-generation/ancestry changes and clears stale tracks on respawn.
- Local animation playback is throttled using the existing crystal Basic/Ability cooldown values; this does not replace server cooldown validation.
- VFX playback has a small local presentation guard to avoid excessive local burst/sound allocation during input spam.
- Wired Basic/Q presentation animation + VFX on PC and mobile before the existing `CombatRequest`; these effects are cosmetic only.
- Registered the animation/VFX controllers, presentation config, asset folders and `CombatFeedback` remote mapping in `default.project.json`.
- `GetAvailableQuests` already has a dedicated 0.2-second RemoteFunction guard with PlayerRemoving cleanup.
- `QuestRequest` remains owned by the single Bootstrap handler; do not add a second handler.
- Shop, Crafting, Consumable and NPC dialog remotes have explicit request limits and the relevant server-side ownership/distance checks.
- Added `remote-event-ownership-validation.yml` to ensure critical RemoteEvents have exactly one server-side handler.

## Animation/VFX status
The animation architecture is in place, but the actual `Animation` objects and published IDs are still absent. The configured asset names are intentionally ready for future authored assets:
- `EMBER_Basic`, `EMBER_FlameBurst`
- `TIDE_Basic`, `TIDE_TidalPulse`
- `GALE_Basic`, `GALE_GaleStrike`

Therefore this is **not yet a claim of real in-game attack animations or final audio**. Missing assets safely fall back/no-op.

The VFX layer is deliberately placeholder-level: it provides immediate crystal identity without pretending to be final asset-based particles. The confirmed-hit presentation is explicitly client-side: the server validates damage and publishes only the verified result; the client turns that result into visuals. Animation timing still never determines damage authority.

## Quality assessment
- **Architecture:** strong for a prototype; server authority is clear and gameplay services are separated.
- **Persistence/security:** strong; profile locking, migration, validation and remote hardening are substantially covered.
- **Gameplay foundation:** broad and playable in design, including four islands, three crystals, enemies, quests, shop, crafting, bounty and a boss.
- **UI/UX:** functional foundation with PC + mobile paths, but still visually prototype-level.
- **Production readiness:** not ready yet. Runtime behavior still needs real Roblox Studio testing, animation/assets polish, and performance validation.

## Known limitations
- No real Roblox Studio runtime/playtest has been executed in this environment.
- No Luau interpreter is available here, so Luau syntax has only been statically/structurally reviewed, not executed.
- The latest commit has no reported combined status/workflow run available through the connected GitHub status endpoints in this session; do not call that CI-green.
- `src/ServerScriptService/StatusSpeedGuard.server.lua` may still physically exist as a legacy file, but it is not referenced by `default.project.json`.
- Actual Roblox animation and sound assets are not available yet.

## Exact next steps
1. Continue auditing `CrystalAnimationController.client.lua`, `CrystalVFXController.client.lua`, `CombatPresentation.client.lua`, `CombatService.lua`, `BossService.lua`, `StatusEffectService.lua` and final Rojo mapping.
2. Validate the combat-presentation, damage-path, direct-damage, feedback-authority and RemoteEvent-ownership CI contracts after subsequent changes.
3. Add the actual authored `Animation`/`Sound` objects under the configured asset names.
4. Create/publish the first real EMBER Basic + Flame Burst animation assets and wire them into the asset folders or IDs.
5. Add animation markers/events only for presentation timing; never use client markers as proof of damage.
6. Repeat the same presentation contract for TIDE and GALE.
7. Prepare the first Roblox Studio runtime/playtest and record actual combat/animation issues.

## Do not do
- Do not merge this branch into `main` yet.
- Do not create a second `OnServerInvoke` handler for an existing RemoteFunction.
- Do not reintroduce the legacy SaveSystem or legacy StatusSpeedGuard into Rojo.
- Do not claim runtime-tested or CI-green without a verified GitHub status.
- Do not change the White Queen intro, first-loss setup, Ancient Crystal lore, or the long-term secret second-world plan without explicit project-owner approval.
- Do not put gameplay authority into client animation markers.
- Do not recreate server-side cosmetic Part/Tween VFX in `CombatService`.

## Useful files
- `default.project.json`
- `TODO.md`
- `CHANGELOG.md`
- `NEXT_SESSION.md`
- `.github/workflows/project-validation.yml`
- `.github/workflows/remote-handler-validation.yml`
- `.github/workflows/remote-event-ownership-validation.yml`
- `.github/workflows/combat-presentation-validation.yml`
- `.github/workflows/damage-path-validation.yml`
- `.github/workflows/direct-damage-audit.yml`
- `.github/workflows/feedback-authority-audit.yml`
- `.github/workflows/remote-rate-limit-validation.yml`
- `src/ServerScriptService/Bootstrap.server.lua`
- `src/ServerScriptService/Services/CombatService.lua`
- `src/ServerScriptService/Services/DamageService.lua`
- `src/ServerScriptService/Services/DodgeService.lua`
- `src/ServerScriptService/Services/NPCService.lua`
- `src/ServerScriptService/Services/BossService.lua`
- `src/ServerScriptService/Services/PlayerService.lua`
- `src/ServerScriptService/CombatFeedbackRemote.server.lua`
- `src/ReplicatedStorage/Modules/PlayerData.lua`
- `src/ReplicatedStorage/Modules/CrystalSystem.lua`
- `src/ReplicatedStorage/Modules/CrystalMastery.lua`
- `src/ReplicatedStorage/Modules/QuestSystem.lua`
- `src/ReplicatedStorage/Config/CrystalConfig.lua`
- `src/ReplicatedStorage/Config/CrystalAnimationConfig.lua`
- `src/StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.lua`
- `src/StarterPlayer/StarterPlayerScripts/CrystalAnimationController.client.lua`
- `src/StarterPlayer/StarterPlayerScripts/CrystalVFXController.client.lua`
- `src/StarterPlayer/StarterPlayerScripts/CombatPresentation.client.lua`
- `src/StarterPlayer/StarterPlayerScripts/CooldownAuthority.client.lua`
