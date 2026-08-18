# Crystal Bound — Session Handoff

## Branch
- Branch: `agent/complete-crystal-bound-foundation`
- Base: `main`
- Current compare: **407 commits ahead, 13 commits behind** `main`
- `main` has not been merged/overwritten.

## What was completed
The branch now contains the full Rojo project structure plus the current gameplay foundation:

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
- CI guard ensuring `RemoteFunction.OnServerInvoke` ownership is unique for the query/dialog-style remotes

## Important recent fixes
- `PlayerData` now whitelists valid Titles and `UnlockedIslands` during reconciliation.
- `HitboxService` rejects invalid/negative/non-finite radius values.
- `CombatModifierService` finite-safely normalizes mastery level before critical calculation.
- `CombatService` has a small request-rate guard in addition to action cooldowns.
- `CombatService` only marks `LastHitCritical` after successful damage validation.
- `DailyBountyService` claim/progress is server-side and atomic within a single request.
- `QuestMenu` no longer replaces valid available-quest data with an empty table when the availability RemoteFunction is rate-limited.
- The temporary `DataQueryRateLimit.server.lua` was removed because it would compete with Bootstrap's `OnServerInvoke` handlers. Query handlers must have a single owner.
- `remote-handler-validation.yml` now checks unique `OnServerInvoke` ownership.
- `StatusSpeedGuardV2` is the active Rojo speed guard; legacy V1 is not loaded by `default.project.json`.
- The old unsafe `SaveSystem.lua` is not loaded/used.

## Known limitations
- No real Roblox Studio runtime/playtest has been executed in this environment.
- No Luau interpreter is available here, so Lua syntax has only been statically/structurally reviewed, not executed.
- GitHub Actions may not have produced a run for the latest branch head; do not claim CI is green without checking the commit status.
- `src/ServerScriptService/StatusSpeedGuard.server.lua` may still physically exist in the branch as a legacy file, but it is not referenced by `default.project.json`.

## Exact next step for the next session
**Do not start adding large new systems immediately.**

1. Re-check the current branch compare and commit status.
2. Inspect `ClientBootstrap.client.lua` and `CooldownAuthority.client.lua` for remaining duplicate UI/render loops.
3. Finish the BossBar optimization that was identified at the end of the previous session: `ClientBootstrap` currently refreshes boss HP on every `RenderStepped`; reduce this to a small timed interval without breaking responsiveness.
4. Re-check `GetPlayerData`/`GetQuestData` RemoteFunction handlers in Bootstrap and ensure the unique-handler CI still passes.
5. Only after those checks, move to the next gameplay milestone: real attack/ability animations, then asset-based VFX/particles, then Roblox Studio runtime testing.

## Do not do
- Do not merge this branch into `main` yet.
- Do not create a second `OnServerInvoke` handler for an existing RemoteFunction.
- Do not reintroduce the legacy SaveSystem or legacy StatusSpeedGuard into Rojo.
- Do not claim runtime-tested/CI-green without a verified GitHub status.

## Useful files to start from
- `default.project.json`
- `TODO.md`
- `CHANGELOG.md`
- `.github/workflows/project-validation.yml`
- `.github/workflows/remote-handler-validation.yml`
- `src/ServerScriptService/Bootstrap.server.lua`
- `src/ServerScriptService/Services/CombatService.lua`
- `src/ServerScriptService/Services/PlayerService.lua`
- `src/ReplicatedStorage/Modules/PlayerData.lua`
- `src/StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.lua`
- `src/StarterPlayer/StarterPlayerScripts/CooldownAuthority.client.lua`
