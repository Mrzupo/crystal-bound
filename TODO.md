# TODO

## Naechste sinnvolle Schritte

- Itemdefinitionen in `InventoryConfig.Items` ausarbeiten.
- Kristall-Items mit `CrystalConfig` und `InventoryConfig` abstimmen.
- Crystal-Level, Upgrades und Fortschritt als separates spaeteres System planen.
- Combat-Integration fuer ausgeruestete Kristalle spezifizieren.
- Damage Pipeline spaeter mit echten Schadensformeln verbinden.
- Zielmodell fuer NPCs und Spieler definieren, bevor `ApplyDamage` echten Schaden anwendet.
- Kritische Treffer, Blocken, Ausweichen und Ruestung separat designen.
- Konkrete Ability-Klassen fuer `EMBER`, `TIDE` und `GALE` erst nach Combat-Design erstellen.
- Aktivierungsregeln fuer Abilities definieren, bevor echte Cooldowns oder Ressourcen eingebaut werden.
- Passive Effekte in `PassiveRegistry` spezifizieren.
- Serverinterne Tests fuer `CrystalService` ergaenzen.
- Materialien und Questitems als getrennte Itemtypen definieren.
- ShopService oder TraderService erstellen, der `EconomyService` und `InventoryService` gemeinsam nutzt.
- Admin-Testbefehle fuer XP, Geld und Items erstellen.
- Automatisierte Luau-Tests fuer Services vorbereiten.
- Session-Locking fuer `SaveSystem` ergaenzen.
- UI fuer `XPChanged`, `MoneyChanged` und `InventoryChanged` bauen.

## Spaeter

- Inventar-Slotlimit.
- Item-Rarities.
- Item-Icons aus `Assets/Icons`.
- Drop-Tabellen fuer Gegner.
- Questitem-Regeln wie nicht handelbar oder nicht verkaufbar.
- Validierte RemoteFunctions fuer sichere Client-Abfragen.
- Crystal-Faehigkeiten, Cooldowns, VFX und Animationen erst nach Abschluss des Combat-Designs implementieren.
- Hitboxen und NPC-KI erst nach stabiler Damage Pipeline implementieren.
