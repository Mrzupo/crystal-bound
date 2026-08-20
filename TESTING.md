# Crystal Bound — Testing Contract

## Ziel

Dieses Dokument beschreibt die aktuellen statischen und manuellen Tests für Crystal Bound.

Wichtig: Ein statischer Contract oder Code-Review ersetzt keinen echten Roblox-Studio-Runtime-Test.

## Voraussetzungen

- Roblox Studio
- Rojo mit `default.project.json`
- Studio Access to API Services für DataStore-Tests
- Server-Test für serverautoritatives Verhalten
- Für Multiplayer-Tests mindestens zwei Testspieler

## 1. Static validation

Vor jedem Runtime-Test:

- `default.project.json` muss alle referenzierten Dateien finden.
- JSON-Dateien müssen parsebar sein.
- zentrale `require`-Pfade müssen existieren.
- RemoteEvent/RemoteFunction Ownership muss eindeutig sein.
- keine unerwarteten `Humanoid:TakeDamage()`-Pfade außerhalb `DamageService`.
- keine Legacy-Save-/Crystal-Module dürfen in Rojo auftauchen.
- Rarity muss Common → Divine sein.
- Ancient darf nicht als Rarity auftauchen.
- Crystal Unlock-Gates müssen aus `CrystalConfig.UnlockLevels` kommen.
- Achievement Titles müssen aus Achievement-IDs abgeleitet werden.
- Daily Bounty Rewards müssen aus `DailyBountyConfig` kommen.

## 2. Boot / World initialization

### Test

1. Starte einen Server-Test.
2. Trete mit einem Spieler bei.
3. Prüfe Roblox Output.
4. Prüfe Workspace.

### Erwartung

- Profil lädt sicher.
- Bei Load-Fehlern wird kein leeres Profil erzeugt.
- `Crystal Bound`-Runtime wird geladen.
- Starter Island, Tide Island, Wind Island und Ancient Ruins existieren.
- NPCs und Spawn existieren.
- WorldDecor/WorldTheme initialisieren nicht doppelt.
- Crystal Guardian existiert genau einmal.

## 3. Persistence

### Neues Profil

Erwartet:

- Level 1
- XP 0
- EMBER besessen und ausgerüstet
- Money = `EconomyConfig.StartingMoney`
- gültige Default-Bounty
- leeres Inventar

### Save / Rejoin

1. Level verändern.
2. Money verändern.
3. Item hinzufügen.
4. Crystal Mastery verändern.
5. Questfortschritt verändern.
6. Spieler normal verlassen.
7. Erneut beitreten.

Erwartung:

- Werte bleiben erhalten.
- Reconciliation entfernt ungültige IDs.
- Mastery-Caps bleiben korrekt.
- Inventar bleibt innerhalb MaxStack.

### Session Lock

1. Server A startet und besitzt Profil-Lock.
2. Controlled Test für parallelen Serverzugriff.
3. Server B versucht das gleiche Profil zu laden.

Erwartung:

- Server B bekommt keinen gültigen Besitz solange Lock aktiv ist.
- Lock wird nicht still überschrieben.
- Heartbeat verlängert einen gesunden Lock.
- wiederholter Heartbeat-Verlust beendet die Session sicher.

## 4. Crystal system

### EMBER

- Start-Crystal vorhanden.
- Basic Attack funktioniert.
- Flame Burst funktioniert.

### TIDE

- Level-Gate wird serverseitig geprüft.
- Tidal Pulse funktioniert.
- MaxHealth-Passive wirkt.

### GALE

- Level-Gate wird serverseitig geprüft.
- Gale Strike funktioniert.
- Splash trifft nur gültige Enemy-Modelle innerhalb der konfigurierten Reichweite.

### Security

- Manipulierte Crystal-ID wird abgewiesen.
- Nicht besessene Crystal-ID kann nicht ausgerüstet werden.
- Client kann Unlock-Gate nicht umgehen.

