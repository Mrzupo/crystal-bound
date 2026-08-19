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
- GitHub-CI zur JSON-, Rojo-Dateipfad-, Remote-, Gameplay-, Profil-Migrations-, `TakeDamage()`- und Balancing-Validierung.
- GitHub-CI zur Prüfung der Damage-Path-Grenzen für Boss, Combat, DamageService, StatusEffects und Dodge.
- CI-Regel zur eindeutigen `OnServerInvoke`-Besitzerschaft von Player-/Quest-Data-RemoteFunctions.
- Dedicated `CombatFeedback` RemoteEvent für serverbestätigte Crystal-Hit-Presentation.
- Clientseitige Crystal-Animation-, VFX- und Combat-Presentation-Layer für PC und Mobile.
- `combat-presentation-validation.yml` als Regression-Guard für die Server-/Client-Presentation-Grenze.
- `ConfirmedCombatVFXBridge.client.lua` als serverbestätigter, einmaliger VFX-Bridge für den lokalen Angreifer.
- Zusätzliche CI-Verträge für Animator-Ownership, bestätigte Crystal-VFX, Crystal-Unlock-Gates, Achievement-Titel, NPC-Dialog-Optionen und Enemy-Respawn-Lifecycle.
- `CURRENT_AUDIT.md` als aktueller Repository-Audit- und Übergabestand.

### Changed

