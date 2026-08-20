# Crystal Bound — Roblox Studio Playtest Checklist

This is a runtime checklist, not a claim that the project has already been runtime-tested.

## 1. Boot
- Start a server test with at least one player.
- Confirm profile load succeeds and no legacy save warning appears.
- Confirm `Crystal Bound client ready` appears on the client.
- Confirm the four islands, NPC folder and Guardian spawn exist.
- Confirm world decoration and themes initialize only once.

## 2. Crystal flow
- Start as EMBER.
- Confirm EMBER Basic attack can damage an enemy in range.
- Confirm Q triggers the EMBER presentation path and server damage.
- Reach the TIDE unlock level and equip TIDE.
- Verify TIDE passive health bonus and Tidal Pulse heal without selecting an enemy target.
- Use Tidal Pulse while at full HP; expected: no heal, no consumed cooldown on the server and no false success message.
- Reach the GALE unlock level and equip GALE.
- Verify Gale Strike primary damage and confirm secondary splash is centered on the selected enemy, including enemies near the configured AoE edge that may be farther from the player than the primary target.
- Confirm crystal switching never changes server-side damage authority to the client.
- Controlled config test: malformed/non-integer Crystal UnlockLevel must cause that crystal boundary to reject the ID rather than silently floor the requirement.
- Controlled server test: malformed CrystalMastery mutation ID must be rejected without changing EMBER mastery.

## 3. Combat security
- Spam Basic/Q input rapidly.
- Confirm server cooldown still prevents extra damage.
- Attempt a target outside range from the client.
- Attempt a player target from the client.
- Attempt a dead target.
- Attempt malformed/fractional/oversized damage through a controlled server-side test harness.
- Perform a dodge during an incoming hit.
- Expected: invalid/out-of-range/Player targets deal no damage; invalid damage is rejected; dodged hits return zero applied damage.
- Trigger a controlled server shutdown while a delayed combat/status callback is pending; expected: no new damage is applied after shutdown begins.

## 4. Quest security
- Start `FIRST_FIGHT` and defeat the Training Dummy; confirm the one-step server trigger completes it once.
- Attempt to complete an active multi-step quest before its goal; expected: completion is refused and no XP/Money reward is granted.
- Advance a normal quest to its exact goal; expected: it completes once and rewards exactly once.
- Re-trigger the same completion event; expected: no duplicate reward.
- Confirm Guardian completion is only possible through the intended server trigger.

## 5. Enemy AI
- Pull an Emberling away from spawn.
- Confirm it leashes back toward home.
- Test Emberling special attack and burn.
- Test Tidecrawler slow.
- Test Galewisp movement/special.
- Test Crystal Bat and Ancient Golem attacks.
- Defeat each enemy and confirm XP, Money, loot, quest progress and bounty progress are applied once.
- Confirm dead enemies stop AI/status callbacks before respawn.
- Confirm each enemy respawns exactly once and no duplicate named instances appear.
- Trigger a controlled server shutdown while an enemy is inside its delayed respawn window; expected: shutdown does not create a replacement NPC.

## 6. Guardian
- Bring Guardian below 50% HP.
- Confirm phase changes to 2.
- Confirm boss bar tracks `CrystalGuardian`.
- Verify the boss-centered Phase-2 AoE and the separate targeted telegraph are distinct attacks.
- Wait for telegraph and dodge out of the radius.
- Expected: no damage and no false impact message after a dodge.
- Stay in the telegraph and confirm `BossShockwave` damage.
- Defeat Guardian.
- Confirm Guardian reward/quest/achievement state is granted once and the boss respawns on schedule.
- Force a controlled 60-second autosave window and defeat Guardian during that save; expected: Guardian XP/loot/quest/stats still commit and are persisted by the next settled save pass.
- Trigger a controlled server shutdown while the Guardian is in its delayed respawn window; expected: shutdown does not create a replacement Guardian and Guardian AI stops.
- Trigger controlled server shutdown during a Guardian telegraph windup; expected: the delayed impact callback does not deal damage.

## 7. Persistence
- Change level, money, inventory, crystal mastery and quest state.
- Leave the server normally.
- Rejoin.
- Confirm values persisted.
- Simulate a second server/session lock.
- Confirm the second session is refused while the original lock is healthy.
- Force heartbeat/save failure only in a controlled test environment.
- Confirm the server does not silently release a lost lock.
- Force final `Release()` failure in a controlled test environment.
- Expected: removal reports failure and the persistent session lock is retained.
- During autosave, trigger a server-authorized gameplay mutation; expected: the settled save path does not report success until the changed profile state is persisted.
- Persist a controlled `DailyBounty` record with `Claimed=true` and `Progress<Goal`; expected: `PlayerData.Reconcile()` restores `Claimed=false` before gameplay can observe the profile.
- Inject a controlled `PlayerData.Reconcile()` failure after a successful DataStore lock claim; expected: `SafeProfileStore.Load()` releases the exact claimed SessionLock before returning the load failure.
- Inject a controlled unexpected exception around profile loading; expected: `PlayerService.Load()` clears the in-flight UserId marker so a later join is not permanently blocked by stale `LoadingByUserId` state.

