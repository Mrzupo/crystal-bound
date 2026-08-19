# Crystal Bound — Current Audit

Date: 2026-08-19
Branch: `agent/complete-crystal-bound-foundation`
Base: `main`
Current compare: **912 commits ahead, 29 commits behind** `main`.
`main` remains at verified commit `b4877299d51a083f1bf5adfdf1fc152c6a5c1d17`.

## Verified
- `main` remains untouched; development work is isolated on the feature branch.
- `default.project.json` maps the active Rojo runtime tree and explicitly registers `ConfirmedCombatVFXBridge.client.lua`.
- Legacy `SaveSystem.lua` is absent.
- Legacy Crystal registry/definition modules are absent from the active project tree.
- Legacy `StatusSpeedGuard` is not loaded; V2 is the active runtime implementation.
- `DamageService` is the only direct `Humanoid:TakeDamage()` implementation path in `src`.
- Damage requests require known damage types, valid attackers/targets, positive bounded range and finite damage.
- Dodge state resets on respawn and is cleaned on leave; attacker-based Dodge damage normalizes Range before comparison.
- Shop, Crafting and Consumable transactions validate before mutation and use rollback/rate-limit protections.
- Shop and Crafting request amounts are strict positive integers; fractional amounts are rejected instead of floored.
- Crystal Mastery upgrades verify every material removal and roll back already-consumed materials if any removal or the final upgrade fails.
- CrystalSystem, PlayerData and CrystalMastery now reject malformed non-integer/non-finite Crystal UnlockLevels consistently.
- Inventory stacks are clamped and AddItem never reports a negative added amount from corrupted over-cap state.
- Quest progress rejects invalid/non-finite/non-integer increments.
- Unknown EnemyConfig IDs no longer fall back to TrainingDummy; NPC runtime boundaries reject them cleanly.
- Enemy XP/Money/Loot rewards use canonical `EnemyConfig`; unknown enemy types and implicit Crystal-based fallback rewards are rejected.
- `CrystalService.GetOwnedCrystals()` returns a copy instead of exposing the internal profile table.
- Achievement Titles are derived from earned Achievement IDs; achievement Money rewards are granted only for newly unlocked IDs and have one server payout owner.
- Daily Bounty Goal/Reward values are canonicalized from `DailyBountyConfig` even for an existing same-day profile; payout has one server owner and completion is claimed before payout.
- Guardian telegraphs are bound to the concrete Guardian instance, preventing old-boss attacks after a respawn.
- NPC Burn/Slow only apply after the base damage call actually succeeds.
- Enemy respawn configuration is protected by CI against values shorter than NPC cleanup time.
- Session heartbeat failure state uses weak keys.
- `PlayerService.Save/Remove` guarantee operation-lock release and clean local player state after final-save failures while retaining the persistent session lock.
- Final player removal treats a failed `SafeProfileStore.Release()` as a failed removal and retains the persistent session lock.
- `StatusSpeedGuardV2` continuously enforces the server-derived base WalkSpeed even when no Slow effect is active, immediately corrects server-observed `WalkSpeed` property changes, and prevents stale Character listeners across respawns.
- Crystal Animation Controller no longer creates a local Animator; PlayerService creates the Animator server-side.
- Confirmed Crystal VFX follow a server-confirmed presentation flow; gameplay authority never depends on local VFX state.
- CombatPresentation keeps a single Character HealthChanged connection across respawns.
- NPC dialog closes cleanly when transitioning into Quest/Crystal/Shop/Inventory/Crafting menus.
- NPCMenuBridge validates server-side interaction distance before opening NPC menus.
- PC and mobile input can request presentation locally, but unconfirmed hit VFX are suppressed in the normal client flow.
- Static smoke / presentation / reward / config CI contracts cover the canonical boundaries.
- Additional contracts protect strict crafting input boundaries, final player-remove/session-release semantics, Crystal upgrade material transaction rollback, StatusSpeedGuard baseline/immediate/stale-character enforcement, strict Crystal UnlockLevel/Mastery ID validation, NPC menu interaction distance, Achievement reward ownership and Daily Bounty reward ownership.
- Studio playtest checklist covers Damage bounds, Crystal upgrade rollback, fractional transaction rejection, final session-release failure, baseline WalkSpeed enforcement, malformed Crystal gates and NPC interaction distance.
- README, DESIGN, TESTING, TODO, NEXT_SESSION, CHANGELOG and CURRENT_AUDIT are aligned to the current architecture.

## Important open decisions / limitations
- No real Roblox Studio runtime playtest has been executed here.
- No Luau interpreter is available in this environment.
- The current head has no reported Combined Status checks and no PR-triggered workflow runs available through the connector; do not call CI green without an actual status result.
- Authored Roblox Animation/Sound assets are still absent.
- Current VFX are still procedural/placeholder presentation.
- TIDE/GALE currently unlock through level gates; the master design also plans Mining, Digging, Bosses, Dungeons, World Events and Quests as long-term Crystal acquisition activities. Do not silently replace one model with another; decide the final model first.
- White Queen intro/story implementation has not been replaced or rewritten; the story rules remain unchanged.

## Next technical direction
1. Continue only concrete static audits where risk remains.
2. Move toward Roblox Studio runtime validation.
3. Add authored EMBER Basic + Flame Burst animation/VFX/audio assets first.
4. Repeat the asset contract for TIDE and GALE.
5. Keep gameplay authority in server systems; animation/VFX never decide damage, timing or rewards.
