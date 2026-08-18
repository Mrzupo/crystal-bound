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

## Important recent fixes
- `PlayerData` whitelists valid Titles and `UnlockedIslands` during reconciliation.
- `HitboxService` rejects invalid/negative/non-finite radius values.
- `CombatModifierService` finite-safely normalizes mastery level before critical calculation.
- `CombatService` has a small request-rate guard in addition to action cooldowns.
- `CombatService` only marks `LastHitCritical` after successful damage validation.
- `DailyBountyService` claim/progress is server-side and atomic within a single request.
- `QuestMenu` no longer replaces valid available-quest data with an empty table when the availability RemoteFunction is rate-limited.
- The temporary `DataQueryRateLimit.server.lua` was removed because it would compete with Bootstrap's `OnServerInvoke` handlers.
- `remote-handler-validation.yml` checks unique `OnServerInvoke` ownership.
- `StatusSpeedGuardV2` is the active Rojo speed guard; legacy V1 is not loaded by `default.project.json`.
- The old unsafe `SaveSystem.lua` is not loaded/used.
- `ClientBootstrap.client.lua` throttles Guardian BossBar work to a 0.1-second interval instead of doing the expensive BossBar lookup/update every rendered frame.
- Added `CrystalAnimationConfig.lua` as presentation-only configuration for Basic/Ability animation asset IDs for EMBER/TIDE/GALE.
- Added `CrystalAnimationController.client.lua`, which owns client-side `Animator`/`AnimationTrack` loading, priority, fade and playback.
- Wired Basic click and Q Ability input through `CrystalAnimationController` before the existing `CombatRequest`; server validation and damage authority were not changed.
- Added `CrystalVFXController.client.lua` for lightweight crystal-specific local combat bursts.
- VFX configuration now lives beside animation configuration, including optional sound IDs, presentation scale and offsets.
- Wired Basic/Q presentation VFX before the existing `CombatRequest`; these effects are cosmetic only and do not report hits or damage to the server.
- Registered the VFX controller in `default.project.json`.

## Animation/VFX status
The animation architecture is in place, but the asset IDs are intentionally empty until real Roblox animations are published. Therefore this is **not yet a claim of real in-game attack animations**. The controller safely no-ops when an ID is missing.

The VFX layer is deliberately placeholder-level: it provides immediate crystal identity without pretending to be final asset-based particles. The optional sound hooks also remain empty until authored Roblox assets exist.

Next presentation task is to create/publish the actual EMBER Basic + Flame Burst animations first, then TIDE and GALE. Keep asset IDs out of `CombatService` and never let animation timing determine server damage authority.

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
- Actual Roblox animation asset IDs are not available yet.

## Exact next steps
1. Audit the refined `CrystalVFXController.client.lua` and final Rojo mapping.
2. Add authored asset folders/lookup contracts for crystal VFX and sounds without moving gameplay authority client-side.
3. Create/publish the first real EMBER Basic + Flame Burst animation assets and wire their IDs into `CrystalAnimationConfig.lua`.
4. Add animation markers/events only for presentation timing; never use client markers as proof of damage.
5. Repeat the same presentation contract for TIDE and GALE.
6. Prepare the first Roblox Studio runtime/playtest and record actual combat/animation issues.

## Do not do
- Do not merge this branch into `main` yet.
- Do not create a second `OnServerInvoke` handler for an existing RemoteFunction.
- Do not reintroduce the legacy SaveSystem or legacy StatusSpeedGuard into Rojo.
- Do not claim runtime-tested or CI-green without a verified GitHub status.
- Do not change the White Queen intro, first-loss setup, Ancient Crystal lore, or the long-term secret second-world plan without explicit project-owner approval.
- Do not put gameplay authority into client animation markers.

## Useful files
- `default.project.json`
- `TODO.md`
- `CHANGELOG.md`
- `NEXT_SESSION.md`
- `.github/workflows/project-validation.yml`
- `.github/workflows/remote-handler-validation.yml`
- `src/ServerScriptService/Bootstrap.server.lua`
- `src/ServerScriptService/Services/CombatService.lua`
- `src/ServerScriptService/Services/PlayerService.lua`
- `src/ReplicatedStorage/Modules/PlayerData.lua`
- `src/ReplicatedStorage/Config/CrystalConfig.lua`
- `src/ReplicatedStorage/Config/CrystalAnimationConfig.lua`
- `src/StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.lua`
- `src/StarterPlayer/StarterPlayerScripts/CrystalAnimationController.client.lua`
- `src/StarterPlayer/StarterPlayerScripts/CrystalVFXController.client.lua`
- `src/StarterPlayer/StarterPlayerScripts/CombatPresentation.client.lua`
- `src/StarterPlayer/StarterPlayerScripts/CooldownAuthority.client.lua`
