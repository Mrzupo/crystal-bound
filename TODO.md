# TODO

## Aktueller Entwicklungsstand

- [x] PlayerData + Schema-Reconciliation
- [x] DataStore Save/Load + Retry
- [x] Autosave alle 60 Sekunden
- [x] Session-Locking mit Timeout und Release beim Server-Shutdown
- [x] Sicherer Profil-Ladefehlerpfad ohne leeres Fallback-Profil
- [x] Persistente Daten-Normalisierung für Zahlen, Kristalle, Inventar, Quests und Daily Bounty
- [x] XP- und Levelsystem
- [x] Geldsystem
- [x] Inventar + Material-Loot
- [x] Materialverkauf beim Material Trader
- [x] Kauf-Shop mit Health Potion
- [x] Crafting mit Health-Potion-Rezept und Stack-Kapazitätsprüfung
- [x] Servervalidierte Consumable-Nutzung
- [x] Crystal-System mit EMBER/TIDE/GALE
- [x] Crystal-Level-Freischaltungen
- [x] Crystal-Passiveffekte
- [x] Crystal-Mastery + Upgrade-System
- [x] Crystal-Fähigkeiten mit unterschiedlichen Effekten
- [x] Servervalidiertes Combat
- [x] Serverseitige Combat-Action-Whitelist
- [x] Serverseitige Enemy/Boss-Target-Whitelist
- [x] Serverseitige Distanz-/Hitbox-Prüfung
- [x] Serverautorisierte kritische Treffer
- [x] Serverautorisierter Dodge mit globalem ForceField-Schutz
- [x] Damage Numbers + Cooldown-Feedback
- [x] Gegner-Konfiguration und serverseitige einfache KI
- [x] Hindernis-Steering + Pathfinding-Fallback
- [x] Status-Effekte (Burn / Slow)
- [x] Gegnertypen mit unterschiedlichen visuellen Stilen
- [x] Gegnertypen mit speziellen Angriffen
- [x] Gegner-HP-Balken
- [x] Sauberer Enemy-/Boss-Lifecycle mit Respawn-Cleanup
- [x] Training Dummy
- [x] Emberling
- [x] Tidecrawler
- [x] Galewisp
- [x] Crystal Bat
- [x] Ancient Golem
- [x] Crystal Guardian Boss
- [x] Guardian-Arena mit Phase-2-Hazard
- [x] Telegraphierte Phase-2-Bossattacke
- [x] Starter Island
- [x] Tide Island
- [x] Wind Island
- [x] Ancient Ruins
- [x] Levelgesperrte Portale
- [x] Questdefinitionen + Fortschritt
- [x] Servervalidierte Questvoraussetzungen
- [x] Automatische Questkette bis Ancient Ruins
- [x] Automatischer Queststart nach erreichter Levelvoraussetzung
- [x] Quest Journal
- [x] Achievements + Titles
- [x] Achievement Journal
- [x] Tägliche Bounty mit persistentem Fortschritt
- [x] NPC-Dialoge mit servervalidierten Menü-Optionen
- [x] NPC-Dialoge als zentraler Einstieg zu Quest/Crystal/Shop/Inventory/Crafting
- [x] HUD für Progression, Loot, Quests, Bounty und Crafting
- [x] Gemeinsames Status-Message-HUD inklusive Loot/Dodge/Bounty/Crafting-Feedback
- [x] Spieler-HP + Death/Respawn-Feedback
- [x] Inventory-/Crystal-GUI
- [x] Item-Raritäten
- [x] Gegnerabhängige Drop-Chancen
- [x] Mobile Touch Combat Controls mit Kamera-Ray-Zielauswahl
- [x] Mobile Menu Controls inklusive Crafting
- [x] Mobile Dodge-Control
- [x] NPC-zu-Menü-Verknüpfung über Dialogsystem
- [x] Welt-Dekoration für alle aktuellen Inseln
- [x] Modulare Welt-Themes
- [x] Rojo-/default.project.json-Struktur für alle Erweiterungen
- [x] GitHub-CI für JSON-, Rojo- und häufige Luau-Require-Pfad-Validierung
- [x] Combat-Cooldown-Cleanup beim Player-Verlassen

## Nächste Systeme

- [ ] echte Attack-/Ability-Animationen
- [ ] echte Asset-basierte VFX/Particles statt prozeduraler Placeholder
- [ ] weitere Boss-Mechaniken außerhalb des Guardian-Phasen-Systems
- [ ] fortgeschrittenes Navigation-/Pathfinding-Tuning für komplexes Terrain
- [ ] automatisierte Luau-Tests
- [ ] Multiplayer-Performance- und Security-Test
- [ ] echter Roblox-Studio-Playtest mit Output-/Runtime-Fehlerbehebung
- [ ] bessere Kampfanimationen und Hit-Reactions

## Später

- [ ] PvP-Modus
- [ ] Weekly/Daily Quest-Varianten zusätzlich zur aktuellen Bounty
- [ ] weitere Inseln
- [ ] weitere Kristalle
- [ ] weitere Bosse
- [ ] umfangreicheres Shop-/Economy-System
- [ ] Sounddesign
- [ ] vollständige UI-Überarbeitung