## 5. Crystal Mastery

Testfälle:

- XP addieren.
- Level-Up.
- Max-Level.
- Max-XP.
- Upgrade-Kosten.
- fehlende Materialien.
- volle Output-Stacks.
- ungültige/negative/NaN Werte.

Erwartung:

- keine negativen Mastery-Werte.
- kein Level über MaxLevel.
- auf MaxLevel bleibt XP 0.
- ungültige Eingaben erzeugen keinen Fortschritt.

## 6. Combat

### Basic Attack

- Enemy in Range trifft.
- Enemy außerhalb Range wird abgewiesen.
- toter Enemy wird abgewiesen.
- Player-Target wird abgewiesen.
- eigener Character als Target wird abgewiesen.

### Ability

- Server-Cooldown wird eingehalten.
- clientseitige Cooldown-Anzeige ist nur Presentation/Input-Throttle.
- Server entscheidet endgültig.

### Critical

- kritischer Treffer verändert Damage serverseitig.
- Crit-State wird nicht dauerhaft am Target gespeichert.
- Damage Numbers zeigen Crit nur bei bestätigtem Treffer.

## 7. DamageService / security

Versuche:

- negativer Schaden
- NaN / Infinity
- unbekannter DamageType
- Range 0
- negative Range
- Range > 1000
- ungültiger Attacker
- ungültiges Target
- Player-vs-Player
- Dodge während Treffer

Erwartung:

- Request wird abgewiesen oder landet bei 0 applied damage.
- keine Economy-/XP-/Loot-Seitenwirkung bei abgelehntem Treffer.

## 8. Dodge

Test:

- normaler Dodge
- Spam
- ungültiger Vector
- NaN/Infinity Vector
- Dodge während Incoming Hit
- Respawn während Dodge
- Leave während Dodge

Erwartung:

- Cooldown serverseitig.
- kurze Invulnerability.
- ForceField wird entfernt.
- neuer Character startet ohne Dodge-Zustand.

## 9. Status Effects

### Burn

- bounded tick count.
- bounded damage.
- bounded interval.
- stoppt bei Tod.
- ignoriert Dodge.

### Slow

- bounded multiplier.
- bounded duration.
- neuer Slow kann alten Token nicht falsch beenden.
- Crystal/Mastery-Sync zerstört aktiven Slow nicht.
- Respawn entfernt alten Zustand.

## 10. Enemy AI

Für jeden Enemy-Typ:

- Aggro
- Movement
- Attack
- Special
- Status Effect
- Leash
- Pathfinding
- Jump waypoint
- Death
- Respawn

Erwartung:

- kein NPC bleibt nach Tod aktiv.
- keine alten Status-Callbacks bleiben bestehen.
- keine Doppelspawns.
- Spezialangriffe nutzen `Special.Range`.
- Respawn-Wert bleibt kompatibel mit Cleanup-Lifecycle.

## 11. Guardian

- Phase 1 → Phase 2 unter 50% HP.
- Arena Hazard.
- Telegraph sichtbar.
- Telegraph verschwindet/stoppt bei Boss-Tod.
- neuer Guardian wird nicht von altem Telegraph getroffen.
- Dodge verhindert Shockwave-Schaden.
- Reward genau einmal.
- Quest Reward genau einmal.
- Respawn genau einmal.

## 12. Quests

- FIRST_FIGHT startet korrekt.
- CRYSTAL_POWER wird nur durch tatsächlichen Ability-Fortschritt erhöht.
- normale Quest benötigt Ziel-Fortschritt vor Abschluss.
- Quest-Reihenfolge kann nicht übersprungen werden.
- Quest-Reward nur einmal.
- ungültige Progress-Mengen werden abgewiesen.
- GetQuestData und GetAvailableQuests sind rate-limited.

## 13. Daily Bounty

