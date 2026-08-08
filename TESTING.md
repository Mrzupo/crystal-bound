# Testing

Dieses Dokument beschreibt, wie die aktuellen Kernsysteme von Crystal Fight getestet werden:

- `SaveSystem`
- `PlayerData`
- `XPService`
- `EconomyService`
- `InventoryService`
- `CrystalService`
- Crystal Ability Framework
- Damage Pipeline Framework

## Ziel

Die Tests sollen bestaetigen, dass persistente Spielerprofile, XP, Geld, Inventar und Crystal Framework v1 korrekt serverseitig funktionieren. Beim Crystal Framework wird nur Besitz und Ausruestung getestet. Faehigkeiten, Schaden, Animationen, VFX und UI sind nicht Teil dieses Testumfangs.

Die Damage Pipeline wird aktuell nur auf Datenmodell, Validierung und Result-Erzeugung getestet. Es wird kein Humanoid beschaedigt.

## Voraussetzungen

- Roblox Studio Projekt mit der Struktur aus `default.project.json`
- API Services in Roblox Studio aktiviert, damit `DataStoreService` im Test funktioniert
- Test im Server-Kontext, nicht nur als reiner Client-Test

In Roblox Studio:

1. `Game Settings` oeffnen.
2. `Security` oeffnen.
3. `Enable Studio Access to API Services` aktivieren.
4. Projekt speichern und erneut testen.

## Testfaelle

## SaveSystem testen

### Neues Profil

1. Spiel in Roblox Studio starten.
2. Dem Spiel als Testspieler beitreten.
3. Pruefen, ob `SaveSystem.GetProfile(player)` ein Profil zurueckgibt.

Erwartung:

- `Level` ist `1`
- `Experience` ist `0`
- `Money` kommt aus `EconomyConfig.StartingMoney`
- alle Felder aus `PlayerData.GetDefaultProfile()` sind vorhanden

### Bestehendes Profil laden

1. Spiel starten.
2. Profilwerte serverseitig veraendern, zum Beispiel durch `XPService.AddXP` oder `EconomyService.AddMoney`.
3. Spiel verlassen, damit gespeichert wird.
4. Spiel erneut starten.

Erwartung:

- gespeicherte Werte werden geladen
- neue Felder aus dem Schema werden automatisch ergaenzt
- fehlende Felder verursachen keinen Absturz

### Autosave

1. Spiel starten.
2. Profilwerte veraendern.
3. Mindestens 60 Sekunden warten.
4. Server stoppen und neu starten.

Erwartung:

- Werte wurden durch Autosave gespeichert
- keine manuelle UI-Aktion ist erforderlich

### Server-Shutdown

1. Spiel starten.
2. Profilwerte veraendern.
3. Server stoppen.

Erwartung:

- `BindToClose` versucht aktive Profile final zu speichern
- parallele Saves werden nicht gleichzeitig auf denselben Spieler angewendet

## XPService testen

### XP hinzufuegen

Serverseitig:

```lua
local XPService = require(game.ServerScriptService.Services.XPService)
XPService.AddXP(player, 50)
```

Erwartung:

- `Experience` steigt um `50`
- `XPChanged` wird an den Client gesendet
- `GetXP(player)` gibt den aktuellen XP-Wert zurueck

### Level-Up

Serverseitig:

```lua
local XPService = require(game.ServerScriptService.Services.XPService)
XPService.AddXP(player, 100000)
```

Erwartung:

- der Spieler steigt automatisch im Level
- mehrere Level-Ups in einem Aufruf werden verarbeitet
- `LevelUp` wird gesendet, wenn mindestens ein Level gewonnen wurde
- benoetigte XP kommt aus `XPConfig.GetRequiredXP(level)`

## EconomyService testen

### Geld hinzufuegen

Serverseitig:

```lua
local EconomyService = require(game.ServerScriptService.Services.EconomyService)
EconomyService.AddMoney(player, 100)
```

Erwartung:

- `Money` steigt um `100`
- `MoneyChanged` wird an den Client gesendet
- `GetMoney(player)` gibt den aktuellen Wert zurueck

### Geld entfernen

Serverseitig:

```lua
local EconomyService = require(game.ServerScriptService.Services.EconomyService)
EconomyService.RemoveMoney(player, 50)
```

Erwartung:

- Geld wird nur entfernt, wenn genug Geld vorhanden ist
- `Money` wird niemals negativ
- `RemoveMoney` gibt `false` zurueck, wenn der Spieler nicht genug Geld hat

### Kaufpruefung

Serverseitig:

```lua
local EconomyService = require(game.ServerScriptService.Services.EconomyService)
local canBuy = EconomyService.CanAfford(player, 250)
```

Erwartung:

- `true`, wenn `Money >= 250`
- `false`, wenn nicht genug Geld vorhanden ist
- keine Profildaten werden veraendert

## InventoryService testen

### Item hinzufuegen

Serverseitig:

```lua
local InventoryService = require(game.ServerScriptService.Services.InventoryService)
InventoryService.AddItem(player, "CrystalShard", 5)
```

Erwartung:

- `Inventory.CrystalShard` steigt um `5`
- `InventoryChanged` wird an den Client gesendet
- die Stackgroesse wird aus `InventoryConfig.GetMaxStackSize(itemId)` gelesen

### Item entfernen

Serverseitig:

```lua
local InventoryService = require(game.ServerScriptService.Services.InventoryService)
InventoryService.RemoveItem(player, "CrystalShard", 2)
```

Erwartung:

- der Bestand wird nur reduziert, wenn genug Items vorhanden sind
- bei Bestand `0` wird der Eintrag aus dem Inventar entfernt
- `RemoveItem` gibt `false` zurueck, wenn der Spieler zu wenig Items hat

### Item pruefen

Serverseitig:

```lua
local InventoryService = require(game.ServerScriptService.Services.InventoryService)
local hasItem = InventoryService.HasItem(player, "CrystalShard")
```

Erwartung:

- `true`, wenn der Spieler mindestens ein Item besitzt
- `false`, wenn der Spieler das Item nicht besitzt
- keine Profildaten werden veraendert

### Inventar lesen

Serverseitig:

```lua
local InventoryService = require(game.ServerScriptService.Services.InventoryService)
local inventory = InventoryService.GetInventory(player)
```

Erwartung:

- es wird eine Kopie des Inventars zurueckgegeben
- direkte Mutation des Rueckgabewerts veraendert nicht automatisch das Profil

## CrystalService testen

### Definitionen pruefen

Serverseitig oder in einem shared Modul:

```lua
local CrystalSystem = require(game.ReplicatedStorage.Modules.CrystalSystem)
print(CrystalSystem.IsValid("EMBER"))
print(CrystalSystem.GetDefinition("TIDE"))
```

Erwartung:

- `EMBER`, `TIDE` und `GALE` sind gueltig
- ungueltige IDs geben `false` oder `nil` zurueck
- `CrystalUtils` veraendert keine Playerdaten

### Kristall freischalten

Serverseitig:

```lua
local CrystalService = require(game.ServerScriptService.Services.CrystalService)
CrystalService.UnlockCrystal(player, "EMBER")
```

Erwartung:

- `EMBER` wird in `PlayerData.Crystals.Owned` gespeichert
- erneutes Freischalten von `EMBER` gibt `false` zurueck
- ungueltige IDs werden abgelehnt
- Definitionen werden nicht in PlayerData gespeichert

### Kristall ausruesten

Serverseitig:

```lua
local CrystalService = require(game.ServerScriptService.Services.CrystalService)
CrystalService.UnlockCrystal(player, "EMBER")
CrystalService.EquipCrystal(player, "EMBER")
```

Erwartung:

- `PlayerData.Crystals.Equipped` ist `"EMBER"`
- es ist immer nur ein Kristall ausgeruestet
- nicht freigeschaltete Kristalle koennen nicht ausgeruestet werden

### Kristalle lesen

Serverseitig:

```lua
local CrystalService = require(game.ServerScriptService.Services.CrystalService)
local owned = CrystalService.GetOwnedCrystals(player)
local equipped = CrystalService.GetEquippedCrystal(player)
```

Erwartung:

- `GetOwnedCrystals` gibt eine Kopie der IDs zurueck
- `GetEquippedCrystal` gibt die ausgeruestete ID oder `""` zurueck

### Ability-Basisklasse pruefen

Serverseitig oder in einem isolierten Module-Test:

```lua
local BaseCrystal = require(game.ReplicatedStorage.Modules.Crystal.Abilities.BaseCrystal)
local ability = BaseCrystal.new("EMBER")

print(ability:Initialize(player))
print(ability:CanActivate())
print(ability:Activate())
print(ability:Deactivate())
print(ability:GetCooldown())
ability:Destroy()
```

Erwartung:

- `Initialize` setzt nur Basiszustand
- `CanActivate` prueft nur Initialisierung und aktiven Zustand
- `Activate` und `Deactivate` veraendern nur `IsActive`
- `GetCooldown` gibt `0` zurueck
- es wird kein Schaden, keine Animation, kein VFX und kein Cooldown-System ausgefuehrt

