# Garden: Bad Bloom base-game release

The owner approved a full offline Android base game before the separate follow-on expansion. Build 0.1.3 is the packaged baseline. The owner runs gameplay, regression, and device tests. Development handoffs include an APK, fixture or seed details where useful, and the exact work that remains.

## Mandatory coverage

| Bible | Release requirement | 0.1.3 baseline and open work |
| --- | --- | --- |
| 02–08, 22, 45–46 | Five heroines, responsive combat, landscape presentation, authored rooms | Five kits, 56 layout identities, startup, battle, cut-in, HUD and results work. Finish room-specific behaviors and art, weapon animation overlays, hit/reaction polish and accessibility. |
| 09–10, 29, 34 | 168 regular and Endless species, 40 bosses | 25 regular species and seven chapter bosses. Add the remaining authored species and bosses, secret encounter conditions, remixes, phase art, audio and drops. |
| 11–12, 30–33, 40 | 120 weapons, 130 relics, 30 curses, 35 synergies, 30 charms and 30 consumables | Five fixed class weapons, five relics, one authored synergy, three pocket consumables and an altar trade. Add equipment, item hooks, evolution, conditional offers, acquisition and collection. |
| 13, 35–36, 39 | 56 set pieces, 100 events, 42 hazards | 56 identities generate; several already have distinctive mechanics and art. 16 events are live. Count actual mechanics and normal play placement, with artwork for each release piece. |
| 14, 37–38 | 36 elite affixes and 48 Endless floor mutators | Five floor rules and a capstone-to-Endless transition are live. Implement compatibility, modifiers, escalating roles, hidden encounters and bests. |
| 06, 28, 43 | 120 talents, ten alternate aspects and optional in-run quest chains | Base skills and ultimates work for each heroine. Add talent choices, aspect triggers, distinct moves and persistent discovery. |
| 12, 15–16, 41–42 | Progression, 50 achievements, Codex, history, hub, audio and haptics | Existing Seed awards, enemy discoveries, history persistence, menu art and authored score. Add breadth unlocks, cosmetic customization, goals, full archive, settings and feedback. |
| 18–21, 23, 44, 47–48 | Determinism, save migration, data integrity, English and Bahasa Indonesia, performance, Android release | Stable run checkpoints, ARM64 landscape debug package, existing headless suite and offline manifest. Expand schema coverage, accessibility and localization, and obtain owner device acceptance for the release APK. |

## Completion gates

- An entry counts when it has implemented behavior, a normal-play source, finished art, and a reproducible check. Display names and layout IDs alone do not count as completed content.
- Append the build ID and owner test results by affected requirement. Close the release after all mandatory entries are covered and the owner accepts the APK on the Xiaomi 14T Pro.
- Scope follows the owner’s landscape and fine-pixel direction, with offline runtime assets, interruption resume, and explicit forfeiture on End Run.

## Implementation queue

1. **0.1.4 implementation.** Weapon slots and comparison, ten field weapons, Weapon Ledger discoveries, an Honest Receipt relic and Rose Receipt interaction, seven combat statuses, the first talent for each heroine, three persistent curse bargains, six illustrated Bloodbloom events, four Garden Seed unlocks, run history, and an initial English/Bahasa Indonesia flow. Owner playtesting is pending. See the [player checks](PLAYTEST_0.1.4.md).
2. **0.1.5 and 0.1.6 implementation.** The rest-room forge has one evolution per heroine. The two packages cover distinct recipe sources, ingredient and evolved equipment art, saved combat effects, persisted discovery, and a second talent milestone for Sewing Thread. Owner playtesting is pending. [0.1.5 player checks](PLAYTEST_0.1.5.md) · [0.1.6 player checks](PLAYTEST_0.1.6.md)
3. **0.1.7 playtest follow-up.** Added higher encounter health and pressure, Angela's shield, two hero action atlases, boss defeat animation and fanfare, distinct exploration scores and attack effects, fewer healing and Petal sources, a curse bargain, talent alternatives, Three Caps in a Row, and Garden/title/Seed Shop updates. [0.1.7 player checks](PLAYTEST_0.1.7.md)
4. **0.1.8 storybook prologue.** Added five illustrated, animated story scenes after Hugo & Angela Works, each with its own arrangement and timed effects. Owner feedback on the forge praised crafting and asked that future additions maintain attention to animation, music, sound effects, and visual effects. [Prologue player checks](PROLOGUE.md)
5. **0.1.9 run rewards.** Added seven alternatives to Thorn Edge, with seeded chest offers, ranked combat effects, artwork, confirmation effects, and a Pause upgrade list. The player-facing post-campaign mode is Garden Without End. [0.1.9 player checks](PLAYTEST_0.1.9.md)
6. **0.1.10 boss and route tuning.** Campaign and Garden Without End bosses have five times their former health. Active saves keep the same fraction of boss health remaining as the new maximum takes effect. Three Caps has a dedicated route marker in Mushroom Kingdom. [0.1.10 player checks](PLAYTEST_0.1.10.md)
7. **0.1.11 Garden Games and relics.** Added Petal Prix, Clockwork Encore, Bramble Snake and Teacup Catch alongside Three Caps. The five games have free Garden practice and marked, saved dungeon encounters with stakes and prizes. Relic inspection and starting-relic comparison show triggers, limits and forge pairings. [0.1.11 player checks](PLAYTEST_0.1.11.md)
8. **0.1.12 Garden collection and finale.** Added 58 Seed Shop unlocks, cartridge replay, all 37 soundtrack tapes, the jukebox, and a Relic Ledger with fixed sources. Dungeon games occupy main-route event rooms. Bosses gain pace as they lose health and Bloomheart has a new finale. [0.1.12 player checks](PLAYTEST_0.1.12.md)
9. **Next implementation.** Fill biome production in Bible order. Begin with the remaining Forgotten Garden species, room mechanics, hazard variants and event cards through normal routes. Add more heroine talents and evolutions alongside the biome batches before expanding optional bosses.
10. Fill the full progression, aspects and equipment catalogs in parallel with remaining biomes, then complete Garden Without End, settings, localization and release packaging.
