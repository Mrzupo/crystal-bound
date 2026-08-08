# Design

## Grundprinzip

Crystal Fight nutzt serverseitige Services als Autoritaet. Client und UI sollen nur anzeigen oder Anfragen senden. Persistente Werte liegen im `PlayerData`-Profil und werden vom `SaveSystem` gespeichert.

## Architektur

Das Crystal Framework v1 besteht aus:

- `ReplicatedStorage/Modules/Crystal/CrystalDefinitions`
- `ReplicatedStorage/Modules/Crystal/CrystalTypes`
- `ReplicatedStorage/Modules/Crystal/CrystalUtils`
- `ReplicatedStorage/Modules/Crystal/Abilities/BaseCrystal`
- `ReplicatedStorage/Modules/Crystal/Abilities/AbilityRegistry`
- `ReplicatedStorage/Modules/Crystal/Abilities/PassiveRegistry`
- `ReplicatedStorage/Modules/CrystalSystem` als Fassade
- `ReplicatedStorage/Config/CrystalConfig`
- `ServerScriptService/Services/CrystalService`

`CrystalDefinitions`, `CrystalTypes` und `CrystalUtils` sind read-only Bausteine. `CrystalService` ist die serverseitige Autoritaet fuer Besitz und Ausruestung.

Das Crystal Ability Framework definiert nur Lifecycle und Registries. Es ist absichtlich frei von Combat-Logik.

Die Damage Pipeline besteht aus:

- `ReplicatedStorage/Modules/Combat/DamageTypes`
- `ReplicatedStorage/Modules/Combat/DamageRequest`
- `ReplicatedStorage/Modules/Combat/DamageResult`
- `ReplicatedStorage/Modules/Combat/DamageValidators`
- `ReplicatedStorage/Modules/CombatSystem` als Fassade
- `ServerScriptService/Services/DamageService`

Sie ist die zentrale Vorbereitung fuer spaetere Kampfsysteme. Aktuell validiert sie nur und wendet keinen Schaden an.

## Datenmodell

`PlayerData.Crystals` speichert nur Referenzen:

```lua
Crystals = {
	Owned = {},
	Equipped = "",
}
```

Definitionen wie Name, Rarity, Element oder UnlockLevel werden nicht gespeichert. Sie bleiben im Definition Catalog.

Ein Damage Request hat diese Kernfelder:

```lua
{
	Attacker = attacker,
	Target = target,
	Damage = damage,
	DamageType = damageType,
	CrystalId = crystalId,
	Timestamp = timestamp,
}
```

Ein Damage Result hat diese Kernfelder:

```lua
{
	Success = true,
	FinalDamage = 0,
	Reason = "OK",
	WasCritical = false,
	WasBlocked = false,
}
```

`PlayerData.Inventory` ist eine Map:

```lua
Inventory = {
	ItemId = Amount,
}
```

Beispiel:

```lua
Inventory = {
	CrystalShard = 25,
	AncientKey = 1,
}
```

Diese Struktur ist bewusst einfach:

- schnelle Abfrage per `itemId`
- einfache Speicherung im DataStore
- direkte Unterstuetzung fuer stapelbare Items
- geeignet fuer Shops, Haendler, Drops und Questitems

## Service-Verantwortung

`CrystalService` verantwortet:

- Besitzliste lesen
- Besitz pruefen
- Kristalle freischalten
- einen Kristall ausruesten
- ausgeruesteten Kristall lesen
- ungueltige IDs ablehnen
- Duplikate verhindern
- gespeicherte Kristalldaten bereinigen
- aktive Ability-Platzhalter erzeugen
- Ability-Platzhalter aktivieren und deaktivieren

`CrystalService` implementiert keine echten Faehigkeiten, keinen Schaden, keine Cooldowns, keine Animationen und keine VFX.

`BaseCrystal` definiert die gemeinsame API fuer spaetere Kristallfaehigkeiten:

- `Initialize`
- `CanActivate`
- `Activate`
- `Deactivate`
- `GetCooldown`
- `Destroy`

`AbilityRegistry` mappt Kristall-IDs auf Ability-Klassen. Nicht registrierte Kristalle nutzen `BaseCrystal`.

`PassiveRegistry` haelt spaeter passive Zuordnungen, fuehrt aber keine Logik aus.

