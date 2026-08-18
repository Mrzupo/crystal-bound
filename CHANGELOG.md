# Changelog

## Unreleased

### Added

- Vollständige `src`-Roblox-Struktur passend zu `default.project.json`.
- PlayerData mit Versionierung, QuestProgress, Crystal-Mastery, Achievements und Schema-Reconciliation.
- Sicherer Profil-Speicher mit Session-Lock, Timeout, Heartbeat und Release beim Server-Shutdown.
- Sicherer Fehlerpfad bei DataStore-Ladefehlern; kein leeres Fallback-Profil bei Fehlern oder beschädigten Stored Values.
- DataStore Save/Load mit Retry und Autosave-Integration.
- XP-, Level- und Economy-System.
- Inventar mit Material-Loot und serverseitigem Verkauf.
- Kauf-Shop mit Health Potion und servervalidierter Consumable-Nutzung.
- Crafting mit servervalidiertem Health-Potion-Rezept.
- Item-Raritäten und gegnerabhängige Drop-Chancen.
- Crystal Framework für `EMBER`, `TIDE` und `GALE`.
- Crystal-Level-Freischaltungen, Ausrüstung und Mastery-Upgrades.
- Passive Crystal-Effekte: Schaden, Geschwindigkeit und MaxHealth.
- Unterschiedliche aktive Crystal-Abilities mit individuellen VFX.
- Servervalidierte Damage-Pipeline, zentrale Hitbox-Prüfungen und Combat.
- Serverseitige Action-Whitelist, Enemy/Boss-Target-Whitelist und Dodge-Invulnerability.
- Dodge-ForceField, sodass auch ältere direkte `TakeDamage()`-Pfade das Dodge-Fenster respektieren.
- Serverautorisierte kritische Treffer mit Mastery-Skalierung.
- Damage Numbers, Ability-Cooldown-Anzeige und Player-Damage-Feedback.
- Burn-/Slow-Status-Effekte für unterschiedliche Gegner.
- Pathfinding-Fallback plus Hindernis-Steering für Gegner.
- Crystal Guardian mit Phase-System, Spieler-Shockwave, Arena-Pylonen, Phase-2-Hazard und Boss-Rewards.
- Telegraphed Phase-2 Guardian Impact mit sichtbarer Warnzone und Reaktionsfenster.
- Starter Island, Tide Island, Wind Island und Ancient Ruins.
- Levelgesperrte Portale und prozedurale Welt-Dekoration.
- Crystal Keeper Quest-NPC und Material Trader.
- Servervalidierte NPC-Dialoge mit Menüoptionen und Rate-Limit.
- Quest-System mit persistentem Fortschritt, servervalidierten Voraussetzungen und automatischer Quest-Kette bis zu den Ancient Ruins.
- Daily Bounty mit persistentem Tagesfortschritt und Geldbelohnung.
- Quest Journal, Achievement System mit Titles und Achievement Journal.
- HUD für Level, XP, Geld, Kristall, Mastery, Loot, Quests, Bounty, Crafting und Statusmeldungen.
- Inventory-/Crystal-GUI mit Besitzstatus, Abilities, Passives, Unlock-Leveln, Upgrade-Kosten, Item-Raritäten und Health-Potion-Nutzung.
- Shop-GUI mit Verkauf und Kaufangebot.
- Mobile Touch Controls mit echter Kamera-/Touch-Zielauswahl.
- Mobile Dodge-, Inventory-, Quest-, Shop- und Achievement-Steuerung.
- GitHub-CI zur JSON-, Rojo-Dateipfad-, Remote-, Gameplay-, Profil-Migrations- und Balancing-Validierung.
- Serverseitiger Rate-Limiter für PlayerData-/QuestData-RemoteFunctions.

### Changed

- `CrystalConfig` enthält Basic Attacks, Abilities und Passives.
- `CrystalUpgradeConfig` steuert Mastery-Level, XP-Kosten und Ressourcen-Kosten.
- `EnemyConfig` enthält Balancing, Spezialwerte und Drop-Chancen für alle aktuellen Gegnertypen.
- `NPCService` verwaltet Gegnererstellung, eindeutige Namen, Visual Styles, Health Bars, Leash-Verhalten, Pathfinding-Fallback und Spezialangriffe.
- `NPCService` leitet normale und spezielle Spieler-Schäden jetzt über `DodgeService` und begrenzt Spezialangriffe auf sinnvolle Nahkampfreichweiten.
- `CombatService` verwendet gegnerspezifische XP-, Geld-, Loot- und Masterywerte, markiert den letzten Boss-Angreifer korrekt, validiert Reichweite serverseitig und verarbeitet Krits, Bounty und Drop-Chancen.
- `DamageService` lässt Schaden nur noch gegen Enemy-/Boss-Modelle zu, respektiert Dodge-Invulnerability und validiert Range/Amount finite-sicher.
- `DamageValidators` weist nicht-endliche Schadenswerte explizit ab.
- `DodgeService` schützt das komplette Character-Schadensfenster zentral über ein temporäres ForceField, validiert Bewegungs-/Schadenswerte finite-sicher und setzt Dodge-State bei Respawn zurück.
- `StatusEffectService` verhindert Slow/Burn während eines aktiven Dodge-Fensters und erhält aktives Slow bei Player-Syncs.
- `StatusSpeedGuardV2` hält aktive Slow-Effekte nach Crystal-/Mastery-Syncs stabil.
- `BossArena` leitet Phasen-Hazard-Schaden über `DodgeService`.
- `BossTelegraph` bricht verzögerte Boss-Angriffe ab, wenn der Guardian während des Telegraphs verschwindet oder stirbt.
- `AIPathService` nutzt einen Weak-Key-Cache, gedrosselte Pfadberechnung und verarbeitet Jump-Waypoints auch beim Erreichen gespeicherter Waypoints.
- `PlayerService` verwendet den sicheren Session-locked Profile Store, schützt Save/Remove vor Race Conditions und synchronisiert Daily-Bounty-/Progressionsattribute.
- `SafeProfileStore` nutzt Profil-Snapshots beim Save und verweigert beschädigte DataStore-Werte statt sie mit frischen Daten zu überschreiben.
- `PlayerData` normalisiert Level, XP, Geld, Stats, Kristalle, Mastery, Inventar, Questzustand, Session-Lock, Daily-Bounty, Achievements, Titles und `UnlockedIslands` während der Migration.
- `CraftingRemote` und `ShopRemote` verlangen die nötige Nähe zum Material Trader und räumen Request-State beim Player-Leave auf.
- `EconomyService`, `InventoryService`, `XPService` und `CrystalMastery` filtern nicht-endliche Eingabewerte und schützen Limits serverseitig.
- `StatusMessages` erlaubt wiederholt auftretende identische Meldungen nach Ablauf des aktuellen Anzeigefensters.
- Portal-Cooldowns nutzen Weak Keys für lange Serverlaufzeiten.
- `default.project.json` lädt ausschließlich `StatusSpeedGuardV2`; der Legacy-Guard und das alte SaveSystem bleiben außerhalb von Rojo.
- `TODO.md` wurde an den tatsächlichen Entwicklungsstand angepasst.

### Notes

- Die aktuellen VFX sind prozedural und benötigen noch keine externen Assets.
- Echte Attack-/Ability-Animationen, asset-basierte Partikel, noch komplexere Boss-Mechaniken, automatisierte Luau-Tests und ein echter Roblox-Studio-Playtest bleiben offen.
- Der aktuelle GitHub-Branch ist absichtlich ein Entwicklungsbranch und wurde nicht nach `main` gemerged.
