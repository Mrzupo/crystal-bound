# Crystal Bound — Current Audit

Date: 2026-08-20
Branch: `agent/complete-crystal-bound-foundation`
Base: `main`
Current compare: **1110 commits ahead, 29 commits behind** `main`.
`main` remains at verified commit `b4877299d51a083f1bf5adfdf1fc152c6a5c1d17`.

## Verified
- `main` remains untouched; development work is isolated on the feature branch.
- `default.project.json` maps the active Rojo runtime tree and explicitly registers `ConfirmedCombatVFXBridge.client.lua`.
- Legacy `SaveSystem.lua` is absent.
- Legacy Crystal registry/definition modules are absent from the active project tree.
- Legacy `StatusSpeedGuard` is not loaded; V2 is the active runtime implementation.
- `DamageService` is the only direct `Humanoid:TakeDamage()` implementation path in `src`.
- Damage requests require known damage types, valid attackers/targets, positive bounded range and finite damage.
- `DamageService` restricts NPC attackers and non-player targets to the server-managed `Workspace.NPCs` tree and rejects Player-vs-Player damage.
- Last-attacker records pin Player attribution to the concrete Player instance/session and reject stale rejoin sessions before combat rewards are credited.
- Lethal damage records the attacker before `Humanoid:TakeDamage()` so `Died` callbacks can attribute the final hit; zero-applied damage restores the previous attribution.
- Normal enemy reward processing explicitly clears attacker attribution after successful defeat rewards; respawned NPC instances cannot inherit old attacker records.
- Dodge state resets on respawn and is cleaned on leave; attacker-based Dodge damage normalizes Range before comparison.
- `DodgeService` runtime config is finite-safe; direction magnitude and attacker ranges are bounded before movement or damage are applied.
- NPC damage paths require the attacker model to still be parented, marked `Enemy`, and alive before damage is applied.
- Shop, Crafting and Consumable transactions validate before mutation and use rollback/rate-limit protections.
- Shop and Crafting request amounts are strict positive integers; fractional amounts are rejected instead of floored.
- Shop purchase totals are finite, positive and bounded by canonical `EconomyConfig.MaxMoney` before the money mutation phase.
- Crafting CI validates every configured recipe input/output ID against `InventoryConfig`, not only a fixed allowlist.
- Crafting output/input multiplication is finite/integer-bounded before materials are mutated.
- Crystal Mastery upgrades verify every material removal and roll back already-consumed materials if any removal or the final upgrade fails.
- `CrystalMastery.AddXP`, `GetUpgradeCost` and `Upgrade` reject malformed Crystal mutation IDs instead of silently falling back to EMBER.
- CrystalSystem only treats Crystal IDs as valid when UnlockLevel is finite/integer and Definition, BasicAttack, Ability and Passive blocks all exist.
- PlayerData rejects malformed persisted Crystal ownership, equipped IDs and Mastery keys using the same complete-config Crystal boundary; malformed equipped state falls back to the first valid owned Crystal instead of blindly restoring EMBER.
- `PlayerData.Reconcile()` normalizes persisted Level/XP/Money, inventory stacks, quests/progress, islands, DailyBounty and SessionLock data before gameplay uses the profile.
- PlayerData reconciliation has a dedicated CI contract covering persisted numeric bounds, completed-vs-active quest state, bounty reward bounds and malformed SessionLock rejection.
- CrystalMastery applies the same complete Crystal-config validation before using a Crystal ID.
- CrystalConfig CI enforces semantic Damage/Range/Cooldown/HealAmount/UnlockLevel bounds.
- Combat modifier CI enforces Critical probability 0..1 and multiplier 1..10, and `CombatModifierService` applies the same runtime bounds before rolling.
- Economy config CI validates StartingMoney/MinMoney/MaxMoney relationships instead of hardcoding balance values.
- Money mutations are owned by `EconomyService`; direct `profile.Money` mutation elsewhere in `ServerScriptService` is blocked by contract.
- Inventory stacks are clamped and AddItem never reports a negative added amount from corrupted over-cap state.
- Inventory mutations are owned by `InventoryService`; direct `profile.Inventory[...]` mutation elsewhere in `ServerScriptService` is blocked by contract.
- Level/Experience mutations are owned by `XPService`; direct server mutation outside the progression service is blocked by contract.
- Quest progress rejects invalid/non-finite/non-integer increments.
- Quest completion is owned by `QuestService`; `QuestSystem.Complete()` has a dedicated single-owner regression contract.
- `QuestService.Complete()` validates XP/Money reward configuration as finite nonnegative integers before committing `CompletedQuests`.
- Unknown EnemyConfig IDs no longer fall back to TrainingDummy; NPC runtime boundaries reject them cleanly.
- Enemy XP/Money/Loot rewards use canonical `EnemyConfig`; unknown enemy types and implicit Crystal-based fallback rewards are rejected.
- NPC special attacks clamp runtime ranges/cooldowns and Gale teleport offsets to bounded values.
- Normal enemy and Guardian loot IDs are checked against canonical `InventoryConfig` by CI.
- `CrystalService` is the sole server-facing Crystal ownership wrapper and delegates mutation to `CrystalSystem`.
- `CrystalAbilityService.Execute()` independently verifies the active/owned Crystal, complete Crystal config, GALE enemy target context and player-to-target ability range before applying secondary effects.
- Crystal ability input CI pins defensive numeric ability values to a 1000-unit cap.
- TIDE's `Tidal Pulse` configuration explicitly combines ability damage with a bounded heal; the service implementation matches the canonical config rather than treating the heal as an accidental side effect.
- Achievement Titles are derived from earned Achievement IDs; achievement Money rewards are granted only for newly unlocked IDs and have one server payout owner.
- Daily Bounty Goal/Reward values are canonicalized from `DailyBountyConfig`; payout has one server owner and completion is claimed before payout.
- Guardian creation is active in the loaded `BossTelegraph` runtime: a missing/invalid `CrystalGuardian` identity is replaced and a canonical Guardian is created from `BossConfig.CrystalGuardian.ArenaCenter`; `BossService.CreateGuardian()` remains idempotent.
- Guardian phase-2 multipliers, attack values, shockwave radius/damage and telegraph values are runtime-bounded and backed by semantic CI contracts.
- Guardian rewards are idempotent, reward configuration is finite/integer-validated, and XP/Money/Inventory mutation stays on canonical services; optional quest completion no longer blocks Guardian cleanup/respawn.
- Guardian telegraphs are bound to the concrete Guardian instance, preventing old-boss attacks after a respawn.
- Guardian reward contract additionally verifies the configured Guardian Drop is registered in `InventoryConfig`.
- NPC Burn/Slow only apply after the base damage call actually succeeds.
- Enemy respawn configuration is protected by CI against values shorter than NPC cleanup time.
- Enemy lifecycle CI protects both death cleanup and attacker-liveness checks.
- Session heartbeat failure state uses weak keys; heartbeat kicks after two consecutive refresh failures to protect the save-session lock.
- `PlayerService.Save/Remove` guarantee operation-lock release and clean local player state after final-save failures while retaining the persistent session lock.
- Final player removal treats a failed `SafeProfileStore.Release()` as a failed removal and retains the persistent session lock.
- `PlayerService.Load` rejects a player that leaves while the yieldable profile load is in flight and releases the claimed persistent session lock instead of installing an orphaned in-memory profile.
- The load lifecycle is checked again immediately after `Profiles[player]` is populated; a leave race removes the in-memory profile and releases the persistent lock before returning.
- `SafeProfileStore.Load/Save/Refresh/Release` only mutate a profile when the persistent `SessionLock.JobId` belongs to the current server session; competing active locks are not overwritten.
- Profile-store session-lock invariants have a dedicated CI contract covering foreign-lock protection, lock refresh/release ownership and Load/Save reconciliation.
- `SessionHeartbeat.server.lua` registers `game:BindToClose()` and runs the canonical `PlayerService.Remove()` path for loaded profiles during server shutdown with a bounded shutdown wait.
- `StatusSpeedGuardV2` continuously enforces the server-derived base WalkSpeed even when no Slow effect is active, immediately corrects server-observed `WalkSpeed` property changes, and prevents stale Character listeners across respawns.
- `StatusSpeedGuardV2` applies conservative server-side position authority using observed displacement bounds and server rollback without creating a second server entry-point.
- Position correction refreshes the authoritative movement snapshot immediately after rollback, preventing repeated correction against a stale pre-correction position.
- Portal movement authority is cleared on Character respawn, preventing stale portal grace from authorizing a new character instance.
- `WorldTheme.server.lua` performs the canonical level-gated portal destination teleport, resets server velocity, verifies destination arrival and arms movement grace only for that same destination.
- Bootstrap portal creation is definition-only; it no longer registers a second `Touched` teleport handler or directly changes player `CFrame`.
- `WorldTheme.server.lua` is the sole canonical server owner for portal touch, level gate, destination teleport, destination verification and movement-grace authorization.
- Portal movement CI explicitly rejects Bootstrap portal `Touched`/teleport authority drift and requires the canonical WorldTheme teleport path.
- Portal movement CI cross-checks Bootstrap portal definitions, WorldTheme destinations and WorldConfig level gates plus the pre-touch snapshot, canonical teleport and arrival-grace flow.
- MovementConfig CI bounds WalkSpeed, Slow, observed-position, grace and portal-arrival parameters.
- Dodge has no generic movement/teleport grace path; its server velocity remains subject to the same positional authority.
- `DodgeService` explicitly disconnects CharacterAdded listeners on leave/rebind while retaining weak player state.
- Dodge request directions are server-validated as finite `Vector3` values and bounded by `MaxDirectionMagnitude` before movement is applied.
- Bootstrap and all major server Remote entrypoints fail fast on mismatched Remote classes instead of silently binding the wrong type.
- Critical RemoteEvent/RemoteFunction types are statically verified from `default.project.json` and per-entrypoint fail-fast guards are covered by CI.
- Critical mutating Remote rate-limit state is contract-checked for cleanup on `PlayerRemoving`.
- RemoteEvent ownership covers all known mutating client-to-server RemoteEvents; RemoteFunction ownership separately covers `GetPlayerData`, `GetQuestData`, `GetAvailableQuests` and `NPCDialogRequest`.
- NPC dialog config is constrained to the canonical CrystalKeeper/MaterialTrader option IDs, and the server read path enforces interaction distance plus request rate-limit cleanup.
- World initialization CI validates the bounded portal tracking loop, cleanup on PlayerRemoving and definition-only Bootstrap portal ownership instead of incorrectly banning all `while` loops.
- StatusEffect input CI validates bounded Slow/Burn duration, multiplier, damage, interval and integer tick-count parameters; lifecycle CI protects token cancellation and cleanup.
- Crystal Animation Controller no longer creates a local Animator; PlayerService creates the Animator server-side.
- Confirmed Crystal VFX follow a server-confirmed presentation flow; gameplay authority never depends on local VFX state.
- CombatPresentation keeps a single Character HealthChanged connection across respawns.
- NPC dialog closes cleanly when transitioning into Quest/Crystal/Shop/Inventory/Crafting menus.
- NPCMenuBridge validates server-side interaction distance before opening NPC menus.
- PC and mobile input can request presentation locally, but gameplay authority remains server-side and VFX require server confirmation before actual VFX playback.
- Combat defeat rewards are sourced from canonical EnemyConfig and guarded by `DeathRewarded` idempotency.
- Environmental/Boss hazard contracts validate attacker-less Environmental damage against current BossArena semantics.
- RemoteFunction contracts enforce single ownership and request-rate guards.
- Portal contracts verify gates consume canonical `WorldConfig` level fields.
- Status effects use weak Humanoid state, token-based cancellation for Slow/Burn, and explicit `Clear()` cleanup; a lifecycle contract protects those invariants.
- `HitboxService.GetEnemyModels()` resolves targets only from `Workspace.NPCs`, requires `Model` + `Enemy == true`, living Humanoids and bounded radius; a dedicated regression contract protects that boundary.
- AI path destinations are finite-validated, quantized, cached by weak Model keys, recomputed at a bounded interval, and explicitly cleared when NPCs die; the AI-path contract protects those lifecycle/resource invariants.
- `contract-path-validation.yml` validates workflow-referenced repository paths.
- Studio playtest checklist explicitly covers portal cooldown/arrival grace, stale portal authorization, malformed CrystalMastery mutation IDs, movement correction, normal multiplayer contention, Damage bounds, NPC attacker liveness and transaction rollbacks.

## Important open decisions / limitations
- No real Roblox Studio runtime playtest has been executed here.
- No Luau interpreter is available in this environment.
- The current head has no reported Combined Status checks and no PR-triggered workflow runs available through the connector; do not call CI green without an actual status result.
- Authored Roblox Animation/Sound assets are still absent.
- Current VFX are still procedural/placeholder presentation.
- TIDE/GALE currently unlock through level gates; the master design also plans Mining, Digging, Bosses, Dungeons, World Events and Quests as long-term Crystal acquisition activities. Do not silently replace one model with another; decide the final model first.
- White Queen intro/story implementation has not been replaced or rewritten; the story rules remain unchanged.
- Conservative server movement-position anti-teleport foundations are present, but thresholding and interaction with Roblox network ownership/physics still require real Studio multiplayer validation before calling exploit-resistance complete.

## Next technical direction
1. Continue concrete static audits where risk remains.
2. Move toward Roblox Studio runtime validation, especially movement correction, portal arrivals, Dodge velocity, shutdown saves and multiplayer contention.
3. Add authored EMBER Basic + Flame Burst animation/VFX/audio assets first.
4. Repeat the asset contract for TIDE and GALE.
5. Keep gameplay authority in server systems; animation/VFX never decide damage, timing or rewards.
