# Session Hardening Addendum

Date: 2026-08-20
Branch: `agent/complete-crystal-bound-foundation`

## Persistence / session ownership

- `SafeProfileStore.Load()` now creates a unique load token per load invocation.
- The active `sessionTokens[player]` entry is installed only after a load successfully claims the DataStore session lock.
- `Save()` and `Refresh()` use the active profile token; superseded or aborted loads release the token stored in the profile they actually claimed.
- `SafeProfileStore.Release(player, expectedToken)` supports token-specific release, preventing a stale load from releasing a newer active lock.
- `PlayerService.Load()` keeps a per-UserId generation guard and releases claimed locks on every superseded/shutdown/player-left exit.
- `PlayerService.Save()` and `PlayerService.RefreshSession()` re-check `Profiles`/`Closing` after acquiring the serialized operation lock.
- Shutdown waits for both loaded-profile removals and pending profile loads, while `BeginShutdown()` makes new loads abort safely.

## Progression / reconciliation

- Persisted player stats are normalized to finite non-negative integers.
- Quest active/completed state is restricted to canonical quest IDs and prerequisite-consistent state.
- Achievement IDs are canonicalized and Titles are rebuilt from canonical earned achievements.
- Daily Bounty state is reconstructed from `DailyBountyConfig`; invalid bounty state resets its date so the daily selector is recalculated.
- Player XP and Crystal Mastery XP are bounded below the next-level threshold for the stored level; max-level states store zero XP.

## Reward / gameplay hardening

- Guardian Boss money and `GUARDIAN_TRIAL` quest money are preflighted together against the wallet cap before committing either reward.
- Portal arrival state is cleared on character replacement so stale grace/cooldown data cannot survive a respawn.
- Dodge damage requires the passed Humanoid to belong to the player's current character.
- Slow multiplier state is cleared together with the Slow status token.
- Server gameplay contracts reject future use of client-exposed derived attributes as authoritative sources.

## Verification boundary

Static repository/contract checks continue to be the basis of verification. No claim of Roblox Studio runtime success or green CI is made without an actual observed run.
