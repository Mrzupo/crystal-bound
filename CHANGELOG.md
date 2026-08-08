# Changelog

## Unreleased

### Added

- Crystal Framework v1 mit `Modules/Crystal`.
- `CrystalDefinitions` mit `EMBER`, `TIDE` und `GALE`.
- `CrystalTypes` fuer zentrale Rarities und Elements.
- `CrystalUtils` mit `Exists`, `GetDefinition` und `IsValid`.
- `CrystalSystem` als Fassade ueber die neuen Crystal-Module.
- Vollstaendiger serverseitiger `CrystalService`.
- Crystal Ability Framework mit `BaseCrystal`, `AbilityRegistry` und `PassiveRegistry`.
- Platzhalter-Methoden in `CrystalService`: `GetActiveAbility`, `CanUseAbility`, `ActivateAbility`, `DeactivateAbility`.
- Damage Pipeline Framework mit `DamageRequest`, `DamageResult`, `DamageTypes` und `DamageValidators`.
- `DamageService` mit `ValidateRequest`, `CanDamage`, `ProcessDamage` und `ApplyDamage`.
- `PlayerData.Crystals` speichert nur `Owned` und `Equipped` IDs.
- `InventoryService` als serverseitiges Inventarsystem.
- `InventoryConfig` fuer Stackgroessen und Item-Metadaten.
- `InventoryChanged` RemoteEvent fuer spaetere UI.
- Stapelbare Items mit `itemId -> amount` Speicherung in `PlayerData.Inventory`.
- Oeffentliche Inventory-Funktionen:
  - `AddItem(player, itemId, amount)`
  - `RemoveItem(player, itemId, amount)`
  - `HasItem(player, itemId)`
  - `GetInventory(player)`
- Dokumentation fuer README, TESTING, TODO und DESIGN.

### Changed

- Alte Kristall-Platzhalter wurden durch das modulare Crystal Framework v1 ersetzt.
- Kristallbezogene Platzhalter-Remotes wurden aus der Rojo-Struktur entfernt.
- `PlayerData.Inventory` wurde von einer Platzhalter-Liste auf eine Item-Map umgestellt.
- `SaveSystem` normalisiert Inventardaten nach dem Laden.
- `Bootstrap` laedt jetzt `InventoryService`.

### Notes

- Crystal Framework v1 implementiert keine Faehigkeiten, keinen Schaden, keine Animationen, keine VFX und keine UI.
- Crystal Ability Framework stellt nur API, Registry und Lifecycle-Platzhalter bereit.
- Damage Pipeline validiert nur und wendet keinen Schaden auf Humanoids oder Spielzustand an.
- Das System ist fuer Kristalle, Materialien, Questitems, Shops und Haendler vorbereitet.
- Es gibt noch keine Client-UI und keine Shop- oder Drop-Logik.