### AbilityRegistry pruefen

Serverseitig:

```lua
local AbilityRegistry = require(game.ReplicatedStorage.Modules.Crystal.Abilities.AbilityRegistry)
local ability = AbilityRegistry.CreateAbility("EMBER")
```

Erwartung:

- nicht registrierte Kristalle erhalten eine `BaseCrystal`-Instanz
- Registry enthaelt keine Gameplay-Logik
- ungueltige Registrierungen geben `false` zurueck

### CrystalService Ability-Platzhalter pruefen

Serverseitig:

```lua
local CrystalService = require(game.ServerScriptService.Services.CrystalService)
CrystalService.UnlockCrystal(player, "EMBER")
CrystalService.EquipCrystal(player, "EMBER")

local ability = CrystalService.GetActiveAbility(player)
local canUse = CrystalService.CanUseAbility(player)
local activated = CrystalService.ActivateAbility(player)
local deactivated = CrystalService.DeactivateAbility(player)
```

Erwartung:

- `GetActiveAbility` erzeugt eine Placeholder-Ability fuer den ausgeruesteten Kristall
- `CanUseAbility` delegiert an `BaseCrystal.CanActivate`
- `ActivateAbility` delegiert an `BaseCrystal.Activate`
- `DeactivateAbility` delegiert an `BaseCrystal.Deactivate`
- keine echte Combat-Logik wird ausgefuehrt

## Damage Pipeline testen

### DamageRequest erstellen

Serverseitig:

```lua
local CombatSystem = require(game.ReplicatedStorage.Modules.CombatSystem)
local request = CombatSystem.DamageRequest.new(player, target, 10, CombatSystem.DamageTypes.Crystal, "EMBER")
```

Erwartung:

- Request enthaelt `Attacker`, `Target`, `Damage`, `DamageType`, `CrystalId` und `Timestamp`
- es wird keine Validierung und kein Schaden ausgefuehrt

### DamageService validieren

Serverseitig:

```lua
local DamageService = require(game.ServerScriptService.Services.DamageService)
local result = DamageService.ValidateRequest(request)
```

Erwartung:

- gueltige Requests geben `Success = true`
- ungueltiger Angreifer gibt `INVALID_ATTACKER`
- ungueltiges Ziel gibt `INVALID_TARGET`
- Schaden `<= 0` gibt `DAMAGE_NOT_POSITIVE`
- unbekannter DamageType gibt `UNKNOWN_DAMAGE_TYPE`

### Damage vorbereiten

Serverseitig:

```lua
local processed = DamageService.ProcessDamage(request)
local applied = DamageService.ApplyDamage(request)
```

Erwartung:

- `ProcessDamage` validiert und gibt `FinalDamage = request.Damage`
- `ApplyDamage` gibt `NOT_APPLIED_FRAMEWORK_ONLY`
- kein Humanoid und kein Spielzustand wird veraendert

## Beruecksichtigte Randfaelle

- DataStore-Zugriffe laufen mit `pcall`
- DataStore-Zugriffe werden mehrfach versucht
- fehlgeschlagenes Laden erzeugt nur ein unsicheres In-Memory-Profil
- unsicher geladene Profile werden nicht automatisch gespeichert
- fehlende neue Schemafelder werden beim Laden ergaenzt
- ungueltige Profile werden verworfen und durch Standardwerte ersetzt
- parallele Saves fuer denselben Spieler werden begrenzt
- Autosave speichert aktive Profile regelmaessig
- Spieler-Verlassen loest Speichern aus
- Server-Shutdown loest Speichern aus
- XP-Mengen werden auf ganze positive Zahlen normalisiert
- negative oder ungueltige XP-Mengen werden abgelehnt
- mehrere Level-Ups in einem XP-Aufruf werden verarbeitet
- Geld-Mengen werden auf ganze positive Zahlen normalisiert
- negative oder ungueltige Geld-Mengen werden abgelehnt
- Geld wird auf `EconomyConfig.MinMoney` und `EconomyConfig.MaxMoney` begrenzt
- `RemoveMoney` verhindert negative Kontostaende
- Inventar-Mengen werden auf ganze positive Zahlen normalisiert
- leere oder ungueltige ItemIds werden abgelehnt
- Item-Stapel werden durch `InventoryConfig` begrenzt
- Entfernen von Items erlaubt keine negativen Bestaende
- alte array-basierte Inventarplatzhalter werden beim Laden in eine Item-Map migriert
- Crystal IDs werden gegen `CrystalDefinitions` validiert
- doppelte Kristalle werden abgelehnt
- ungueltige gespeicherte Kristall-IDs werden bereinigt
- ein ausgeruesteter Kristall muss auch in `Owned` enthalten sein
- Ability-Platzhalter werden beim Wechsel des ausgeruesteten Kristalls zerstoert
- Ability-Platzhalter werden beim Verlassen des Spielers bereinigt
- Damage Requests ohne Angreifer oder Ziel werden abgelehnt
- nicht-positive, NaN- und Infinite-Damage-Werte werden abgelehnt
- unbekannte DamageTypes werden abgelehnt

