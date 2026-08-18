# Crystal Bound — Session Handoff

## Branch
- Branch: `agent/complete-crystal-bound-foundation`
- Base: `main`
- Current compare: **410 commits ahead, 13 commits behind** `main`
- `main` has not been merged/overwritten.

## Current state
The branch contains the complete Rojo project foundation plus the current gameplay stack. The repository is now in a **hardening + integration** phase rather than a blank-project phase.

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
- `ClientBootstrap.client.lua` now throttles Guardian BossBar work to a 0.1-second interval instead of doing the expensive BossBar lookup/update every rendered frame.

## Quality assessment
- **Architecture:** strong for a prototype; server authority is clear and gameplay services are separated.
- **Persistence/security:** strong; profile locking, migration, validation and remote hardening are substantially covered.
- **Gameplay foundation:** broad and playable in design, including four islands, three crystals, enemies, quests, shop, crafting, bounty and a boss.
- **UI/UX:** functional foundation with PC + mobile paths, but still visually prototype-level.
- **Production readiness:** not ready yet. Runtime behavior still needs real Roblox Studio testing, animation/assets polish, and performance validation.

## Known limitations
- No real Roblox Studio runtime/playtest has been executed in this environment.
- No Luau interpreter is available here, so Luau syntax has only been statically/structurally reviewed, not executed.
- GitHub Actions must be checked on the actual latest commit before claiming CI is green; the current head has no reported status entries.
- `src/ServerScriptService/StatusSpeedGuard.server.lua` may still physically exist as a legacy file, but it is not referenced by `default.project.json`.

## Exact next step
1. Re-check current commit/status and RemoteFunction handler ownership.
2. Review `CooldownAuthority.client.lua` and the main client HUD for remaining duplicate render/update work.
3. Keep the combat pipeline server-authoritative while preparing the animation architecture.
4. Design the first real attack/ability animation layer for EMBER/TIDE/GALE without changing the established combat validation pipeline.
5. Then prepare asset-based VFX/particles and the first Roblox Studio runtime/playtest.

## Do not do
- Do not merge this branch into `main` yet.
- Do not create a second `OnServerInvoke` handler for an existing RemoteFunction.
- Do not reintroduce the legacy SaveSystem or legacy StatusSpeedGuard into Rojo.
- Do not claim runtime-tested or CI-green without a verified GitHub status.
- Do not change the White Queen intro, first-loss setup, Ancient Crystal lore, or the long-term secret second-world plan without explicit project-owner approval.

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
