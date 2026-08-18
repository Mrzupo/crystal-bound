# Crystal Bound

Professionelles Roblox/Luau-Grundgeruest fuer ein spaeter erweiterbares Spiel.

Dieses Projekt enthaelt bewusst noch keine Spielmechaniken. Es bereitet nur die Architektur, Ordnerstruktur und zentrale Module vor.

## Struktur

```text
ReplicatedStorage
  Modules
    PlayerData
    CombatSystem
    Combat
      DamageRequest
      DamageResult
      DamageTypes
      DamageValidators
    CrystalSystem
    Crystal
      CrystalDefinitions
      CrystalTypes
      CrystalUtils
      Abilities
        BaseCrystal
        AbilityRegistry
        PassiveRegistry
    QuestSystem
    NPCSystem
    InventorySystem
    SaveSystem
  Config
    GameConfig
    CrystalConfig
    EnemyConfig
    XPConfig
    EconomyConfig
    InventoryConfig
  Shared
    Constants
    Enums
    Utility
  Remotes
    CombatRequest
    QuestRequest
    NPCRequest
    InventoryRequest
    GetPlayerData
    GetQuestData
    XPChanged
    LevelUp
    MoneyChanged
    InventoryChanged
  Assets
    Animations
    Sounds
    Particles
    Icons

ServerScriptService
  Systems
  Services
    PlayerService
    CombatService
    DamageService
    QuestService
    CrystalService
    NPCService
    XPService
    EconomyService
    InventoryService
  Bootstrap

StarterPlayer
  StarterPlayerScripts
    ClientBootstrap

StarterGui
  MainUI

Workspace
  NPCs
  Islands
  Spawn
```

## Nutzung mit Roblox Studio

1. Oeffne Roblox Studio.
2. Erstelle die Ordner wie oben beschrieben oder nutze `default.project.json` mit Rojo.
3. Fuege die Luau-Dateien an den passenden Stellen ein.
4. Erweitere die vorbereiteten Module spaeter Schritt fuer Schritt.

Weitere Testhinweise stehen in `TESTING.md`.

## Hinweis

Alle Module, Config-Dateien, Shared-Dateien und Services sind als saubere Grundlage vorbereitet. `SaveSystem` und `PlayerData` bilden das erste voll funktionsfaehige System fuer persistente Spielerprofile.

## Architektur-Rollen

- `Modules` enthaelt groessere fachliche Systeme, die spaeter erweitert werden.
- `Config` enthaelt vorbereitete Konfigurationstabellen fuer Balancing und Definitionen.
- `Shared` enthaelt gemeinsam genutzte Konstanten, Enum-Tabellen und kleine Hilfsfunktionen.
- `Services` enthaelt serverseitige Autoritaet und Lebenszyklus-Module.

## PlayerData Schema

Das vorbereitete Profil enthaelt aktuell:

- `Level`
- `Experience`
- `Crystals`
- `Money`
- `Stats`
- `Inventory`
- `ActiveQuests`
- `CompletedQuests`
- `UnlockedIslands`
- `Titles`

## SaveSystem

Das SaveSystem nutzt `DataStoreService` und laedt beim Betreten eines Spielers ein Profil aus dem vorhandenen `PlayerData`-Schema. Wenn keine Daten vorhanden sind, wird ein neues Standardprofil erstellt.

Vorbereitet sind:

- Laden per `GetAsync`
- Speichern per `UpdateAsync`
- `pcall` und Retry-Logik fuer alle DataStore-Zugriffe
- Autosave alle 60 Sekunden
- Speichern beim Verlassen
- Speichern bei Server-Shutdown
- Schema-Reconciliation, damit neue Felder aus `PlayerData` automatisch ergaenzt werden
- Schutz gegen versehentliches Ueberschreiben, wenn ein Profil nicht sicher geladen wurde

In Roblox Studio muessen API Services aktiviert sein, damit DataStores im Test funktionieren.

## XP- und Levelsystem

`XPService` ist das erste Gameplay-System. Es nutzt das geladene `PlayerData`-Profil und stellt serverseitig diese Funktionen bereit:

- `AddXP(player, amount)`
- `GetLevel(player)`
- `GetXP(player)`

Die benoetigte XP pro Level kommt aus `XPConfig.GetRequiredXP(level)`. Dadurch bleibt Balancing getrennt vom Service-Code.

Vorbereitet fuer spaetere UI:

- `XPChanged`
- `LevelUp`

## Geldsystem

`EconomyService` ist der serverseitige Zugriffspunkt fuer Geld. Andere Systeme sollen `profile.Money` nicht direkt bearbeiten.

Oeffentliche Funktionen:

- `AddMoney(player, amount)`
- `RemoveMoney(player, amount)`
- `GetMoney(player)`
- `CanAfford(player, amount)`

Startwerte und Grenzen kommen aus `EconomyConfig`:

- `CurrencyName`
- `StartingMoney`
- `MinMoney`
- `MaxMoney`
- `ShopDefaults`
- `TraderDefaults`

Vorbereitet fuer spaetere UI:

- `MoneyChanged`

## Inventarsystem

`InventoryService` ist der serverseitige Zugriffspunkt fuer Items. Andere Systeme sollen `profile.Inventory` nicht direkt bearbeiten.

Das Inventar wird als Map gespeichert:

```lua
Inventory = {
	ItemId = Amount,
}
```

Oeffentliche Funktionen:

- `AddItem(player, itemId, amount)`
- `RemoveItem(player, itemId, amount)`
- `HasItem(player, itemId)`
- `GetInventory(player)`

Stackgroessen und Item-Metadaten kommen aus `InventoryConfig`:

- `DefaultMaxStackSize`
- `ItemTypes`
- `Items`
- `GetItemConfig(itemId)`
- `GetMaxStackSize(itemId)`

Vorbereitet fuer:

- Kristalle
- Materialien
- Questitems
- Shops
- Haendler

Vorbereitet fuer spaetere UI:

- `InventoryChanged`

## Crystal Framework v1

Das Crystal Framework verwaltet Kristall-Definitionen, Besitz und Ausruestung. Es implementiert keine Faehigkeiten, keinen Schaden, keine Animationen, keine VFX und keine UI.

Module:

- `Modules/Crystal/CrystalDefinitions`
- `Modules/Crystal/CrystalTypes`
- `Modules/Crystal/CrystalUtils`
- `Modules/Crystal/Abilities/BaseCrystal`
- `Modules/Crystal/Abilities/AbilityRegistry`
- `Modules/Crystal/Abilities/PassiveRegistry`
- `Modules/CrystalSystem` als Fassade

Server-Service:

- `ServerScriptService/Services/CrystalService`

Gespeichert werden nur IDs:

```lua
Crystals = {
	Owned = {},
	Equipped = "",
}
```

Oeffentliche Server-Funktionen:

- `GetOwnedCrystals(player)`
- `OwnsCrystal(player, crystalId)`
- `UnlockCrystal(player, crystalId)`
- `EquipCrystal(player, crystalId)`
- `GetEquippedCrystal(player)`
- `GetActiveAbility(player)`
- `CanUseAbility(player)`
- `ActivateAbility(player)`
- `DeactivateAbility(player)`

Beispielkristalle:

- `EMBER`
- `TIDE`
- `GALE`

Sicherheitsregel: Der Client schaltet keine Kristalle frei, ruestet keine Kristalle aus und veraendert keine Kristalldaten. Das Framework nutzt keine Crystal-RemoteEvents.

## Crystal Ability Framework

Das Ability Framework stellt nur die API-Struktur fuer spaetere Kristallfaehigkeiten bereit.

`BaseCrystal` definiert diese Standard-API:

- `Initialize()`
- `CanActivate()`
- `Activate()`
- `Deactivate()`
- `GetCooldown()`
- `Destroy()`

`AbilityRegistry` ordnet spaeter Kristall-IDs konkreten Ability-Klassen zu. Aktuell faellt jede nicht registrierte Ability auf `BaseCrystal` zurueck.

`PassiveRegistry` ist nur eine Datenstruktur fuer spaetere passive Effekte.

Nicht enthalten:

- Schaden
- Hitboxen
- Cooldowns
- Mana oder Energie
- Status-Effekte
- VFX
- Animationen
- UI

## Damage Pipeline Framework

Die Damage Pipeline ist die zentrale Vorbereitung fuer spaetere Kampfsysteme. Sie validiert Damage Requests und erzeugt standardisierte Results. Sie verursacht aktuell keinen Schaden.

Module:

- `Modules/Combat/DamageTypes`
- `Modules/Combat/DamageRequest`
- `Modules/Combat/DamageResult`
- `Modules/Combat/DamageValidators`
- `Modules/CombatSystem` als Fassade

Server-Service:

- `ServerScriptService/Services/DamageService`

Damage Types:

- `Physical`
- `Crystal`
- `True`
- `Environmental`

Service-Funktionen:

- `ValidateRequest(request)`
- `CanDamage(request)`
- `ProcessDamage(request)`
- `ApplyDamage(request)`

Nicht enthalten:

- Humanoid-Schaden
- Hitboxen
- NPC-KI
- Kritische Treffer
- Blocken
- Ausweichen
- Status-Effekte
- Ruestung
- Schadensformeln