## 8. Transactions / Consumables
- Buy Health Potions with enough Money; confirm Money decreases exactly once and inventory increases exactly once.
- Attempt a purchase over the maximum stack; expected: no Money loss.
- Send fractional purchase/crafting quantities; expected: the server rejects them rather than flooring them.
- Attempt crafting without enough materials; expected: no materials lost.
- Force a failed output insertion in a controlled test; expected: all consumed crafting inputs are restored and any partial output insertion is removed.
- Force a mid-transaction crafting or upgrade material-removal failure; expected: already-consumed inputs are restored.
- Upgrade a Crystal with valid materials; confirm every required material is consumed exactly once and mastery increases exactly once.
- Force `CrystalMastery.Upgrade()` to fail after material consumption in a controlled test; expected: all consumed upgrade materials are restored.
- Use a Health Potion below max HP; expected: exactly one potion is consumed and HP increases by up to 60 without exceeding MaxHealth.
- Try to use a Health Potion at full HP or without inventory; expected: no item is consumed.
- Spam potion use; expected: the 0.2-second server gate prevents duplicate consumption.

## 9. UI / mobile
- Open Inventory, Quest, Shop, Crafting, Daily Bounty and Achievement menus.
- Switch crystals through UI and hotkeys.
- Verify quest HUD text matches the active quest and progress.
- Open/close Quest rapidly; expected: no duplicate request storm or stale UI overwrite.
- Trigger Crystal Keeper/Material Trader prompts from inside the configured distance.
- Controlled server test: attempt the same NPC prompt action from outside range; expected: menu does not open.
- Test mobile ATK/Q/target selection.
- Test mobile TIDE Q with no selected target; expected: Tidal Pulse works identically to PC.
- Test mobile GALE Q with a selected target and verify centered splash range.
- Test mobile dodge and verify the same server cooldown/invulnerability behavior as PC.
- Confirm local animations/VFX never decide damage.
- Change local `Humanoid.WalkSpeed` in a controlled client test; expected: the server restores the derived value immediately.
- Repeat during and after respawn; expected: no stale speed listeners and no incorrect old-character writes.

## 10. Movement / portals
- Walk normally near the configured movement threshold; expected: no false position correction.
- Perform a legitimate portal teleport; expected: the server accepts the known destination and does not snap the player back.
- Touch the same portal repeatedly within the 1-second server cooldown; expected: no second teleport and no new portal movement grace.
- During portal cooldown, attempt to spoof the destination locally; expected: movement authority rejects the displacement.
- Test every configured portal destination and level gate.
- Respawn after a portal use; expected: stale portal grace is cleared and cannot authorize the new character.
- Teleport through a portal, respawn before the original 1-second cooldown expires, then touch a portal again on the new Character; expected: the old delayed cooldown callback must not clear the new Character's cooldown early.
- Perform a Dodge and verify its server velocity remains subject to the normal position authority.
- Trigger controlled server shutdown while the player is near a portal; expected: WorldTheme stops monitoring portal candidates and no new portal movement grace is armed.
- Trigger controlled server shutdown while a player repeatedly sends `DodgeRequest`; expected: no new Dodge boost, ForceField or invulnerability window is created after shutdown begins.

## 11. Asset pass
- Insert the authored animation objects under the six configured names.
- Insert authored sounds under the corresponding sound asset names.
- Verify no fallback asset errors are produced.
- Test one EMBER Basic and Flame Burst ability first.
- Then repeat the same contract for TIDE and GALE.

## 12. Regression checks
- Confirm no duplicate `OnServerInvoke` handlers exist.
- Confirm no direct `Humanoid:TakeDamage()` exists outside `DamageService`.
- Confirm no quest reward is granted on an incomplete objective.
- Confirm no Daily Bounty or Achievement reward can be granted twice.
- Confirm no duplicate NPC/Boss instances appear after respawn.
- Confirm NPC/Guardian delayed respawn callbacks do not create new instances after shutdown begins.
- Confirm delayed Guardian telegraph impacts do not damage Players after shutdown begins.
- Confirm delayed Burn/Slow callbacks do not continue gameplay mutation after shutdown begins.
- Confirm no malformed Crystal UnlockLevel can be floored into an unintended lower gate.
- Confirm malformed CrystalMastery mutation IDs cannot modify EMBER mastery.
- Confirm NPC menu opening is server-distance validated.
- Confirm a menu left open before respawn is cleared on the new Character.
- Confirm a deferred NPC dialog callback from the old Character cannot open on the new Character.
- Confirm WalkSpeed baseline enforcement remains active without a Slow effect.
- Confirm portal grace is destination-bound and cannot be created during a rejected portal touch/cooldown.
- Confirm portal cooldown callbacks are generation-safe across respawn/rejoin.
- Confirm StatusEffect Slow/Burn replacement tokens clear stale callbacks on replacement/cleanup and shutdown.
- Confirm the global `CrystalBoundShuttingDown` flag is published before final profile removal and is honored by DamageService, DodgeService and StatusEffectService.
- Confirm the official rarity ladder is Common → Divine and Ancient is not a rarity.
- Confirm `main` remains untouched.
- Record every runtime failure with exact script name, event/action, reproduction steps and expected vs actual behavior.