- `CrystalConfig` enthält Basic Attacks, Abilities und Passives.
- `CrystalUpgradeConfig` steuert Mastery-Level, XP-Kosten und Ressourcen-Kosten.
- `CrystalAnimationConfig` enthält ausschließlich Präsentationswerte für Animation/VFX/Sound und keine Gameplay-Authority.
- `DamageTypes` kennt jetzt explizit `CrystalAbilitySplash` und `BossShockwave`.
- `DamageValidators` lehnen unbekannte DamageType-Werte ab.
- `EnemyConfig` enthält Balancing, Spezialwerte und Drop-Chancen für alle aktuellen Gegnertypen.
- `NPCService` verwaltet Gegnererstellung, eindeutige Namen, Visual Styles, Health Bars, Leash-Verhalten, Pathfinding-Fallback und Spezialangriffe.
- `NPCService` leitet normale und spezielle Spieler-Schäden jetzt über `DodgeService` und begrenzt Spezialangriffe auf sinnvolle Nahkampfreichweiten.
- `NPCService` wendet Burn/Slow nur noch an, wenn der eigentliche Treffer tatsächlich Schaden verursacht hat.
- `CombatService` verwendet ausschließlich kanonische `EnemyConfig`-Werte für XP, Money und Loot; unbekannte Enemy-Typen und implizite Crystal-basierte Fallback-Rewards werden nicht mehr belohnt.
- `CombatService` erzeugt keine serverseitigen kosmetischen Crystal-VFX mehr; bestätigte Treffer werden über `CombatFeedback` an Clients gemeldet.
- `CombatService` leitet GALE-Splash-Schaden ebenfalls über `DamageService.ProcessDamage()`.
- `CombatService` sendet für bestätigte Primär- und Splash-Hits den angewendeten Schaden, Crystal, Action und Critical-State als Presentation-Daten an Clients; diese Daten verändern keine Gameplay-Entscheidungen clientseitig.
- `CombatService` meldet keine Dodges als bestätigte Treffer, wenn `DamageService` null Amount zurückgibt.
- `DamageService` lässt Schaden nur noch gegen Enemy-/Boss-Modelle zu, validiert außerdem den Angreifer als Player oder servermarkiertes Enemy/Boss-Modell und validiert Range/Amount finite-sicher.
- `DamageValidators` weist nicht-endliche Schadenswerte und unbekannte DamageType-Werte explizit ab.
- `BossService` routet Guardian-Shockwave-Schaden gegen NPCs über `DamageService` statt direkt `Humanoid:TakeDamage()` aufzurufen.
- `BossTelegraph` bindet verzögerte Angriffe an die konkrete Guardian-Instanz, damit alte Telegraphen keine neue Bossinstanz treffen.
- `DodgeService` schützt das komplette Character-Schadensfenster zentral über ein temporäres ForceField, validiert Bewegungs-/Schadenswerte finite-sicher und setzt Dodge-State bei Respawn zurück.
- `DodgeService.ApplyDamage()` normalisiert Range-Werte vor jedem Vergleich und verweigert ungültige attacker-basierte Bereiche.
- `StatusEffectService` verhindert Slow/Burn während eines aktiven Dodge-Fensters und erhält aktives Slow bei Player-Syncs.
- `StatusSpeedGuardV2` hält aktive Slow-Effekte nach Crystal-/Mastery-Syncs stabil.
- `BossArena` leitet Phasen-Hazard-Schaden über `DodgeService`.
- `AIPathService` nutzt einen Weak-Key-Cache, gedrosselte Pfadberechnung und verarbeitet Jump-Waypoints auch beim Erreichen gespeicherter Waypoints.
- `PlayerService` verwendet den sicheren Session-locked Profile Store, schützt Save/Remove vor Race Conditions und synchronisiert Daily-Bounty-/Progressionsattribute.
- `PlayerService` erzeugt serverseitig den Character-Animator; `CrystalAnimationController` erstellt keinen lokalen Animator mehr.
- `SafeProfileStore` nutzt Profil-Snapshots beim Save und verweigert beschädigte DataStore-Werte statt sie mit frischen Daten zu überschreiben.
- `PlayerData` normalisiert Level, XP, Geld, Stats, Kristalle, Mastery, Inventar, Questzustand, Session-Lock, Daily-Bounty, Achievements, Titles und `UnlockedIslands` während der Migration.
- Achievement Titles werden bei jeder Reconciliation aus tatsächlich verdienten Achievement-IDs abgeleitet.
- `DailyBountyService` canonicalisiert bestehende Bounty Goal/Reward-Werte anhand des aktuellen `DailyBountyConfig` statt persistierte Rewardwerte blind zu vertrauen.
- `QuestSystem` verwirft ungültige/nicht-endliche Quest-Progress-Increments statt sie als Standardfortschritt zu interpretieren.
- `CrystalSystem.Unlock()` setzt das kanonische Crystal-Level-Gate selbst durch; Bootstrap ist nicht mehr die einzige Schutzgrenze.
- `CrystalSystem.Unlock()` verweigert zusätzlich beschädigte/missing Unlock-Level-Konfigurationen statt auf unendliche Fallbackwerte zu laufen.
- `InventoryService` klemmt korrumpierte Stackwerte vor Add/Remove/Has an die konfigurierten MaxStackSize-Grenzen.
- `CraftingRemote` und `ShopRemote` verlangen die nötige Nähe zum Material Trader und räumen Request-State beim Player-Leave auf.
- `EconomyService`, `InventoryService`, `XPService` und `CrystalMastery` filtern nicht-endliche Eingabewerte und schützen Limits serverseitig.
- `StatusMessages` erlaubt wiederholt auftretende identische Meldungen nach Ablauf des aktuellen Anzeigefensters.
- Portal-Cooldowns nutzen Weak Keys für lange Serverlaufzeiten.
- `default.project.json` lädt ausschließlich `StatusSpeedGuardV2`; der Legacy-Guard und das alte SaveSystem bleiben außerhalb von Rojo.
- Der separate `DataQueryRateLimit`-Server wurde entfernt, weil `Bootstrap` bereits der alleinige `OnServerInvoke`-Handler für diese RemoteFunctions ist; ein zusätzlicher Handler hätte eine Race-/Override-Quelle geschaffen.
- `ClientBootstrap.client.lua` begrenzt die teure Guardian-BossBar-Aktualisierung auf 0,1 Sekunden.
- `CrystalAnimationController.client.lua` behandelt Character-Generationswechsel, stale Tracks und lokale Playback-Begrenzung.
- `CrystalVFXController.client.lua` verlangt eine einmalige serverbestätigte CombatFeedback-Autorisierung und verbraucht diese nach dem Abspielen.
- `ConfirmedCombatVFXBridge.client.lua` akzeptiert auch verspätete Bestätigungen nach einem Crystal-Wechsel, solange die Bestätigung vom Server für den tatsächlichen Angriff stammt.
- `CombatPresentation.client.lua` wartet nicht mehr auf mutable NPC-Hit-Attributes, sondern verarbeitet ausschließlich das serverbestätigte `CombatFeedback`-Event.
- `CombatPresentation.client.lua` verwirft lokal Präsentations-Spam oberhalb eines kleinen Event-Budgets und ignoriert Effekte außerhalb von 220 Studs.
- `NPCDialogMenu.client.lua` schließt den Dialog beim Übergang in Quest/Crystal/Shop/Inventory/Crafting-Menüs.
- `TODO.md`, `NEXT_SESSION.md` und `CURRENT_AUDIT.md` wurden an den aktuellen Entwicklungsstand angepasst.

### Notes

- Die aktuellen VFX sind weiterhin prozedural und noch Placeholder-Level; finale ParticleEmitter, Trails, Sounds und authored Animationen benötigen echte Roblox-Assets.
- Echte Attack-/Ability-Animationen, asset-basierte Partikel, noch komplexere Boss-Mechaniken, automatisierte Luau-Tests und ein echter Roblox-Studio-Playtest bleiben offen.
- Der aktuelle GitHub-Branch ist absichtlich ein Entwicklungsbranch und wurde nicht nach `main` gemerged.
- CI-Status darf nur nach einem tatsächlichen GitHub-Workflow-Lauf als grün bezeichnet werden; für den geprüften aktuellen Head war kein kombinierter Status verfügbar.