## Fehlerbehandlung

- Oeffentliche Service-Funktionen geben bei ungueltigen Eingaben `false` oder `nil` zurueck.
- Ungueltige Crystal IDs erzeugen Warnungen und werden nicht gespeichert.
- Fehlende Profile werden nicht still ignoriert; Services warnen und brechen ab.
- DataStore-Fehler werden im `SaveSystem` mit Retry-Logik behandelt.

## Sicherheit

- Crystal Framework v1 nutzt keine Crystal-RemoteEvents.
- Der Client darf keine Kristalle freischalten oder ausruesten.
- `CrystalService` ist der einzige vorgesehene Schreibzugriff auf `PlayerData.Crystals`.
- Definitionen werden nicht in PlayerData gespeichert.
- Ability-Aktivierung ist aktuell nur serverseitiger Platzhalter ohne Remotes.
- Damage Pipeline hat keine Client-Remotes und wendet keinen Schaden an.

## Performance

- Crystal-Lookups erfolgen ueber Dictionary-Zugriff per ID.
- `GetOwnedCrystals` gibt eine Kopie zurueck, um direkte Mutation zu verhindern.
- Die aktuelle Datenmenge ist klein; `MaxOwnedCrystals` begrenzt Wachstum.
- AbilityRegistry faellt ohne Lookup-Kosten fuer konkrete Klassen auf `BaseCrystal` zurueck.
- DamageType-Validierung nutzt Dictionary-Lookups.

## Bekannte Einschraenkungen

- Es gibt noch keine automatisierten Luau-Unit-Tests.
- DataStore-Verhalten kann in Studio von Live-Servern abweichen.
- Es gibt noch keine Session-Lock-Implementierung gegen gleichzeitige Server-Sessions desselben Spielers.
- `SaveSystem` nutzt einfache Retry-Logik, aber noch keine Backoff-Strategie mit zufaelliger Streuung.
- Es gibt noch kein Admin-Testkommando und keine Debug-Konsole im Spiel.
- RemoteEvents informieren nur spaetere UI-Systeme; es gibt aktuell keine UI, die diese Events anzeigt.
- Shop- und Haendlerlogik ist vorbereitet, aber noch nicht implementiert.
- Economy- und XP-Aenderungen werden im Profil aktualisiert, aber nicht sofort nach jedem Aufruf gespeichert; Persistenz erfolgt ueber Autosave, Verlassen oder Shutdown.
- Inventory-Aenderungen werden im Profil aktualisiert, aber nicht sofort nach jedem Aufruf gespeichert; Persistenz erfolgt ueber Autosave, Verlassen oder Shutdown.
- Es gibt noch keine Gewichtslimits, Slotlimits, Item-Rarities oder serverseitige Drop-Tabellen.
- Crystal Framework v1 enthaelt noch keine Faehigkeiten, keinen Schaden, keine Animationen, keine VFX, keine Cooldowns und keine UI.
- Ability Framework enthaelt keine echten Ability-Klassen, keine Hitboxen, keine Ressourcen, keine Status-Effekte und keine Cooldown-Berechnung.
- Damage Pipeline enthaelt keine Schadensformeln, keine Hitboxen, kein Blocken, kein Ausweichen, keine kritischen Treffer, keine Ruestung und keine NPC-KI.

## Naechste Erweiterungen

- Crystal-Level und Upgrade-Kosten definieren.
- Combat-System an `GetEquippedCrystal` anbinden.
- Serverseitige Reward-Systeme an `UnlockCrystal` anbinden.
- Konkrete Ability-Klassen registrieren, sobald das Combat-System spezifiziert ist.
- Passive Faehigkeiten im `PassiveRegistry` formal definieren.
- DamageTarget-Modell fuer Spieler, NPCs und Umweltschaden definieren.
- Erst nach Zielmodell echten Humanoid-Schaden in `ApplyDamage` ergaenzen.
- Optional spaeter sichere Remotes fuer reine Client-Anfragen planen.
