# Crystal Bound Engineering State

## Current Branch

`agent/complete-crystal-bound-foundation` (remote GitHub branch).

## Current Verified Commit

`fdfef785392dc72f3f114b7fb4724e8710bb98dd` — actual branch HEAD verified at the start of the Delayed Callbacks / Lifecycle Races audit on 2026-09-27. The production source in this commit matches the source baseline from `9f036b97108987076c840a82136776658fc5eca6`; intervening commits were documentation-only. This audit inspected repository content through GitHub; the local workspace was not used as source of truth.

## Project Status

Existing Roblox project; development is ongoing. The verified head includes foundation fixes and the semantic NPC-dialog contract adjustment. This is not a declaration that the project is complete or runtime-stable.

The Actions run set queried for this exact commit contained 158 workflow runs, of which 49 concluded as failures. Therefore CI is not wholly green. The failures include contract-script syntax/runtime errors and source-marker mismatches; a failed check is not by itself proof of a production defect. See Known Failed Contracts.

## Completed Audits

- **WorldDecor / Decor Ownership (static source review):** `src/ServerScriptService/WorldDecor.server.lua` tags generated parts and readiness markers with `CrystalBoundDecor = true`. However, `clearDecor` also deletes direct island children solely by a list of legacy names and removes its named readiness marker without checking ownership. Generic-name collisions can delete unrelated instances if that island is regenerated. This is a conditional destructive production bug; whether a conflicting instance exists in the saved place was not runtime-checked.
- **Persistence / Player Data (static source review):** `PlayerData.Reconcile` clamps and normalizes persisted fields. `SafeProfileStore` claims, refreshes, saves, and releases a session lock through `UpdateAsync`; save/release paths check the session token. `PlayerService` serializes per-player operations, tracks profile revisions during save settling, and refuses normal profile access while saving/closing. No DataStore runtime test was performed. On final save or release failure, the service reports failure and retains the lock, but removes in-memory profile state; unsaved in-memory progress cannot then be recovered by that server.
- **Rewards / Achievement Atomicity (static source review):** quest reward values are validated before quest completion, and BossService validates progression reward fields before setting its rewarded flag. Achievement checks mutate the achievement list before PlayerService credits its configured reward. These operations are synchronous and later persisted with the profile; there is no explicit rollback transaction if an unexpected runtime error interrupts the sequence. No such runtime error was observed. Money cap behavior can grant less than the configured amount.
- **GetPlayerData / Client Snapshot Semantics (static source review):** Bootstrap rate-limits the RemoteFunction, requires `ProfileLoaded`, selects a fixed set of profile fields, and returns a deep copy. `AchievementMenu.client.lua` is the only client script found that calls this remote. It protects refreshes against menu/character changes, but does not subscribe to achievement changes while already open; its displayed unlocked state can remain stale until the next refresh/reopen.
- **NPC Spawn / World Lifecycle (static source review):** Bootstrap repairs canonical islands/portals/spawn and canonical interaction NPCs. Enemy spawns use unique names, server attributes, and a death/respawn callback; NPCService reuses a live matching enemy and starts AI only once. On a unique-name collision with an invalid/unowned instance, NPCService destroys that instance. Bootstrap likewise destroys a same-name non-Model or malformed canonical NPC. These are conditional ownership risks if unrelated instances are placed in the reserved NPC folder. WorldDecor waits up to 30 seconds for each island; a missing island at timeout is skipped for that startup.
- **6. Delayed Callbacks / Lifecycle Races (static source review at `fdfef785392dc72f3f114b7fb4724e8710bb98dd`):** searched all 89 Lua/Luau files for task delays/spawns/defers/waits, legacy delay/spawn/wait, RunService frame events, connections, player lifecycle events, Humanoid death, and NPC respawn. No server Heartbeat/Stepped loop was found; client `ClientBootstrap` uses RenderStepped only for HUD refresh.
  - **A — conditional Production-Bug, player presentation state:** `PlayerService.bindHumanoid` connects HealthChanged, MaxHealth-changed, and Died callbacks. Their closures check player/humanoid Parent, but do not capture/check that `player.Character == humanoid.Parent`. Old Humanoid connections are disconnected when the replacement is later bound, after CharacterAdded's deferred/retry initialization. A stale or already-queued old Humanoid callback can therefore overwrite the new character's Health/MaxHealth attributes or set DeathMessage after respawn. This changes replicated UI attributes, not the profile/rewards. Minimal patch: capture the bound character and reject each callback unless it is still `player.Character`; disconnect old Humanoid connections as soon as CharacterAdded begins to narrow the gap.
  - **A — low-impact transient UI race:** `NPCMenuBridge.openDialog` defers setting OpenNPCDialog and checks player/profile/character identity, but not the NPC instance or a dialog generation. If the NPC/menu state changes before the defer runs, it can reopen a stale dialog attribute for the same character. `NPCDialogRemote` independently checks canonical NPC and proximity before returning options, so this does not bypass server authority or mutate rewards. Minimal hardening if desired: generation token and recheck the same canonical, nearby NPC in the deferred callback.
  - **B — robust status/dodge callbacks:** StatusEffectService's slow timeout uses per-effect token identity; burn loops recheck token, Humanoid parent/health, profile-loaded state, and server shutdown before each bounded tick. Dodge timeouts use per-player tokens, check player lifetime, and clear the ForceField only if the same Character remains current; respawn/removal invalidate the token.
  - **B — robust player/session callbacks:** PlayerService load work has per-UserId load tokens, exception-safe cleanup, current-load checks, Character identity checks, Closing/shutdown checks, and exact session-token release. Character sync retries are bounded and revalidate player/profile/Character after waits. Save/heartbeat/shutdown work is serialized per player and gated by shutdown/profile/session ownership. PlayerRemoving handlers clear the relevant per-player connections or cooldown/rate-limit state. The Humanoid attribute-listener exception is described above.
  - **B — robust NPC/boss lifecycle:** enemy AI loops are tied to their model/Humanoid lifetime and stop on model removal, death, or shutdown. Enemy death cleanup affects only the captured old model; delayed respawn checks shutdown and the captured NPC folder, then NPCService's unique-name path reuses a living same-type enemy instead of duplicating it. Boss reward logic runs synchronously in Died, has a Rewarded guard and live-profile check; delayed old-model removal targets only that instance, while respawn checks shutdown, parent lifetime, and that no same-name Guardian exists. Boss Telegraph windup rechecks exact Guardian identity, phase/health, player/profile/Closing state, and exact Character identity before damage. BossArena hazard cleanup captures only the old hazard instance; reactivation creates a new slot/instance.
  - **B — robust portal lifecycle:** WorldTheme cooldown callbacks compare per-player tokens; PlayerRemoving invalidates tokens and clears candidates. Deferred arrival work checks candidate Character, destination, expiry, ready-character identity, and current player Character. Character and ProfileLoaded connections are disconnected/reset per player.
  - **C — harmless delayed presentation/maintenance:** client VFX/message callbacks operate on their own temporary Instances and check Parent before cleanup; camera/health listeners use Character identity/generation guards. Quest/NPC/Achievement menu retries check open/request generation and Character state before applying responses. Some stale QuestMenu retries can cause an extra fresh request, but do not apply old data. Periodic NPC, boss, movement, and session loops are bounded by object/player membership or a shutdown flag. Quest completion and reward functions are synchronous; no delayed quest/reward mutation path was found.
  - **D — Contract/CI failures are separate:** current-HEAD Actions run `Player Health Connection Lifecycle` failed on a source signature marker expecting the older `bindCharacterWhenReady(player, character)` signature; that failure does not exercise the stale-Humanoid callback described above. `Status Effect Stale Callback Contract` crashed with `ValueError: substring not found`. `Status Speed Guard Lifecycle` and `Enemy Lifecycle Validation` failed implementation-specific marker checks despite current-Character validation and unique-name spawn idempotency in code. Treat these as contract/CI evidence, not runtime results.

