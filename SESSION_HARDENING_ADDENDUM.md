# Session Hardening Addendum

Date: 2026-08-20
Branch: `agent/complete-crystal-bound-foundation`

## Persistence / session ownership

- `SafeProfileStore.Load()` creates a unique load token per load invocation.
- `Save()`/`Refresh()` use active profile tokens; superseded/aborted loads release the exact token they claimed.
- `SafeProfileStore.Release(player, expectedToken)` prevents stale loads from releasing newer locks.
- `PlayerService.Load()` uses per-UserId load-generation guards and releases claimed locks on superseded/shutdown/player-left exits.
- `PlayerService.Save()`/`RefreshSession()` re-check profile/closing state after the serialized operation lock is acquired.
- `PlayerService.saveConsistently()` uses bounded revision-settle passes.
- Duplicate `PlayerService.Remove()` calls serialize through `Closing`/`RemovalResults`; `PlayerRemoving` remains the canonical persistence owner.
- `Bootstrap.server.lua` is the single canonical PlayerAdded/load owner and processes already-present players after binding the handler; the redundant `PlayerLoadCatchup.server.lua` owner was removed.
- Bootstrap load attempts are protected by a weak-key `loadingPlayers` guard that is cleared after every `PlayerService.Load()` attempt, including failed/error paths.
- Player CharacterAdded callbacks re-check exact Character identity before/after waiting for Humanoid, blocking stale-respawn bindings.
- During global shutdown, `GetProfile()` and `Heal()` reject new gameplay profile access/mutation while `PlayerLifecycle` still unconditionally delegates `PlayerRemoving` to `PlayerService.Remove()`.
- Shutdown waits for loaded-profile removals and pending loads with a bounded timeout.

## Health / movement authority

- Player Health mutation is centralized in `PlayerService.Heal()`; TIDE and Health Potion healing both route through it.
- `PlayerService.Heal()` validates live Player/Character state, finite 0..1000 heal input, MaxHealth bounds and returns the actually applied amount.
- Health Authority contracts allow direct server Humanoid Health/MaxHealth writes only for PlayerService player-heal/sync logic plus NPC/Boss spawn-time initialization.
- `StatusEffectService` owns Slow state; Movement guards read Slow through the service rather than the client-exposed Humanoid attribute.
- `StatusSpeedGuardV2` separates WalkSpeed refresh and position enforcement cadence, resets stale position snapshots, and preserves portal-arrival grace through Character-aware state.
- Dodge invulnerability uses per-player tokens and current-Character checks, preventing stale delayed callbacks after respawn/re-dodge.

## Progression / reconciliation

- Persisted player stats are normalized to finite non-negative integers and capped to runtime service limits.
- Quest active/completed state is canonicalized to valid IDs and prerequisite-consistent state.
- Achievement IDs are canonicalized and Titles rebuilt from canonical earned achievements.
- Daily Bounty state is reconstructed from `DailyBountyConfig` and repaired on malformed definitions.
- Player XP and Crystal Mastery XP are bounded below the next-level threshold; max-level states store zero XP.
- `PlayerData.Reconcile()` explicitly preserves valid SessionLock `JobId` + `Token` + `Timestamp` state.
- Enemy mastery rewards derive directly from canonical Enemy XP without an arbitrary minimum fallback.

## Economy / inventory / crafting

- Economy Money mutation is exclusively owned by `EconomyService` and always finite/integer/bounded.
- Shop purchases validate total cost and use detached Inventory snapshots before mutation.
- Selling checks Wallet capacity before inventory consumption and restores both Money + items on any unexpected partial payout.
- `InventoryConfig.GetMaxStackSize()` runtime-bounds stack size to 1..1000.
- `InventoryService.GetInventory()` returns a detached normalized snapshot and does not mutate missing inventory.
- Crafting validates multiplied totals before formatting or mutation and now rejects unregistered recipe Input item IDs at runtime.
- Crafting rolls back consumed inputs if output insertion or later mutation fails.
- Health Potion consumption rolls inventory back if `PlayerService.Heal()` applies zero HP.

## Boss / NPC / combat hardening

- `DamageService` remains the sole direct `Humanoid:TakeDamage()` owner.
- Environmental damage requires `Attacker == nil`; Player-vs-Player damage remains blocked.
- Last-attacker attribution is instance/session-bound and restored on zero-applied damage.
- Guardian rewards keep XP/Drop/Boss stats/quest progression when Money is capped; Money alone is capped by `EconomyService`.
- Guardian `Rewarded` state requires a valid current player profile.
- Guardian creation is idempotent and removes corrupt non-boss occupants of its reserved name.
- Guardian telegraphs bind delayed impacts to the original Guardian and original Player Character.
- Guardian arena hazard interval is runtime-bounded to 0.1..10 seconds.
- NPC AI uses bounded config values, clears path/status state on death, and revalidates NPC liveness after yielded path computation.

## Verification boundary

Static repository/contract checks remain the basis of verification. No Roblox Studio runtime success or green CI is claimed without an actual observed run.
