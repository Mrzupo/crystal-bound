# Changelog

## Unreleased

### Added

- Vollständige `src`-Roblox-Struktur passend zu `default.project.json`.
- PlayerData mit Versionierung, QuestProgress und Schema-Reconciliation.
- SaveSystem mit DataStore-Retry und Autosave-Integration.
- XP-, Level- und Economy-System.
- Inventar mit Material-Loot und serverseitigem Verkauf.
- Crystal Framework für `EMBER`, `TIDE` und `GALE`.
- Crystal-Level-Freischaltungen und Ausrüstung.
- Passive Crystal-Effekte: Schaden, Geschwindigkeit und MaxHealth.
- Unterschiedliche aktive Crystal-Abilities.
- Servervalidierte Damage Pipeline und Combat.
- Temporäre Crystal-Hit-/Ability-VFX.
- Training Dummy, Emberling, Tidecrawler und Galewisp.
- Einfache serverseitige Gegner-KI mit Aggro und Angriff.
- Starter Island, Tide Island und Wind Island.
- Levelgesperrte Portale zwischen Inseln.
- Crystal Keeper Quest-NPC.
- Material Trader mit serverseitiger Entfernung aus dem Inventar und Geldgutschrift.
- Quest-System mit persistentem Fortschritt und Quest-Kette bis zum Wind Trial.
- HUD für Level, XP, Geld, Kristall, Loot, Quests und Statusmeldungen.
- Crystal-Wechsel per `Z`, `X`, `C`.
- Loot-Verkauf per `4`, `5`, `6` in der Nähe des Material Traders.

### Changed

- `CrystalConfig` enthält jetzt Basic Attacks, Abilities und Passives.
- `EnemyConfig` enthält Balancing für mehrere Gegnertypen.
- `NPCService` verwaltet Gegnererstellung, eindeutige Namen und einfache KI.
- `CombatService` verwendet gegnerspezifische XP-, Geld- und Lootwerte.
- `PlayerService` wendet Crystal-Passives beim Spawn und nach Respawns erneut an.
- `Bootstrap` initialisiert Welt, NPCs, Portale, Remotes und Autosave.
- `TODO.md` wurde an den tatsächlichen Entwicklungsstand angepasst.

### Notes

- Die aktuellen VFX sind prozedural und benötigen noch keine externen Assets.
- Animationen, ein vollständiges Inventarfenster, komplexere Hitboxen, Bosskämpfe, Session-Locking und automatisierte Luau-Tests sind noch offen.
- Ein echter Play-Test in Roblox Studio ist weiterhin notwendig, weil diese Umgebung Roblox Studio nicht ausführen kann.