## Completed Fixes

Verified in branch history and current source:

- `932b2678ae11f91f3236d9b24861da413ecf6c9f`: repaired missing closing braces in `default.project.json`.
- `16f3a4dcf7031bf23c841c191aec82ef762bd9e8`: added BasePart root guards in `CraftingRemote.server.lua` and `NPCDialogRemote.server.lua`.
- `e0bc567a979b87213a28b4f37080a4e115a0e787`: validated canonical NPC type, parent, and Interactable attribute in `Bootstrap.server.lua:isNearNPC`.
- `9f036b97108987076c840a82136776658fc5eca6`: changed only the NPC Dialog Config Contract to check the canonical `NPC_IDS` allowlist semantically. Production code was unchanged in that commit.

## Passing Contracts

Successful GitHub Actions runs associated with the verified commit:

- Remote Authority Hardening — run 36324027088.
- NPC Dialog Config Contract — run 36324026109.
- Bootstrap World Idempotency Contract — run 36324026268.
- World Initialization Validation — run 36324026173.
- NPC Unique Spawn Repair — run 36324026103.
- NPC Runtime Boundary — run 36324026989.
- Player Data Exposure Contract — run 36324027243.
- Achievement State Write Ownership — run 36324026706.
- Economy Reward Accounting — run 36324026723.
- Boss Death Reward Respawn Contract — run 36324026143.

