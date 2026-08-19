# Crystal Bound

Crystal Bound is a PvE-first open-world action RPG for Roblox, built around exploration, Ancient Crystals, combat, quests, bosses, discovery and long-term world mystery.

> **Development status:** technical foundation + gameplay stack are substantially implemented. The project is still in development and has **not** been runtime-tested in Roblox Studio from this environment.

## Design constraints

- Crystal Bound is an original game and should not become a copy of another Roblox title.
- The story begins with the White Queen and an intentional first loss before the player enters an unknown world.
- Ancient Crystals are a lore/category term, **not a rarity**.
- Official rarity ladder: **Common → Uncommon → Rare → Epic → Legendary → Mythic → Divine**.
- Crystal Bound is PvE-first; PvP is planned but not the primary gameplay focus.
- A second world is a long-term mystery and must not be developed early.
- Current work is intentionally being done **without Codex**.

## Current gameplay foundation

The current branch contains:

- Player profiles, schema reconciliation and persistent progression
- Safe DataStore persistence with session locks, heartbeat, retries and shutdown handling
- XP and level progression
- Money and inventory economy
- Shop, selling and Health Potion consumables
- Crafting
- EMBER, TIDE and GALE crystals
- Crystal passive effects and Crystal Mastery
- Server-authoritative combat and damage validation
- Critical hits
- Server-authoritative Dodge with invulnerability window
- Burn and Slow status effects
- Enemy AI, obstacle steering and Pathfinding fallback
- Training Dummy, Emberling, Tidecrawler, Galewisp, Crystal Bat and Ancient Golem
- Crystal Guardian boss with phase system and telegraphed attacks
- Starter Island, Tide Island, Wind Island and Ancient Ruins
- Level-gated portals
- Quest chain and Quest Journal
- Achievements and Titles
- Daily Bounty
- NPC dialogs and menu routing
- PC and Mobile combat controls
- Combat feedback, damage numbers, hit presentation and placeholder Crystal VFX
- Crystal animation presentation architecture

## Crystal architecture

`ReplicatedStorage/Config/CrystalConfig.lua` is the canonical source for Crystal definitions, unlock levels, Basic attacks, Abilities and Passives.

`ReplicatedStorage/Modules/CrystalSystem.lua` owns Crystal existence, unlock and equip validation.

`ReplicatedStorage/Modules/CrystalMastery.lua` owns Crystal Mastery XP, levels, bonuses and upgrade costs.

Server gameplay systems must not trust client Crystal state.

Current prototype Crystal data:

| Crystal | Unlock | Basic | Ability |
|---|---:|---|---|
| EMBER | Level 1 | Ember attack | Flame Burst |
| TIDE | Level 3 | Tide attack | Tidal Pulse |
| GALE | Level 5 | Gale attack | Gale Strike |

The **final Crystal acquisition design remains open**. The long-term design also includes Mining, Digging, Bosses, Dungeons, World Events and Quests as possible Crystal acquisition activities. Current level-gated unlocks should therefore be treated as the current prototype behavior until this is explicitly decided.

## Combat architecture

Gameplay damage follows the server-authoritative boundary:

```text
Client input
    ↓
Combat validation
    ↓
Crystal / Ability resolution
    ↓
Hit validation
    ↓
DamageService
    ↓
Defense / modifiers / Dodge
    ↓
DamageResult
    ↓
Rewards / progression
    ↓
Server-confirmed CombatFeedback
    ↓
Client-only presentation
```

`DamageService` is the only direct `Humanoid:TakeDamage()` implementation in `src`.

Clients never decide:

- damage amount
- hit success
- Crystal ownership
- Crystal rarity
- rewards
- XP
- Money
- item grants
- boss damage

## Animation and VFX architecture

Animation and cosmetic effects are presentation-only.

- `CrystalAnimationController.client.lua` handles local character animation playback.
- The server creates the character `Animator`; the client does not create a local replacement.
- `CombatFeedback` is the server-confirmed source for Crystal hit presentation.
- `ConfirmedCombatVFXBridge.client.lua` authorizes the local attacker's Crystal VFX only after server confirmation.
- The authorization is one-shot and tied to the confirmed action + Crystal.
- Animation markers must never become gameplay authority.

The six presentation contracts exist for EMBER/TIDE/GALE Basic + Ability, but authored Roblox Animation/Sound assets are still pending.

## Persistence

`ReplicatedStorage/Modules/SafeProfileStore.lua` is the active persistence implementation.

The persistence layer includes:

- session locking by JobId
- lock refresh heartbeat
- retries
- UpdateAsync save snapshots
- corrupted-store protection
- schema reconciliation
- shutdown save handling
- save/remove operation locking

The old unsafe `SaveSystem.lua` is not part of the active project.

## Repository structure

```text
ReplicatedStorage
  Config
  Modules
  Shared
  Remotes
  Assets

ServerScriptService
  Services
  Bootstrap.server.lua
  BossArena.server.lua
  BossTelegraph.server.lua
  CombatFeedbackRemote.server.lua
  CombatCleanup.server.lua
  CraftingRemote.server.lua
  DodgeRemote.server.lua
  NPCDialogRemote.server.lua
  NPCMenuBridge.server.lua
  QuestAvailability.server.lua
  SessionHeartbeat.server.lua
  ShopRemote.server.lua
  StatusSpeedGuardV2.server.lua
  UseItemRemote.server.lua
  WorldDecor.server.lua
  WorldTheme.server.lua

StarterPlayer
  StarterPlayerScripts

StarterGui
  MainUI

Workspace
  NPCs
  Islands
  Spawn
```

`default.project.json` is the Rojo source of truth for the active DataModel mapping.

## CI and static validation

The repository contains dedicated GitHub Actions contracts for:

- Rojo/file mapping
- JSON syntax
- require paths
- gameplay cross-references
- Remote ownership and direction
- Remote rate limits
- damage authority
- direct `TakeDamage()` auditing
- Crystal canonical sources
- Crystal unlock boundaries
- rarity semantics
- inventory/economy invariants
- quest/progression boundaries
- enemy lifecycle/configuration
- boss behavior
- persistence
- animation/presentation authority
- Achievement title canonicalization
- Daily Bounty canonicalization
- NPC interaction option targets
- project identity and legacy cleanup

Do **not** call CI green unless an actual GitHub workflow status is verified.

## Roblox Studio testing

The repository contains `STUDIO_PLAYTEST.md` with the current manual runtime test plan.

The most important next test areas are:

1. boot/profile loading
2. Crystal attack/ability flow
3. combat/range/Dodge security
4. quest completion and reward idempotency
5. enemy AI and respawn lifecycle
6. Guardian phase 2 and telegraph
7. persistence and session locks
8. shop/crafting/consumables
9. PC/mobile UI
10. authored animation/sound asset pass

## Documentation

- `DESIGN.md` — architecture and design decisions
- `TESTING.md` — testing contract and edge cases
- `STUDIO_PLAYTEST.md` — runtime test checklist
- `TODO.md` — current implementation roadmap
- `CURRENT_AUDIT.md` — latest technical audit
- `NEXT_SESSION.md` — handoff for the next development session
- `CHANGELOG.md` — recent implementation history

## Development workflow

Current mode:

```text
Plan / review
    ↓
Implement directly on development branch
    ↓
GitHub review
    ↓
Static validation
    ↓
Roblox Studio runtime test
    ↓
Bug fix / polish
```

Codex is intentionally not required for the current working mode.

## Branch safety

The active development branch is:

`agent/complete-crystal-bound-foundation`

`main` must remain untouched until the project is explicitly ready for merge.