- UTC-Tageswechsel.
- korrekter EnemyType.
- Goal entspricht Config.
- Reward entspricht Config.
- Progress bounded.
- Claim genau einmal.
- MaxMoney-Clamp verwendet den tatsächlichen Delta-Wert.
- manipuliertes RewardMoney aus Save wird nicht vertrauenswürdig übernommen.
- kontrolliert korrumpiertes `Claimed=true` bei `Progress<Goal` wird beim Reconcile auf `Claimed=false` normalisiert.

## 14. Economy / Inventory / Crafting

### Shop

- genug Geld.
- zu wenig Geld.
- volle Stacks.
- MaxPerPurchase.
- ungültige Amounts.
- Rollback bei failed insertion inklusive Rücknahme einer eventuell teilweisen Inventory-Insertion.

### Selling

- Item vorhanden.
- Item nicht vorhanden.
- HealthPotion nicht verkäuflich.
- MaxMoney-Clamp.
- Item-Rollback bei fehlender Credit-Kapazität.

### Crafting

- gültiges Rezept.
- ausreichende Inputs.
- fehlende Inputs.
- voller Output-Stack.
- ungültiges Rezept.
- Rollback bei fehlender Output-Insertion inklusive Entfernen einer eventuell teilweisen Output-Insertion.

### Health Potion

- nur bei existierendem Item.
- nicht bei voller HP.
- nicht bei totem Character.
- genau eine Potion pro Nutzung.
- 0,2s serverseitiges Gate gegen Spam.

## 15. NPC / Dialog

- Crystal Keeper in Reichweite öffnet Dialog.
- Material Trader in Reichweite öffnet Dialog.
- NPC außerhalb Reichweite kann nicht als serverautoritative Menüquelle genutzt werden.
- QUEST öffnet QuestMenu.
- CRYSTAL öffnet CrystalMenu.
- SHOP öffnet ShopMenu.
- INVENTORY öffnet das kombinierte Inventory/Crystal-Menü.
- CRAFT öffnet CraftingMenu.
- Dialog schließt beim Übergang ins Zielmenü.
- Trigger Dialog auf altem Character und respawne vor dem deferred Menu-Open; erwartet: der alte Callback darf kein Menü für den neuen Character öffnen.

## 16. PC / Mobile

PC:

- Basic attack
- Ability
- Dodge
- Inventory
- Quest
- Shop
- Crafting
- Achievement

Mobile:

- Touch target selection
- Basic attack
- Ability
- Dodge
- same server cooldowns
- same server damage validation
- same reward results

## 17. Animation / VFX / Audio

### Before authored assets

- fehlende AnimationId darf keinen Runtime-Crash erzeugen.
- fehlende SoundId darf keinen Runtime-Crash erzeugen.
- VFX bleibt cosmetic.

### After authored assets

Zuerst EMBER:

1. Basic animation
2. Flame Burst animation
3. Hit VFX
4. sound
5. server confirmation

Danach exakt denselben Vertrag für TIDE und GALE.

Wichtig: Animation markers dürfen niemals XP, Damage, Rewards oder Hit detection auslösen.

## 18. Runtime performance

Während Studio-Test prüfen:

- NPC CPU usage
- Pathfinding frequency
- Remote event frequency
- RenderStep loops
- GUI creation/destruction
- VFX cleanup
- memory after player leave
- memory after repeated respawns

## 19. Regression checklist

Vor jeder großen Änderung:

- keine Legacy SaveSystem references
- keine Legacy Crystal modules
- kein Legacy StatusSpeedGuard mapping
- keine direkten `TakeDamage()`-Pfade außerhalb DamageService
- keine doppelte `OnServerInvoke` ownership
- keine unbestätigten Hit-VFX
- keine falschen Rarity definitions
- Ancient bleibt keine Rarity
- White Queen Story unverändert
- zweite Welt bleibt langfristig geheim
- `main` bleibt unangetastet
