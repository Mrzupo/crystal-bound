# Crystal Bound — Design & Architecture

## 1. Vision

Crystal Bound is a PvE-first open-world action RPG on Roblox.

The technical architecture must support:

- exploration
- discovery
- Crystal progression
- combat
- quests
- bosses
- cooperative play
- mobile + PC
- long-term expansion into additional worlds

The project must remain original and must not become a copy of another Roblox game.

The White Queen intro, the intentional first loss, the unknown first world, the long-term second-world mystery and the Ancient Crystal lore are fixed story/design constraints.

## 2. Crystal terminology

**Ancient Crystal** is a lore/category term and is never a rarity.

Official rarity ladder:

1. Common
2. Uncommon
3. Rare
4. Epic
5. Legendary
6. Mythic
7. Divine

Current prototype Crystals:

- EMBER
- TIDE
- GALE

`ReplicatedStorage/Config/CrystalConfig.lua` is the canonical source for Crystal definitions, unlock levels, Basic attacks, Abilities and Passives.

`ReplicatedStorage/Modules/CrystalSystem.lua` is the canonical server-side ownership/equip boundary.

`ReplicatedStorage/Modules/CrystalMastery.lua` is the canonical Crystal Mastery progression layer.

## 3. Project structure

```text
src/
  ReplicatedStorage/
    Config/
    Modules/
      Combat/
    Shared/
    Assets/
  ServerScriptService/
    Services/
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
  StarterPlayer/
    StarterPlayerScripts/
  StarterGui/
```

`default.project.json` is the Rojo source of truth for the active DataModel.

## 4. Service responsibilities

### PlayerService

Owns:

- profile lifecycle
- session-safe loading
- server-owned Character Animator initialization
- progression synchronization
- player health attributes
- save/remove operation locking
- title display

It must not become a generic God service. New gameplay systems should remain in focused services.

### SafeProfileStore

Owns persistence:

- DataStore `UpdateAsync`
- SessionLock claim/refresh/release
- retries
- save snapshots
- corrupted-store protection
- session ownership

Only this layer may perform profile persistence operations.

### XPService

Owns:

- XP normalization
- XP addition
- level progression
- XP cap

`XPConfig` is the canonical balancing source.

### EconomyService

Owns:

- Money normalization
- Add/Remove
- affordability
- selling
- Money caps

### InventoryService

Owns:

- item validation
- stack limits
- Add/Remove/Has
- inventory normalization

Other systems must not invent independent inventory rules.

### CrystalService / CrystalSystem

`CrystalSystem` provides the core ownership and equip logic.

`CrystalService` is the server-service facade.

Crystal unlock validation must remain inside the canonical CrystalSystem boundary, including level gates.

### CrystalMastery

Owns:

- Mastery levels
- Mastery XP
- level caps
- Mastery bonuses
- upgrade costs

### CrystalAbilityService

Owns Crystal-specific server ability behavior that is not appropriate for the generic CombatService.

Examples currently include:

- TIDE healing
- GALE splash

It may calculate/execute ability-specific server behavior, but it must still use centralized damage validation.

### DamageService

This is the authoritative damage application boundary.

Pipeline:

```text
Damage Request
    ↓
DamageValidators
    ↓
Attacker validation
    ↓
Target validation
    ↓
DamageType validation
    ↓
Range validation
    ↓
Dodge validation
    ↓
Humanoid damage
    ↓
Applied HP delta
    ↓
DamageResult
```

`DamageService` is the only direct `Humanoid:TakeDamage()` path in `src`.

### CombatService

Owns:

- client attack-request validation
- action whitelist
- combat request rate limiting
- Crystal resolution
- critical hit resolution
- combat cooldown state
- DamageService orchestration
- server-confirmed CombatFeedback
- XP/Money/mastery/quest/bounty defeat progression

It must not own cosmetic VFX implementation.

### CombatModifierService

Owns server-side combat modifiers such as critical chance and critical multiplier.

### DodgeService

Owns:

- dodge cooldown
- invulnerability window
- movement direction validation
- ForceField protection
- damage routing through DamageService
- respawn cleanup
- player-leave cleanup

### StatusEffectService

Owns bounded status effects such as:

- Burn
- Slow

Effects are tokenized so stale delayed callbacks cannot cancel newer effects.

Status effects must respect Dodge and Character lifecycle.

### NPCService / AIPathService

NPCService owns:

- enemy creation
- AI loop
- target acquisition
- attacks
- special attacks
- health bars
- enemy death lifecycle
- status cleanup

AIPathService owns:

- PathfindingService use
- weak-key path cache
- path recomputation throttling
- jump waypoints

### BossService / BossTelegraph / BossArena

BossService owns Guardian lifecycle, phases, rewards and boss damage orchestration.

BossTelegraph owns the delayed telegraph presentation/attack timing.

Telegraph delayed callbacks must be bound to the concrete Guardian instance, not only its name.

BossArena owns environment/hazard behavior.

### QuestSystem / QuestService

QuestSystem owns canonical quest definitions, chain order, start rules and progress rules.

QuestService owns server-side completion and reward orchestration.

A quest may only reward once and normal quests require their objective goal before completion.

### DailyBountyService

Owns:

- UTC day rotation
- canonical Goal/Reward values from `DailyBountyConfig`
- persistent progress
- one-time reward claim

Persisted reward values must never override canonical config values.

### AchievementSystem

Owns canonical Achievement definitions, order and Titles.

Titles are derived from earned Achievement IDs; standalone persisted title strings are not trusted as authority.

## 5. Remote security

The client may request actions. The server decides outcomes.

Clients never authoritatively decide:

- damage
- hit success
- Crystal ownership
- Crystal unlock
- rarity
- rewards
- XP
- Money
- inventory grants
- boss damage
- quest completion

Critical RemoteFunctions must have exactly one `OnServerInvoke` owner.

Critical RemoteEvents must have a single clear server ownership/handler direction.

Server request paths use rate limits where appropriate.

## 6. Combat presentation

Combat presentation is cosmetic.

`CombatFeedback` is server-published after successful damage.

`CombatPresentation.client.lua` consumes confirmed hit data for:

- damage numbers
- hit flash
- impact presentation
- camera/player reaction

`CrystalAnimationController.client.lua` is local presentation only.

The character `Animator` is created server-side by PlayerService.

`ConfirmedCombatVFXBridge.client.lua` converts confirmed CombatFeedback for the local attacker into a one-shot authorization for `CrystalVFXController`.

Animation markers must never own gameplay authority.

## 7. Transactions

Shop, Crafting and Consumables use a validate → mutate → verify/rollback pattern.

Examples:

```text
Shop
  validate offer
  validate amount
  validate price
  validate inventory space
  remove Money
  add item
  rollback Money if item insertion fails
```

```text
Crafting
  validate recipe
  validate inputs
  validate output space
  remove inputs
  add output
  rollback inputs if output insertion fails
```

## 8. Persistence and migration

Profile data is canonicalized when loaded.

Normalization covers:

- level / XP
- money
- inventory
- Crystal ownership
- Mastery
- stats
- quests
- achievements
- titles
- islands
- Daily Bounty
- session lock fields

Unknown inventory, Crystal, quest, achievement, title and island identifiers must not silently become valid game state.

## 9. World architecture

Current world islands:

- Starter Island
- Tide Island
- Wind Island
- Ancient Ruins

The third island is intended to become an important central hub in the long-term design.

Portals use `WorldConfig` level gates.

The world must remain expandable without forcing a purely linear island layout.

## 10. Crystal acquisition

Current prototype behavior uses Crystal level gates for EMBER/TIDE/GALE.

The long-term design also includes:

- Mining
- Digging
- Bosses
- Dungeons
- World Events
- Quests

The final acquisition model is intentionally not locked yet and must be decided before deeper acquisition systems are built.

## 11. Mobile

Mobile shares the same server gameplay rules as PC.

Touch controls are input/presentation only.

The server performs the exact same combat, Dodge and progression validation regardless of client input method.

## 12. Performance

Current performance safeguards include:

- weak-key per-player state
- weak-key AI path cache
- bounded NPC AI loop cadence
- pathfinding recomputation throttling
- CombatFeedback distance culling
- limited client presentation event budget
- BossBar update throttling
- rate-limited RemoteFunctions/RemoteEvents

Future large-scale NPC populations require real Studio performance profiling.

## 13. Testing

Static validation is extensive, but static checks are not equivalent to Roblox runtime testing.

`STUDIO_PLAYTEST.md` is the source of truth for the first real runtime verification.

No feature should be considered production-ready until:

1. static contracts pass
2. Roblox Studio runtime test passes
3. multiplayer behavior is checked
4. performance is checked
5. relevant edge cases are recorded

## 14. Non-goals

Do not:

- merge into `main` without approval
- reintroduce legacy SaveSystem
- reintroduce legacy Crystal registries
- make client animation markers gameplay authority
- add client-side damage
- silently rewrite story
- treat Ancient as a rarity
- implement the second world early
- create unnecessary God Services
