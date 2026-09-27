# Crystal Bound Engineering State

## Current Branch

`agent/complete-crystal-bound-foundation` (remote GitHub branch).

## Current Verified Commit

`9f036b97108987076c840a82136776658fc5eca6` — verified as the branch tip during this review on 2026-09-27. Repository content was inspected from that commit through GitHub. The local workspace was not used as source of truth.

## Project Status

Existing Roblox project; development is ongoing. The verified head includes foundation fixes and the semantic NPC-dialog contract adjustment. This is not a declaration that the project is complete or runtime-stable.

The Actions run set queried for this exact commit contained 158 workflow runs, of which 49 concluded as failures. Therefore CI is not wholly green. The failures include contract-script syntax/runtime errors and source-marker mismatches; a failed check is not by itself proof of a production defect. See Known Failed Contracts.

## Completed Audits

- **WorldDecor / Decor Ownership (static source review):** `src/ServerScriptService/WorldDecor.server.lua` tags generated parts and readiness markers with `CrystalBoundDecor = true`. However, `clearDecor` also deletes direct island children solely by a list of legacy names and removes its named readiness marker without checking ownership. Generic-name collisions can delete unrelated instances if that island is regenerated. This is a conditional destructive production bug; whether a conflicting instance exists in the saved place was not runtime-checked.
- **Persistence / Player Data (static source review):** `PlayerData.Reconcile` clamps and normalizes persisted fields. `SafeProfileStore` claims, refreshes, saves, and releases a session lock through `UpdateAsync`; save/release paths check the session token. `PlayerService` serializes per-player operations, tracks profile revisions during save settling, and refuses normal profile access while saving/closing. No DataStore runtime test was performed. On final save or release failure, the service reports failure and retains the lock, but removes in-memory profile state; unsaved in-memory progress cannot then be recovered by that server.
- **Rewards / Achievement Atomicity (static source review):** quest reward values are validated before quest completion, and BossService validates progression reward fields before setting its rewarded flag. Achievement checks mutate the achievement list before PlayerService credits its configured reward. These operations are synchronous and later persisted with the profile; there is no explicit rollback transaction if an unexpected runtime error interrupts the sequence. No such runtime error was observed. Money cap behavior can grant less than the configured amount.
- **GetPlayerData / Client Snapshot Semantics (static source review):** Bootstrap rate-limits the RemoteFunction, requires `ProfileLoaded`, selects a fixed set of profile fields, and returns a deep copy. `AchievementMenu.client.lua` is the only client script found that calls this remote. It protects refreshes against menu/character changes, but does not subscribe to achievement changes while already open; its displayed unlocked state can remain stale until the next refresh/reopen.
- **NPC Spawn / World Lifecycle (static source review):** Bootstrap repairs canonical islands/portals/spawn and canonical interaction NPCs. Enemy spawns use unique names, server attributes, and a death/respawn callback; NPCService reuses a live matching enemy and starts AI only once. On a unique-name collision with an invalid/unowned instance, NPCService destroys that instance. Bootstrap likewise destroys a same-name non-Model or malformed canonical NPC. These are conditional ownership risks if unrelated instances are placed in the reserved NPC folder. WorldDecor waits up to 30 seconds for each island; a missing island at timeout is skipped for that startup.
- The requested audit sequence supplied points 1–5; point 6 was truncated in the message and is awaiting clarification.

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

These are individual static GitHub Actions results, not an overall green CI result and not Roblox runtime evidence.

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

## Known Risks

1. **WorldDecor ownership:** `clearDecor` deletes unmarked direct children by generic names (`Rock`, `TreeTrunk`, `AncientCrystal`, and others) and deletes the readiness marker by name. A foreign same-name object can be destroyed during regeneration.
2. **NPC spawn ownership:** malformed or non-canonical same-name instances in the reserved NPC folder can be destroyed during repair/spawn.
3. **Reward rollback:** quest, achievement, and combat/boss reward state is not wrapped in a general rollback transaction if an unexpected error interrupts synchronous mutations. No interrupted reward was observed.
4. **Snapshot freshness:** an already-open Achievement Menu is not refreshed by achievement-state changes.
5. **Persistence failure at departure:** final save/release failure preserves the DataStore lock but discards the server's in-memory profile during cleanup. The player may need to rejoin after the lock timeout; runtime failure behavior has not been exercised.

## Runtime Validation

No Roblox Studio or Roblox server runtime test was performed for this audit. No claim is made that runtime behavior has been tested. Repository `TESTING.md` documents Roblox Studio, Rojo with `default.project.json`, Studio API access for DataStore tests, and multiplayer server testing as prerequisites for relevant manual validation. Whether these tools are installed or configured on the user's new PC has not been verified.

## Areas Still To Audit

- WorldDecor ownership fix and a safe migration policy for unmarked legacy decor.
- Persistence operation serialization and recovery behavior under injected DataStore failures; inspect remaining failing contracts.
- Reward idempotency/partial-delivery policy and the unclassified reward-related failures.
- Whether the Achievement Menu should refresh while open and whether any other consumer needs snapshot versioning.
- Ownership boundaries for malformed/colliding NPCs and world initialization timing.
- The user's audit item 6 and any subsequent items, once supplied.

## Next Recommended Step

Review and implement a minimal WorldDecor ownership-only cleanup policy: destroy only instances carrying `CrystalBoundDecor == true`, including readiness markers. Decide separately how to handle pre-attribute legacy decor, since generic names cannot safely establish ownership. This is the highest-priority confirmed destructive collision risk. No production patch has been made.

## Important Constraints

- Preserve the existing Crystal Bound repository and branch; do not reinitialize or replace the project.
- Prefer the smallest safe patch and inspect current branch/source before relying on prior handoff notes.
- Never reset `main`, force-push, or merge without an explicit task.
- Do not weaken server-authority, ownership, validation, persistence, or reward safeguards to satisfy a text-based contract.
- Separate production defects, robustness risks, stale contracts, and CI/script errors.
- Do not claim Roblox runtime validation without an actual Studio/server test.
- Do not create replacement project/tooling files merely to assume a local environment.