Additional passing lifecycle-related runs queried at the audit-start HEAD `fdfef785392dc72f3f114b7fb4724e8710bb98dd`: Boss Lifecycle Hardening (36325095847), Status Effect Lifecycle Contract (36325095004), Player Health Sync Contract (36325094866), and Combat Profile Readiness Contract (36325094999). These are individual static GitHub Actions results, not an overall green CI result and not Roblox runtime evidence.

## Known Failed Contracts

GitHub Actions results queried for commit `9f036b97108987076c840a82136776658fc5eca6` on 2026-09-27 reported 49 failed runs among 158 runs. Relevant failures include:

- **Session Autosave Contract (36324027360):** embedded Python ended with an unterminated string literal.
- **Persistence Reconcile Contract (36324025977):** profile-reconcile step passed; later heartbeat subcheck ended with `NameError: name 'PY' is not defined`.
- **Quest Reward Config Contract (36324026097):** embedded Python ended with a syntax error.
- **Player Data Reconciliation Contract (36324026972):** expects an inline XP-clamp expression; current code calls the equivalent shared `capExperienceBelowNextLevel` helper.
- **Profile Store Session Contract (36324027317):** expected lock-check text does not match the current nested lock guard; actual code compares JobId and Token and rejects a non-owned, non-expired lock.
- **Player Load Lifecycle Contract (36324027415), Player Load Rejoin Race Contract (36324026179), Player Remove Release Contract (36324025933), Session Shutdown Contract (36324026077), and Session Heartbeat Ownership Contract (36324026155):** failed source-marker assertions. Several expect older names/signatures; their complete semantics have not all been independently checked.
- **Boss Reward Transaction Contract (36324027159):** expects an early-return spelling; production uses a positive `if validProgressionReward then` guarded block.
- **Combat Reward Contract (36324027362):** expects `model:IsDescendantOf(npcFolder)`; DamageService checks `instance.Parent == npcFolder`, which is a stricter direct-child check for the same NPC folder.
- **NPC Readiness and Spawn Idempotency Contract (36324026809):** expected a one-line return marker; NPCService uses a nested live-model/type/AIStarted validation.
- **Other failed runs in the same Actions snapshot:** Player Health Connection Lifecycle; Portal Level Contract; Guardian Creation Idempotency; Menu Attribute Contract; Crystal Bound RemoteEvent Ownership Validation; Daily Bounty Snapshot Contract; Crystal Upgrade Config Validation; Environmental Damage Validation; Boss Client Contract; Crystal Bound Combat Presentation Validation; Combat Validation Contract; Local Require Validation; Crystal Ability Input Validation; Crystal Bound Feedback Authority Audit; Enemy Config Validation; PvE Attacker Context Validation; Inventory Config Snapshot Contract; Crystal Config Contract; Interaction Config Validation; Boss Attack Contract; Inventory UI Remote Contract; Economy Config Validation; Enemy Lifecycle Validation; Status Speed Guard Lifecycle; Portal Target Consistency Contract; Security Authority Gate; Crystal Ability Context Contract; Crystal Bound Project Validation; Crystal Bound Remote Rate Limit Validation; AI Path Input Validation; Status Effect Stale Callback Contract; Quest Completion Ownership; Achievement Canonical Source Contract; Player Lifecycle Entrypoint Contract; Progression Config Validation; Crystal Config Completeness. These remain unclassified here.

