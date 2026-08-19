# Crystal Bound — Session Handoff

## Branch
- Branch: `agent/complete-crystal-bound-foundation`
- Base: `main`
- Current compare: **814 commits ahead, 29 commits behind** `main` (verified with GitHub compare).
- `main` remains untouched.

## Current state
The branch contains the complete Rojo project foundation plus the current gameplay stack. The repository is in a **hardening + integration + combat presentation** phase, moving toward Roblox Studio runtime verification.

Authoritative design context remains intact: PvE-first open-world action RPG; White Queen intro; first-loss setup; Ancient Crystal lore; Ancient as category, not rarity; Common → Divine rarity ladder; multiple-world long-term mystery; no-Codex working mode.

## Major verified systems
- Server-authoritative `CombatService` + `DamageService`.
- Canonical `CrystalConfig` + `CrystalSystem` + `CrystalMastery`.
- TIDE/GALE level gates enforced inside `CrystalSystem.Unlock()` as well as request-layer checks.
- Central QuestSystem / QuestService completion and rewards.
- SafeProfileStore session lock, refresh heartbeat, save snapshots, retries and corrupted-value protection.
- Economy, Inventory, Shop, Crafting and Consumables with validation, rate limits and rollback.
- Enemy AI, Pathfinding, status effects and lifecycle cleanup.
- Guardian phase system, arena hazard and exact-instance-bound telegraphs.
- Daily Bounty canonicalized from config even for existing same-day profiles.
- Achievement Titles derived from earned Achievement IDs.
- PC/Mobile controls and UI.
- Server-confirmed CombatFeedback presentation.
- Server-owned character Animator for client animation playback.
- One-shot confirmed Crystal VFX bridge.

## Latest hardening work
- Removed Crystal-based fallback loot/XP/Money for unknown enemy types; enemy rewards must come from `EnemyConfig`.
- Added CI reward contract for canonical enemy XP/Money/Loot values.
- Clamped corrupted Inventory stacks before Add/Remove/Has.
- Quest progress rejects invalid/non-finite/non-integer increments.
- Crystal unlock boundary rejects malformed UnlockLevel configuration.
- Daily Bounty Goal/Reward are canonicalized from `DailyBountyConfig` on refresh.
- Guardian telegraph binds to exact Guardian instance.
- NPC Burn/Slow only apply after confirmed damage.
- NPC dialog closes when transitioning into a destination menu.
- NPC dialog options are covered by CI against real menu attributes.
- Crystal VFX now requires one-shot server confirmation and supports late confirmation after Crystal switching.
- Static smoke/presentation contracts cover Animator ownership and confirmed VFX.
- README, DESIGN and TESTING were replaced because they had stale Crystal Fight/legacy architecture descriptions.
- `CURRENT_AUDIT.md` records the latest review and remaining limitations.

## Security / authority rules
- `DamageService` is the only direct `Humanoid:TakeDamage()` path in `src`.
- Known DamageTypes only.
- Positive finite damage and bounded range only.
- PvP damage blocked in current PvE-first combat path.
- Client cannot authoritatively grant Crystals, items, Money, XP, damage or quest completion.
- Animation/VFX never decide gameplay.
- Critical RemoteFunctions have single `OnServerInvoke` ownership.
- Important Remotes are rate-limited.

## Open decisions / limitations
- No actual Roblox Studio runtime playtest has been executed here.
- No Luau interpreter is available here.
- Latest Combined Status is not verified via the available GitHub connector.
- Authored Roblox Animation/Sound assets are still missing.
- Current VFX remain procedural/placeholder-level.
- TIDE/GALE currently use level-gated prototype unlocks, while the master design lists Mining, Digging, Bosses, Dungeons, World Events and Quests as long-term Crystal acquisition activities. Decide the final model before building acquisition content.
- Story remains fixed: White Queen, first loss, unknown world, Ancient Crystal lore, multiple future worlds and delayed second-world reveal.

## Next steps
1. Continue static audits only for concrete remaining issues.
2. Prepare Roblox Studio runtime validation.
3. Add authored EMBER Basic + Flame Burst animation/VFX/audio assets.
4. Repeat asset contract for TIDE and GALE.
5. Test combat, boss, AI, persistence and mobile with real Studio Output.
6. Decide final Crystal acquisition model before Mining/Digging implementation.

## Do not do
- Do not merge into `main`.
- Do not reintroduce legacy SaveSystem or legacy Crystal registries.
- Do not add duplicate `OnServerInvoke` handlers.
- Do not call CI green without verified evidence.
- Do not rewrite the fixed story.
- Do not treat Ancient as a rarity.
- Do not develop the second world early.
