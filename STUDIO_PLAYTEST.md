# Crystal Bound — Roblox Studio Playtest Checklist

This is a runtime checklist, not a claim that the project has already been runtime-tested.

## 1. Boot
- Start a server test with at least one player.
- Confirm profile load succeeds and no legacy save warning appears.
- Confirm `Crystal Bound client ready` appears on the client.
- Confirm the four islands, NPC folder and Guardian spawn exist.

## 2. Crystal flow
- Start as EMBER.
- Confirm EMBER Basic attack can damage an enemy in range.
- Confirm Q triggers the EMBER presentation path and server damage.
- Reach the TIDE unlock level and equip TIDE.
- Verify TIDE passive health bonus and Tidal Pulse heal.
- Reach the GALE unlock level and equip GALE.
- Verify Gale Strike plus secondary splash hits only enemies in the configured radius.
- Confirm crystal switching never changes server-side damage authority to the client.

## 3. Combat security
- Spam Basic/Q input rapidly.
- Confirm server cooldown still prevents extra damage.
- Attempt a target outside range from the client.
- Attempt a player target from the client.
- Attempt a dead target.
- Perform a dodge during an incoming hit.
- Expected: invalid/out-of-range/Player targets deal no damage; dodged hits return zero applied damage.

## 4. Enemy AI
- Pull an Emberling away from spawn.
- Confirm it leashes back toward home.
- Test Emberling special attack and burn.
- Test Tidecrawler slow.
- Test Galewisp movement/special.
- Test Crystal Bat and Ancient Golem attacks.
- Defeat each enemy and confirm XP, Money, loot, quest progress and bounty progress are applied once.

## 5. Guardian
- Bring Guardian below 50% HP.
- Confirm phase changes to 2.
- Confirm boss bar tracks `CrystalGuardian`.
- Wait for telegraph and dodge out of the radius.
- Expected: no damage and no false impact message after a dodge.
- Stay in the telegraph and confirm `BossShockwave` damage.
- Defeat Guardian.
- Confirm Guardian reward/quest/achievement state is granted once and the boss respawns on schedule.

## 6. Persistence
- Change level, money, inventory, crystal mastery and quest state.
- Leave the server normally.
- Rejoin.
- Confirm values persisted.
- Simulate a second server/session lock.
- Confirm the second session is refused while the original lock is healthy.
- Force heartbeat/save failure only in a controlled test environment.
- Confirm the server does not silently release a lost lock.

## 7. UI / mobile
- Open Inventory, Quest, Shop, Crafting, Daily Bounty and Achievement menus.
- Switch crystals through UI and hotkeys.
- Verify quest HUD text matches the active quest and progress.
- Test mobile ATK/Q/target selection.
- Confirm local animations/VFX never decide damage.

## 8. Asset pass
- Insert the authored animation objects under the six configured names.
- Insert authored sounds under the corresponding sound asset names.
- Verify no fallback asset errors are produced.
- Test one EMBER Basic and Flame Burst ability first.
- Then repeat the same contract for TIDE and GALE.

## 9. Regression checks
- Confirm no duplicate `OnServerInvoke` handlers exist.
- Confirm no direct `Humanoid:TakeDamage()` exists outside `DamageService`.
- Confirm `main` remains untouched.
- Record every runtime failure with exact script name, event/action, reproduction steps and expected vs actual behavior.