A red static contract is not automatically a production bug. Contract/script errors are distinguished above where the Action log established them; remaining failures need individual source-versus-contract review.

Point-6-related current-HEAD runs: Player Health Connection Lifecycle (36325096406) failed only its old function-signature marker; Status Effect Stale Callback Contract (36325096087) failed inside its Python check with `ValueError: substring not found`; Status Speed Guard Lifecycle (36325095867) expected an inline character-check marker; Enemy Lifecycle Validation (36325096147) expected a Bootstrap duplicate guard while NPCService performs unique-name reuse; NPC Readiness and Spawn Idempotency Contract (36325096000) expected a one-line return marker. Boss Lifecycle Hardening and Status Effect Lifecycle Contract passed as listed above. No new test was run locally.

## Known Risks

1. **WorldDecor ownership:** `clearDecor` deletes unmarked direct children by generic names (`Rock`, `TreeTrunk`, `AncientCrystal`, and others) and deletes the readiness marker by name. A foreign same-name object can be destroyed during regeneration.
2. **NPC spawn ownership:** malformed or non-canonical same-name instances in the reserved NPC folder can be destroyed during repair/spawn.
3. **Reward rollback:** quest, achievement, and combat/boss reward state is not wrapped in a general rollback transaction if an unexpected error interrupts synchronous mutations. No interrupted reward was observed.
4. **Snapshot freshness:** an already-open Achievement Menu is not refreshed by achievement-state changes.
5. **Persistence failure at departure:** final save/release failure preserves the DataStore lock but discards the server's in-memory profile during cleanup. The player may need to rejoin after the lock timeout; runtime failure behavior has not been exercised.
6. **Delayed old Humanoid callbacks:** HealthChanged, MaxHealth, and Died handlers lack a current-Character identity guard and may overwrite replicated health/death UI state during respawn.
7. **Deferred NPC dialog state:** the deferred open can apply stale dialog state after the NPC or menu context changes, but subsequent server dialog options are proximity/canonical-NPC checked; no persistent or authority impact was found.

## Runtime Validation

No Roblox Studio or Roblox server runtime test was performed for this audit. No claim is made that runtime behavior has been tested. Repository `TESTING.md` documents Roblox Studio, Rojo with `default.project.json`, Studio API access for DataStore tests, and multiplayer server testing as prerequisites for relevant manual validation. Whether these tools are installed or configured on the user's new PC has not been verified.

## Areas Still To Audit

- WorldDecor ownership fix and a safe migration policy for unmarked legacy decor.
- Persistence operation serialization and recovery behavior under injected DataStore failures; inspect remaining failing contracts.
- Reward idempotency/partial-delivery policy and the unclassified reward-related failures.
- Whether the Achievement Menu should refresh while open and whether any other consumer needs snapshot versioning.
- Ownership boundaries for malformed/colliding NPCs and world initialization timing.
- Runtime reproduction of the stale Humanoid callback race and validation after any targeted identity-guard fix.
- Whether to generation-guard the low-impact deferred NPC dialog open.
- DataStore failure and multiplayer/respawn runtime scenarios remain untested.

## Next Recommended Step

Make a minimal targeted patch in `PlayerService.bindHumanoid`: capture the Character associated with the bound Humanoid and make HealthChanged, MaxHealth-changed, and Died callbacks return unless that Character is still `player.Character`; disconnect old Humanoid listeners at CharacterAdded. This addresses the confirmed stale-attribute race without touching profile/reward logic. Keep the WorldDecor ownership fix as the next previously identified production task. No production patch has been made by this audit.

## Important Constraints

- Preserve the existing Crystal Bound repository and branch; do not reinitialize or replace the project.
- Prefer the smallest safe patch and inspect current branch/source before relying on prior handoff notes.
- Never reset `main`, force-push, or merge without an explicit task.
- Do not weaken server-authority, ownership, validation, persistence, or reward safeguards to satisfy a text-based contract.
- Separate production defects, robustness risks, stale contracts, and CI/script errors.
- Do not claim Roblox runtime validation without an actual Studio/server test.
- Do not create replacement project/tooling files merely to assume a local environment.
