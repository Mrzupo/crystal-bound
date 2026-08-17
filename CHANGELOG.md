# Changelog

## Unreleased

### Added

- Vollständige `src`-Roblox-Struktur passend zu `default.project.json`.
- PlayerData mit Versionierung, QuestProgress, Crystal-Mastery, Achievements und Schema-Reconciliation.
- Sicherer Profil-Speicher mit Session-Lock, Timeout und Release beim Server-Shutdown.
- Sicherer Fehlerpfad bei DataStore-Ladefehlern; kein leeres Fallback-Profil wird mehr gespeichert.
- DataStore Save/Load mit Retry und Autosave-Integration.
- XP-, Level- und Economy-System.
- Inventar mit Material-Loot und serverseitigem Verkauf.
- Shop-/Trader-GUI und NPC-zu-Menü-Verknüpfung.
- Crystal Framework für `EMBER`, `TIDE` und `GALE`.
- Crystal-Level-Freischaltungen, Ausrüstung und Mastery-Upgrades.
- Passive Crystal-Effekte: Schaden, Geschwindigkeit und MaxHealth.
- Unterschiedliche aktive Crystal-Abilities mit individuellen VFX.
- Servervalidierte Damage-Pipeline und Combat.
- Damage Numbers, Ability-Cooldown-Anzeige und Player-Damage-Feedback.
- Training Dummy, Emberling, Tidecrawler, Galewisp, Crystal Bat und Ancient Golem.
- Gegnertyp-spezifische Visuals und Spezialangriffe.
- Crystal Guardian mit Phase-System, funktionierender Spieler-Shockwave und Boss-Rewards.
- Starter Island, Tide Island, Wind Island und Ancient Ruins.
- Levelgesperrte Portale und prozedurale Welt-Dekoration.
- Crystal Keeper Quest-NPC und Material Trader.
- Quest-System mit persistentem Fortschritt, servervalidierten Voraussetzungen und automatischer Quest-Kette bis zu den Ancient Ruins.
- Quest Journal mit servervalidiert verfügbaren Quests.
- Achievement-System mit Titles und Achievement Journal.
- HUD für Level, XP, Geld, Kristall, Mastery, Loot, Quests und Statusmeldungen.
- Inventory-/Crystal-GUI mit Besitzstatus, Abilities, Passives, Unlock-Leveln und Upgrade-Kosten.
- Mobile Touch Controls mit echter Kamera-/Touch-Zielauswahl.
- Mobile Menü-Buttons für Inventory, Quests, Shop und Achievements.
- NPC-Menü-Brücke für Crystal Keeper und Material Trader.

### Changed

- `CrystalConfig` enthält Basic Attacks, Abilities und Passives.
- `CrystalUpgradeConfig` steuert Mastery-Level, XP-Kosten und Ressourcen-Kosten.
- `EnemyConfig` enthält Balancing für alle aktuellen Gegnertypen.
- `NPCService` verwaltet Gegnererstellung, eindeutige Namen, Visual Styles, Health Bars, Leash-Verhalten und Spezialangriffe.
- `CombatService` verwendet gegnerspezifische XP-, Geld-, Loot- und Masterywerte und markiert den letzten Boss-Angreifer korrekt.
- `PlayerService` verwendet jetzt den sicheren Session-locked Profile Store und lehnt fehlgeschlagene Profileloads ab.
- `QuestSystem` unterstützt servergeprüfte verfügbare Quests.
- `WorldDecor` wurde auf alle vier aktuellen Inseln erweitert.
- `default.project.json` wurde fortlaufend mit jeder neuen Server-/Client-Datei synchronisiert.
- `TODO.md` wurde an den tatsächlichen Entwicklungsstand angepasst.

### Notes

- Die aktuellen VFX sind prozedural und benötigen noch keine externen Assets.
- Echte Attack-/Ability-Animationen, asset-basierte Partikel, komplexe Hitboxen, fortgeschrittenes Pathfinding, vollständige Boss-Mechaniken und automatisierte Luau-Tests sind noch offen.
- Ein echter Play-Test in Roblox Studio ist weiterhin notwendig, weil diese Umgebung Roblox Studio nicht ausführen kann.
