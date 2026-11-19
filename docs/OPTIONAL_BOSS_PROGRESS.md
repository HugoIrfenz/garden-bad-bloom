# Optional campaign boss production

The release target is all 13 optional encounters, with an Android playtest APK and GitHub handoff. New campaign floors pick from the enabled roster. Each challenge route adds two approach rooms and an arena before rejoining the chapter route.

| Biome | Encounter | State |
| --- | --- | --- |
| Forgotten Garden | Queen of Dandelions, The First Scarecrow | Enabled with arenas, sprite sheets, original tracks, Codex entries, and relics |
| Mushroom Kingdom | Mother of Spores, The Truffle Bandit | Enabled with arenas, sprite sheets, original tracks, Codex entries, and relics |
| Clockwork Conservatory | Baroness Brasswing, The Unfinished Hour | Enabled with arenas, sprite sheets, original tracks, Codex entries, and relics |
| Bloodbloom Forest | Bride of Thorns, The Antlered Choir | Enabled with arenas, sprite sheets, original tracks, Codex entries, and relics |
| Hollow Palace | The Crownless Prince | Enabled, with checkpoint coverage for mirror destruction |
| Hollow Palace | Madam Black Velvet | Enabled with arena, sprite sheet, original track, Codex entry, and relic |
| Astral Greenhouse | Queen of Two Moons, The Nebula Librarian | Enabled with arenas, sprite sheets, original tracks, Codex entries, and relics |
| Bloomheart Core | The Empty Sixth Chair | Enabled with checkpoint coverage for string posts and the once-per-floor relic |

The headless optional boss route suite enters arenas through their room graph, loads the assets, checks encounter state after saving, claims the relic, and follows the rejoin exit. It uses test fixtures to advance rooms and finish combat. Each approach room rehearses a specific telegraph from its boss. The route suite checks all 26 lessons, including windup persistence and normal reward progression. Late Bell timing, capstone shield and defeat, and campaign navigation through Garden Without End now pass through the live game controller. The first 864 × 390 render pass caught a texture lifetime issue and incorrect boss names in the HUD. Both are corrected. The expanded suite verifies all 39 attacks through normal update dispatch, all phase thresholds and saved transitions, each boss relic through the reward interface, and continuation of a pre-detour save. In-game desktop audio capture confirmed playback and sampled a complete loop transition for each score. Xiaomi installation and subjective device mix and touch checks remain open.
