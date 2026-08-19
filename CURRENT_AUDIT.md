# Crystal Bound — Current Audit

Date: 2026-08-19
Branch: `agent/complete-crystal-bound-foundation`
Base: `main`

## Verified
- `main` remains untouched; development work is isolated on the feature branch.
- `default.project.json` maps the active Rojo runtime tree and explicitly registers `ConfirmedCombatVFXBridge.client.lua`.
- Legacy `SaveSystem.lua` is absent.
- Legacy Crystal registry/definition modules are absent from the active project tree.
- Legacy `StatusSpeedGuard` is not loaded; V2 is the active runtime implementation.
- `DamageService` is the only direct `Humanoid:TakeDamage()` implementation path in `src`.
- Damage requests require known damage types, valid attackers/targets, positive bounded range and finite damage.
- Dodge state resets on respawn and is cleaned on leave; attacker-based Dodge damage now normalizes Range before comparison.
- Shop, Crafting and Consumable transactions validate before mutation and use rollback/rate-limit protections.
- Inventory stacks are clamped and AddItem never reports a negative added amount from corrupted over-cap state.
- Quest progress rejects invalid/non-finite/non-integer increments.
- Crystal unlock level gates are enforced in the canonical `CrystalSystem.Unlock()` boundary, not only in Bootstrap; malformed UnlockLevel config is rejected.
- Achievement Titles are derived from earned Achievement IDs instead of trusted standalone title strings.
- Daily Bounty Goal/Reward values are canonicalized from `DailyBountyConfig` even for an existing same-day profile.
- Enemy XP/Money/Loot rewards use canonical `EnemyConfig`; unknown enemy types and implicit Crystal-based fallback rewards are rejected.
- Guardian telegraphs are bound to the concrete Guardian instance, preventing old-boss attacks after a respawn.
- NPC Burn/Slow only apply after the base damage call actually succeeds.
- Enemy respawn configuration is protected by CI against values shorter than NPC cleanup time.
- Crystal Animation Controller no longer creates a local Animator; PlayerService creates the Animator server-side.
- Crystal VFX requires a one-shot server-confirmed CombatFeedback authorization.
- NPC dialog now closes cleanly when transitioning into Quest/Crystal/Shop/Inventory/Crafting menus.
- PC and mobile input can request presentation locally, but unconfirmed hit VFX are suppressed.
- Static smoke / presentation / reward / config CI contracts cover the new canonical boundaries.
- `CURRENT_AUDIT.md`, `NEXT_SESSION.md`, `TODO.md` and `CHANGELOG.md` are being kept in the repository for handoff continuity.

## Important open decisions / limitations
- No real Roblox Studio runtime playtest has been executed here.
- No Luau interpreter is available in this environment.
- Latest Combined Status is not verified through the available connector; do not call CI green without an actual status result.
- Authored Roblox Animation/Sound assets are still absent.
- Current VFX are still procedural/placeholder presentation.
- TIDE/GALE currently unlock through level gates; the master design also plans Mining, Digging, Bosses, Dungeons, World Events and Quests as Crystal acquisition activities. Do not silently replace one model with another; decide the final acquisition model first.
- White Queen intro/story implementation has not been replaced or rewritten; the story rules remain unchanged.

## Next technical direction
1. Continue only concrete static audits where risk remains.
2. Move toward Roblox Studio runtime validation.
3. Add authored EMBER Basic + Flame Burst animation/VFX/audio assets first.
4. Repeat the asset contract for TIDE and GALE.
5. Keep gameplay authority in server systems; animation/VFX never decide damage, timing or rewards.
