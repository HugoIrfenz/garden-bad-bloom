# Verification report

## Laptop through 0.1.3

Godot 4.4.1 imported the project and rendered the landscape 864 × 390 design canvas at its native size and in a 1080 × 488 laptop window. All 30 headless suites passed with isolated local saves. The owner completed a full phone playtest on 0.1.0. The follow-up build has been exercised on the laptop.

| Test | What was exercised |
| --- | --- |
| Generator | 1,000 fixed seeds, 9,922 rooms, seven biomes, 11 room categories and 56 template identities. Checks covered graph paths, separated random streams, safe spawn positions and continuous cover clearance. |
| Campaign routing | Normal door input traversed all seven chapters and launched a generated Endless floor. Branches matched the corresponding minimap links and room choices survived checkpoint restores. Fixtures resolved intermediate fights. |
| Startup | A cold launch showed all three independently moving marks, faded into the title and consumed a skip tap before menu navigation. |
| Merchant and rest | Four seeded stock offers, sold-state and reroll persistence, one-slot inventory, multiple independent purchases, and an exclusive choice between healing and honing. |
| Chapter bosses and enemies | Boss and enemy phase timing, dedicated Majesty poses, tankier health values, arena cover, and enemy arrivals. Desktop rendering verified the boss health bar and action sprites. |
| Flowerbed Siege | Seeded Hedge Knight spawn and Codex discovery, visible thorn windups, shield angles, charge interception, Lilyblade finisher, and clipped patch persistence. |
| Ground hazards | Root Grapple, glass shards, Spore Vent, Leaper landing damage, an active Leech Pond with a safe lily pad, and severable Crimson Threads. Saved active states restore correctly. |
| Clockwork floors | Telegraph timing, safe wedges, changing hazard sectors, and saved gear sweep damage and cover impacts. |
| Iron Bouquet | Angela-only charm acquisition, one reflection per perfect guard, one landed trap, cover blocking and mid-effect resume. |
| Thornmail | Angela-only boss acquisition, perfect guard timing, cover-aware retaliation, and projectile save/restore. |
| Capstone | The boss waits for its arrival animation, then spawns five protective nodes. The nodes survive a checkpoint. Fractured Roots take turns so one warning grid remains actionable. A clear opens Endless. |
| Five heroines | Distinct basic cadences, skills, dodge behavior and aim assistance. The tests verify cinematic combat freeze, the delayed ultimate release and restoration during the cue. |
| Relics and rewards | Starting and acquired relics, seeded pocket rewards, Teacup charge, Tonic recovery, Petal Bomb targeting and saved inventory consumption. |
| Controls | Synthesized multitouch for the floating joystick and attacks, mirrored layout, ranged hold-to-preview and cancel on off-button release, 30/60 FPS and independent audio switches. |
| Run finalization | Live stats pause, explicit End Run confirmation, blocked roster changes, interruption recovery, idempotent Garden Seed awards, migrated saves and local run history. |
| Endless rules | 425 seeded samples and actual rule application, including warning fuses, protection zones, elite and bounty rewards, and checkpoint restore. |
| Events and boss loot | Sixteen authored choice cards, in-room artwork, the saved Wrong Bell hunt, and a seeded optional relic offer on chapter boss chests. |
| Hollow Palace | Four illustrated room layouts, the Porcelain Hound’s marked rush and interrupt, and a saved one-time falling chandelier that can hit the heroine or enemies. |
| Codex | In-game navigation, hidden entries and persisted encounters. |
| Audio | All 27 music cues and 20 effects imported. Checked cue routing, crossfades, action effects and peak headroom. A real laptop audio mix and normal shutdown passed. [Audio checks](AUDIO.md) |

The running game was captured in [the title](review/title-fine-pixel-1080.png), [hero preparation](review/preparation-fine-pixel-864.png), [Angela’s cut-in](review/ultimate-fine-pixel-1080.png), [a two-door route](review/branch-doors-and-minimap.png), [the curse altar](review/curse-altar.png), [the boss HUD and aiming preview](review/boss-health-and-aim.png), [His Moldy Majesty’s windup](review/majesty-windup.png), [paused character stats](review/pause-character.png), and [all five victory reactions](review/hero-victory-five.png).

## Android

The local Godot exporter produced a signed [ARM64 0.1.3 debug APK](../builds/GardenBadBloom-0.1.3-debug.apk). The manifest specifies landscape and declares zero permissions. Signature, archive integrity, embedded asset, and local renderer checks passed.

Fresh Godot imports and compile checks passed for the signed [0.1.5 APK](../builds/GardenBadBloom-0.1.5-debug.apk) and [0.1.6 APK](../builds/GardenBadBloom-0.1.6-debug.apk). The 0.1.6 package verification covered signatures, ZIP integrity, both forge art atlases, ARM64, landscape orientation and zero declared permissions. Gameplay and device acceptance are pending the owner's playtest. [Android export](EXPORT_ANDROID.md) · [0.1.6 player checks](PLAYTEST_0.1.6.md)

The [0.1.7 APK](../builds/GardenBadBloom-0.1.7-debug.apk) passed the clean import, compile, debug signing, archive, and manifest checks. The Android package embeds the new action and event art, board music, and boss fanfare. Its signer matches 0.1.4. Gameplay, automated gameplay suites, and phone checks remain with the owner. [0.1.7 player checks](PLAYTEST_0.1.7.md)

The [0.1.8 APK](../builds/GardenBadBloom-0.1.8-debug.apk) passed the clean import and compile, signing, archive, and Android manifest checks. The package contains both startup scenes, all seven prologue art textures and all ten prologue audio cues. Startup playback and phone testing remain with the owner. [Prologue player checks](PROLOGUE.md)

The [0.1.9 APK](../builds/GardenBadBloom-0.1.9-debug.apk) passed clean import, Godot compilation, debug signing, archive, and Android manifest checks. The package contains the upgrade atlas and both sound effects. Gameplay and phone checks remain with the owner. [Upgrade player checks](PLAYTEST_0.1.9.md)

The [0.1.10 APK](../builds/GardenBadBloom-0.1.10-debug.apk) passed clean import, Godot compilation, debug signing, archive, and Android manifest checks. Boss balance, save resume, and Three Caps discovery remain for the owner's phone playtest. [0.1.10 player checks](PLAYTEST_0.1.10.md)

The [0.1.11 APK](../builds/GardenBadBloom-0.1.11-debug.apk) passed clean import, Godot compilation, debug signing, archive, and Android manifest checks. All minigame scripts, the new art and audio, and the relic inspection panel are packaged. Touch feel, game timing, and reward and resume behavior remain for the owner's phone playtest. [0.1.11 player checks](PLAYTEST_0.1.11.md)

The [0.1.12 Android release](https://github.com/hugosyrf/garden-bad-bloom/releases/tag/v0.1.12) passed clean import, Godot compilation, signature, archive, and Android manifest checks. The package contains the media atlas and all 37 score cues. The README uses gameplay captures from earlier development builds. Gameplay and hardware verification remain with the owner. [0.1.12 player checks](PLAYTEST_0.1.12.md)

## Scope still open

The full catalogs, detailed sprite sets beyond the currently illustrated poses, and further presentation and accessibility work remain part of the release scope. The new combat balance awaits the next phone playtest.
