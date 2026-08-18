# Crystal Bound — Session Handoff

## Branch
- Branch: `agent/complete-crystal-bound-foundation`
- Base: `main`
- Current compare: **408 commits ahead, 13 commits behind** `main`
- `main` has not been merged/overwritten.

## Current state
The branch contains the complete Rojo project foundation plus the current gameplay stack. The repository is now in a **hardening + integration** phase rather than a blank-project phase.

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

## Quality assessment
- **Architecture:** strong for a prototype; server authority is clear and gameplay services are separated.
- **Persistence/security:** strong; profile locking, migration, validation and remote hardening are substantially covered.
- **Gameplay foundation:** broad and playable in design, including four islands, three crystals, enemies, quests, shop, crafting, bounty and a boss.
- **UI/UX:** functional foundation with PC + mobile paths, but still visually prototype-level.
- **Production readiness:** not ready yet. Runtime behavior still needs real Roblox Studio testing, animation/assets polish, and performance validation.

## Known limitations
- No real Roblox Studio runtime/playtest has been executed in this environment.
- No Luau interpreter is available here, so Luau syntax has only been statically/structurally reviewed, not executed.
- GitHub Actions must be checked on the actual latest commit before claiming CI is green.
- `src/ServerScriptService/StatusSpeedGuard.server.lua` may still physically exist as a legacy file, but it is not referenced by `default.project.json`.
- `ClientBootstrap.client.lua` still updates the Guardian BossBar from `RenderStepped`; this is the next concrete performance fix.

## Exact next step
1. Re-check current branch compare and commit/status.
2. Fix the `ClientBootstrap` BossBar render loop: update on a small timed interval instead of every RenderStepped frame.
3. Re-check `CooldownAuthority.client.lua` and the main client HUD for duplicate render/update work.
4. Verify the unique RemoteFunction handler rule remains intact.
5. Then move to real attack/ability animation architecture.
6. After animation/VFX work, perform the first real Roblox Studio runtime/playtest and fix Output/runtime errors.

## Do not do
- Do not merge this branch into `main` yet.
- Do not create a second `OnServerInvoke` handler for an existing RemoteFunction.
- Do not reintroduce the legacy SaveSystem or legacy StatusSpeedGuard into Rojo.
- Do not claim runtime-tested or CI-green without a verified GitHub status.

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
- `src/StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.lua`
- `src/StarterPlayer/StarterPlayerScripts/CooldownAuthority.client.lua`