`InventoryService` ist der einzige vorgesehene Schreibzugriff auf Inventardaten.

Er verantwortet:

- Items hinzufuegen
- Items entfernen
- Itembesitz pruefen
- Inventarkopie zurueckgeben
- Stacklimits einhalten
- `InventoryChanged` fuer spaetere UI senden

Andere Systeme sollen nicht direkt `profile.Inventory` veraendern.

`DamageService` verantwortet:

- Damage Requests validieren
- DamageType pruefen
- positiven Schaden pruefen
- Ziel und Angreifer pruefen
- standardisierte Damage Results erzeugen

`DamageService` verantwortet aktuell nicht:

- Humanoid-Schaden
- Hitboxen
- Formeln
- Kritische Treffer
- Blocken
- Ausweichen
- Status-Effekte
- Ruestung

## Konfiguration

`CrystalConfig` enthaelt:

- `DefaultCrystal`
- `MaxOwnedCrystals`
- `AllowCrystalSwitchInCombat`

`CrystalTypes` enthaelt zentrale Werte fuer:

- Rarities: `Common`, `Rare`, `Epic`, `Legendary`, `Mythic`
- Elements: `Fire`, `Water`, `Wind`

`InventoryConfig` enthaelt:

- `DefaultMaxStackSize`
- `ItemTypes`
- `Items`
- `GetItemConfig(itemId)`
- `GetMaxStackSize(itemId)`

Itemtypen sind vorbereitet fuer:

- `Crystal`
- `Material`
- `QuestItem`
- `Consumable`

`DamageTypes` enthaelt zentrale Werte fuer:

- `Physical`
- `Crystal`
- `True`
- `Environmental`

## Remotes

Crystal Framework v1 verwendet keine Crystal-RemoteEvents. Freischalten und Ausruesten sind serverinterne Operationen.

Damage Pipeline Framework verwendet keine Damage-RemoteEvents. Spaetere Client-Anfragen muessen serverseitig validiert werden, bevor ein Damage Request erzeugt wird.

`InventoryChanged` ist ein server-to-client Event. Es ist fuer UI-Aktualisierung vorgesehen und soll nicht als Client-Autoritaet genutzt werden.

Payload:

```lua
{
	ItemId = itemId,
	Amount = newAmount,
	Delta = delta,
	Inventory = inventoryCopy,
}
```

## Sicherheitsmodell

- Der Client darf keine Kristalle freischalten oder ausruesten.
- Kristall-Definitionen werden ueber `CrystalUtils.IsValid` validiert.
- `PlayerData.Crystals` speichert nur IDs.
- Doppelte Kristalle werden abgelehnt.
- Nicht besessene Kristalle koennen nicht ausgeruestet werden.
- Der Client darf keine Items direkt vergeben.
- Der Client darf keine Damage Results erzeugen oder Schaden anwenden.
- `ApplyDamage` ist aktuell absichtlich ein No-Op bezogen auf Humanoids und Spielzustand.
- Shops, Haendler, Quests und Gegnerdrops sollen serverseitig `InventoryService` aufrufen.
- `GetInventory` gibt eine Kopie zurueck, damit fremder Code nicht versehentlich das Profil direkt mutiert.
- Ungueltige Mengen und leere ItemIds werden abgelehnt.

## Erweiterbarkeit

Neue Kristalle werden in `CrystalDefinitions` hinzugefuegt. Neue Rarities oder Elements werden nur in `CrystalTypes` ergaenzt. Das spaetere Kampfsystem kann `CrystalService.GetEquippedCrystal(player)` verwenden, ohne Definitionen oder PlayerData direkt zu kennen.

Bewusste Entscheidung: Crystal Framework v1 speichert keine Definitionen in DataStores. Das vermeidet veraltete gespeicherte Kopien, wenn Balancing oder Beschreibungen spaeter angepasst werden.

Bewusste Entscheidung: Ability-Instanzen sind aktuell Laufzeit-Platzhalter und werden nicht gespeichert. Gespeichert bleibt nur die ausgeruestete Kristall-ID.

Bewusste Entscheidung: `ApplyDamage` validiert aktuell nur. Echter Schaden wird erst implementiert, wenn Zielmodell, Hitboxen und Combat-Regeln spezifiziert sind.
