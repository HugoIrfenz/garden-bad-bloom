# GARDEN: BAD BLOOM
## Complete Game Concept, Art Direction, Content Encyclopedia & Implementation Contract

> **Owner direction after this bible was written.** The release orientation is landscape. Use the concept board as the visual reference throughout, with illustrated anime characters, expressive animation, and a consistent fine pixel finish across portraits, menus, dungeons, props and item art. Size the interface for the Xiaomi 14T Pro. Confirming End Run forfeits dungeon progress. Interruptions such as app termination preserve the active checkpoint. This direction takes precedence over the earlier orientation and run-exit proposals below. [Art direction](ART_DIRECTION.md)

**Tagline:** Cute chaos. Cruel dungeons. Endless bad decisions.  
**Document status:** Complete integrated game-design bible and binding content library; art finish can be revised after visual review while gameplay scope remains committed.  
**Target:** Completely offline, portrait-first Android action roguelike; single-player; native installable APK.  
**Engine:** Godot 4.x, GDScript, 2D rendering.  
**Audience:** A player who wants 3–30 minutes of satisfying, punishing dungeon crawling on a phone without internet, accounts, advertisements, or interruptions.  
**Primary player device:** Xiaomi 14T Pro.  
**Development directive:** Implement the *complete* game described here through sustained, milestone-by-milestone execution. Milestones are work organization, not a reduction of product scope. A design outline, attractive menu, single demo room, or playable slice does **not** fulfill the assignment. Keep implementing, testing and integrating systems until the full specified game is playable, saveable, balanced, and Android-exportable. Never claim a feature was completed without verifying it. If tooling or assets block an item, implement an honest functional fallback, record the exact blocker, and continue on independent work. Do not silently omit specifications.

---

## 01. Executive vision

**GARDEN: BAD BLOOM** is a cozy-looking, mechanically serious 2D top-down, room-based action roguelike. Five unmistakably different Garden heroines descend into endlessly remixed corrupted fantasy gardens. They explore, dodge, fight, loot, gamble, make irreversible decisions, lose runs, unlock discoveries, and return with more knowledge.

The joke is visual and narrative: round chibi protagonists, silly creatures, questionable consumables, absurd item descriptions and dramatic little reactions. The combat is not a joke: telegraphed threats, precise dodges, class expression, build-defining items, bosses with mechanics, meaningful risk, and genuine death consequences.

### Non-negotiable principles

1. **True offline-first and offline-only gameplay.** Every game screen, drop, seed, AI behavior, progression rule, procedural floor and saved run works in airplane mode from the first launch. No account, authentication, API key, network fetch, online time check, server, analytics, ads, paywall or in-app purchase.
2. **Actually a game.** The player walks around 2D rooms, enemies move and attack, weapons connect, dodges matter, loot changes builds, shops function, bosses can be beaten, death ends runs, and infinite mode generates new playable content.
3. **Five legitimate playable characters.** Angela, Vivianne, Nixia, Virelia and Zaria each have a separate combat identity, sprites, abilities, animations, resource systems and progression.
4. **Garden identity is preserved.** Use the character canon below and recognizable personalities, not replaceable generic fantasy models.
5. **Controls designed for phones.** Portrait play, one-handed-friendly movement, generous touch zones, optional aim assist, legible combat, configurable buttons.
6. **Punishing but fair.** Threats are readable; mistakes hurt; a player who learns patterns and improves can win without grinding stat upgrades.
7. **Procedurally replayable.** Map routes, encounters, rewards, modifiers, hazards and event choices meaningfully recombine.
8. **Synergy-first items.** A build should become strange and expressive, not merely increase a percentage.
9. **Local persistence.** Reliable autosaving, resume mid-run, permanent unlocks, no save corruption on app kill or low battery.
10. **Honest completion.** Tests, gameplay validation, verified Android build instructions, and truthfully reported limitations.

### Emotional cadence

**Cozy hub → temptation → confident first rooms → surprise and adaptation → dangerous build expression → boss panic → victory or humiliating death → a short, funny return to the Garden → one more run.**

### Working title convention

Use `GARDEN: BAD BLOOM` in all menus and docs unless changed by the project owner. The title is not a lore constraint.

---

## 02. Visual identity — the Garden look

### Approved direction to prototype visually

**Hand-drawn-feeling, soft-edged 2D chibi with bold readable outlines**, not intricate HD character art and not a purely tile-pixel game. Small sprites are built from simple shape language and flat color planes. Think illustrated storybook clarity, expressive face icons and unusually dramatic combat effects. The game should look cozy while idle and absurdly kinetic when fighting.

- Full-body protagonists around **2.5–3 heads high**; slightly chubbier heads for readability, small hands and feet, fully clothed, non-suggestive; retain hairstyle, eye colors and signature clothing.
- Primary silhouette distinguishes a character before color is added. Hair contour and weapon silhouette are more important than fine fabric details.
- Use consistent dark warm outlines with selective colored inner strokes; base shade, one shadow tone, one highlight tone plus tiny selective glow.
- Slight squash/stretch, tilt, pop, smear and blink animations are encouraged. Avoid excessively bouncy movement that hides hurtboxes.
- Palette: warm, tranquil Garden hub; cool or spectral highlights on magic; each hostile biome has one dominant color family and one contrasting hazard color.
- Mobile readability: iconography over fine text, shape/animation warnings in addition to color, high-contrast silhouettes against floor tiles.
- Final asset style must stay consistent across portraits, in-world characters, enemies, props, items and UI, even if assets are produced by multiple AI sessions.

### Character likeness hierarchy

1. Canonical hair shape and color.
2. Canonical eyes and face expression.
3. Canonical outfit cues and signature accessories.
4. Silhouette and proportion in chibi form.
5. Class equipment layered over recognizable Garden identity.

Character skins may adapt outfits to fantasy combat, but must not erase the original identity. Avoid turning everyone into generic armored adventurers.

### Character visual reference canon

| Hero | Stable visual anchors | Outfit adaptation | Movement signature |
|---|---|---|---|
| **Angela Lily Solstice** | Short layered icy light-blue bob, darker roots, amber-gold eyes; confident tsundere expressions | White/blue coat, blouse/tie and dark skirt references; attach small knight pauldrons, sword and shield, not a full face-covering helmet | Firm forward steps, defensive shoulder stance, dismissive hair flick, shield bracing |
| **Vivianne Rose Astralis** | Very long silver/platinum-white hair, crimson/red sleepy eyes, oversized black sweater | Dark flowing witch sweater/robe hybrid, tiny rose details, ornate floating grimoire | Glides rather than stomps, sleepy unimpressed blink, elegant spell circles |
| **Nixia Orchid** | Silver/white bob with twin buns, magenta-crimson eyes, purple ribbons/underglow, black-purple gothic/cyber elements; slightly smaller sprite | Oversized dark sweater/cyber-goth wraps and hilariously big gauntlets | Too-fast tiny punches, angry foot taps, smug victory face |
| **Virelia Camellia** | Dusty-pink/pink braids or half-up floral hairstyle, golden eyes, freckles, gentle maid-inspired aesthetic, camellia ornament | Pink/cream floral dress with a ranger capelet, ribboned bow and careful utility belt | Deliberate footwork, neat posture, adjusts ribbon after fights |
| **Zaria Iris** | Asymmetrical teal/cyan-blue hair distinct from Angela's icy blue; two differently colored eyes (amber/blue), oversized black jacket, olive accent top | Street-art rogue with lightweight jacket, asymmetric straps, paint-tinted dual daggers | Fast sideways slides, irregular asymmetrical attack poses, playful graffiti trails |

**Continuity note:** Past drawings have varied in details, particularly Virelia's hairstyle and Zaria's costume. Treat these anchors as the strongest currently established direction, and use any later owner-approved character reference sheets as authority rather than silently improvising a replacement.

### Size / camera / base asset proposal

- Portrait-oriented virtual design resolution around **390 × 844** with scalable viewport and safe-area handling. These are design targets, not fixed device assumptions.
- Base gameplay tile around **24 logical pixels**; world-art sprite footprint around **48 × 48 or 48 × 64 logical pixels** depending on hair/weapon, with transparent padding. Final precise sizes decided after in-engine readability check.
- Character collision shape remains tight and consistent across skins despite oversized hair/weapon art.
- In each room, the camera and playfield should show enough space to anticipate projectiles; dynamically adjust room framing within fixed zoom limits.
- Keep dialogue and small labels above the playfield when possible; never obscure dodging with loot text.
- Prefer authored modular base shapes and small animation sets enhanced with code-driven weapon arcs, particles, stretch, offsets and hit flashes over unrealistic demands for hundreds of unique image frames.
- Art exported at consistent scale, transparent backgrounds, canonical layer order, pivot alignment and filename conventions.

### Animation minimums per hero

Idle (blink, breathing, expression), four-direction walking, attack windup, attack recovery, dodge, skill cast, charged/special attack, hit reaction, knockback, death, victory, interact, equipment visual overlays, alternate-form transformation. A readable four-direction approach may use mirrored side views when it does not break asymmetric identity cues. Effects should correspond to hitboxes and frame timing.

### UI art language

Paper-like cream menu cards in hub, midnight ink framing, petals and tiny corner vines, bronze/copper outlines for rare items, readable round sans typography, clean high-contrast HUD. Avoid excessive gradients, ornamental clutter or tiny text. Buttons must be touch-friendly and visually distinct from non-interactive labels.

---

## 03. Narrative premise, tone and world logic

The Garden is a safe little sanctuary for five very different girls. One evening, the **Bloomheart**, an old wishing mechanism beneath the Garden, begins interpreting harmless wishes too literally. Forgotten objects, stray dreams, flowers, unfinished paintings and petty annoyances sprout into impossible underground worlds. Every door opens into a different improbable nightmare.

Nobody needs a solemn prophecy. The girls go downstairs to stop the mess because it is getting on their nerves. Naturally, they make it worse.

**Narrative priority:** gameplay first, brief charming story delivery. No long unskippable cutscenes. Optional log entries, environmental gags, a few choice events, short hero-specific quips.

**The Garden hub:** warm home, flowers, upgrade benches, five girls idling, a suspiciously decorated entrance and many cozy decorations. The hub is deliberately safer and brighter than the dungeons.

**Dungeon tone:** each biome looks like a nursery story illustrated by someone who doesn't understand danger. Cute props become threats. Ordinary objects acquire exaggerated boss importance. Later tiers grow more ominous without becoming visually muddy or abandoning humor.

**Lore principle:** A corrupted echo, dream or alternate incarnation is a *game encounter*, not a retcon of a Garden character's core canon. For example, an optional `Echo of Angela` boss is not the real Angela turning evil.

**Dialogue examples:**
- Angela: “If this plant stabs me one more time, I'm pruning the entire dimension.”
- Vivianne: “The petals are mourning. How pretty. How inconvenient.”
- Nixia: “BIG MONSTER. LITTLE PROBLEM.”
- Virelia: “I made a list of what went wrong. It's... very long.”
- Zaria: “Hear me out. What if we paint the boss?”

Writing remains short, varied and optional, without spamming lines on every attack.

---

## 04. Player loop and run structure

### Main loop

1. Open offline game → local save loads → enter animated Garden hub.
2. Choose one of five girls, starting weapon, earned cosmetic, accessibility settings, optionally a seed or challenge.
3. Descend via a run entrance; procedural chapter/floor/room graph is generated from deterministic seeds.
4. Move and fight in top-down walkable rooms; dodge telegraphed attacks; open chests, collect petals, shop, choose route, interact with text-choice events.
5. Assemble build-defining equipment and traits; make one-way decisions between safety and power.
6. Fight boss with at least two meaningful attack patterns, including higher-tier variants; choose reward and proceed.
7. Reach a run clear, die permanently, or keep pushing into the Endless. Every outcome is recorded locally.
8. Return to the Garden hub; view run stats, new discoveries, unlocks and personal bests; start again.

### Intended session rhythm

- Quick break: a few rooms / a short run attempt ~3–8 minutes.
- Regular session: meaningful chapter and boss attempt ~10–25 minutes.
- Extended session: successive chapters or Endless challenge until death or manual suspend.

**No real-time dependency:** no stamina timers, daily internet events or online cooldowns. Play as much or as little as desired.

### Run outcomes

- **Death:** the active run is closed irrevocably; all run-only inventory and currency disappear; a run record is saved.
- **Standard clear:** defeating the core arc unlocks Endless progression while preserving optional run continuation. A clear is a real win, not a fake ending.
- **Retire:** a deliberate player action at permitted transition points ends the run with a lesser but coherent record, not a hidden free restart.
- **Suspend/resume:** quitting or backgrounding should resume the exact run instead of rerolling events or avoiding damage.

---

## 05. Core action combat

### Controls

- Left: floating virtual joystick for 8-direction movement.
- Right: big attack button, dodge button, skill button and a contextual ultimate/special button (some actions can share space contextually).
- Contextual interact button near chests, doors, altars and shops.
- Aim: optional directional auto-targeting toward the nearest eligible hostile in a configurable cone/range; manual aim via drag from attack button or right touch region; simple tap-target option is optional.
- Accessibility: button positions and sizes adjustable, vibration optional, screen shake slider, low-effects mode, high contrast hazards, vibration/audio cues, left-handed flip, readable text scaling.
- Buttons should never overlap Android navigation areas, notches, foldable insets or dialogue overlays.
- A dedicated pause button opens settings and allows safe suspend; no internet.

### Combat rules

- Actual 2D physics collisions; enemies and attacks respect wall, cover and hazard rules.
- Attack state contains windup, active frames, recovery, damage amount/type, knockback, range, hitstop, and cancel rules.
- Dodges have clearly tuned travel, invulnerability frames, cooldown/resource cost, and visible telegraph, rather than permanent invulnerability.
- Enemy attacks telegraph with animations or geometric danger markings with sufficient reaction windows. Harder elites may use complex patterns but no invisible instant hits.
- Terrain can block some projectiles; line-of-sight and collision masks are explicit.
- Hit feedback: sound, flash, tiny recoil, damage numbers (toggle), visual trail, restrained screen shake.
- Death feedback: screen pause, brief breakdown of cause, funny hero-specific sentence, full end-of-run report.
- Stagger, status and damage-over-time obey shared predictable rules.
- Invulnerability after taking damage prevents unfair multi-hit bursts, except explicitly communicated multi-stage hazards.

### Damage / resources

Common baseline: HP, base attack, attack interval, move speed, armor/defense, crit chance, crit effect, dodge recovery, knockback resistance, elemental status resistance. Each hero adds one bespoke combat resource. Avoid a huge generic stat sheet on the main HUD; show details in inventory.

Damage types: physical, fire, frost, poison, arcane, thorn, void. Resistances and weaknesses are present but not mandatory rock-paper-scissors matchups. Apply multiplicative stacking caps and explicit order of operations to prevent overflow and unbounded exploit loops while retaining wild builds.

### Combat fairness constraints

- All attacks require detectable warning, consistent physics, meaningful dodge/avoid counterplay.
- Never spawn an unavoidable enemy strike directly on entry.
- Reserve minimum free movement paths and safe-spawn radius per room.
- No opaque particle veil covering damaging telegraphs.
- Bosses should test build understanding and dodge skill, not merely have absurdly scaled HP.
- Discrete difficulty increase via new moves, combinations, room modifiers and occasional elites, not only large numbers.

---

## 06. The five classes — full kits

### 06.1 Angela — Knight / Counterguard

**Gameplay fantasy:** “If you want to hurt anyone, get through me first.” Durable melee duelist who converts defense and timing into explosive counterattacks. Resource **Resolve**, earned from perfect blocks, close escapes and absorbing limited damage.

- **Starting weapon:** Lilyblade, a compact sword with a broad, legible arc.
- **Basic attack:** three-hit sword string; final hit pushes small enemies back.
- **Dodge:** armored side-step, somewhat shorter range, low vulnerability afterward.
- **Active skill:** `Royal Guard` — a timed frontal block; successful perfect guard refunds some cooldown and primes a counter slash.
- **Ultimate:** `Last Stand` — temporary guard aura and empowered counter attacks; no indefinite invulnerability.
- **Passive:** `Stubborn Bloom` — damaged armor bolsters Resolve briefly, with diminishing returns.
- **Strength:** survivability, boss parry windows, reactive damage.
- **Weakness:** lower chase mobility and reduced long-range area denial.
- **Upgrade themes:** Thornmail, Oathblade, Counterclock, Rosewall, Retribution.
- **Visual effects:** amber shield sparks, cool-blue sword arc, petals hardening into protective segments.
- **Secret aspect:** `The Bloodbride` — a curse-powered HP-sacrifice sword path, optional and discoverable, never the default hero portrayal.
- **Personality details:** exasperated side-eye when a trap hits; tiny smug smile on successful perfect guard.

### 06.2 Vivianne — Witch / Roseweaver

**Gameplay fantasy:** sleepy poet casting beautiful, devastating magic. Resource **Ink**, replenished through positioning, spell echoes and controlled attacks.

- **Starting weapon:** Rosebound Grimoire.
- **Basic attack:** small homing rose-thorns with limited turn speed and terrain collision.
- **Dodge:** drifting shadow-step; slightly slower startup but leaves a decoy petal.
- **Active skill:** `Midnight Verse` — a patterned area spell with delayed blooming damage; careful placement rewarded.
- **Ultimate:** `Elegy of Thorns` — timed chained spell crescendos, greatest effect when battlefield zones overlap strategically.
- **Passive:** `Lingering Line` — spells can leave short-lived residue that increases synergy for the next spell.
- **Strength:** area control, multi-target burst, elemental reactions.
- **Weakness:** frailty, overcommitting while channeling.
- **Upgrade themes:** Black Roses, Eternal Rhyme, Inkstorm, Lullaby, Moonlit Manuscript.
- **Visual effects:** crimson petals, ink calligraphy, black-white spell circles.
- **Secret aspect:** `The Last Poet` — curses, enormous spell range, fragile survival.
- **Personality details:** sleepy eye-roll while channeling; several short lyrical item reactions.

### 06.3 Nixia — Brawler / Security Gremlin

**Gameplay fantasy:** the smallest menace on the map, chaining punches, dashes and defensive intrusion counters. Resource **Momentum**, built by staying aggressive without getting hit.

- **Starting weapon:** Orchid Gauntlets.
- **Basic attack:** extremely fast melee jab/combo string; finisher launches enemies slightly.
- **Dodge:** swift short dash with a snap-back option depending on upgrade.
- **Active skill:** `Unauthorized Access` — leap, stun a small cone, then rapid follow-up if successful.
- **Ultimate:** `SECURITY BREACH` — burst of ferocious combo strikes that can launch smaller enemies into others.
- **Passive:** `Smug Streak` — sustained clean hits build Momentum, reset partially by getting damaged.
- **Strength:** close-range DPS, combo tempo, crowd-juggling.
- **Weakness:** dangerous proximity, limited ranged options.
- **Upgrade themes:** Tiny Fists, Combo Firewall, Critical Overload, Punch Cascade, Threat Detector.
- **Visual effects:** magenta glitch sparks, oversized purple impact stamps, jaw-dropping cartoon uppercut silhouettes.
- **Secret aspect:** `Root Administrator` — precision combo chains that mark and explosively delete enemy formations.
- **Personality details:** smug :3, tiny victory stomp, exaggerated rage when a punch misses.

### 06.4 Virelia — Ranger / Camellia Warden

**Gameplay fantasy:** patient precision and orderly battlefield control. Resource **Focus**, gained via accurate consecutive hits, traps and clean positioning.

- **Starting weapon:** Camellia Longbow.
- **Basic attack:** directional arrows with stronger payoff for deliberate aim.
- **Dodge:** elegant evasive step that can prime a precision shot.
- **Active skill:** `Tidy Arrangement` — place a ribbon snare or botanical trap that repositions/slows enemies.
- **Ultimate:** `Perfect Bloom` — fan of guided, controllable arrows favoring marked targets.
- **Passive:** `Neat Work` — consecutive marked weak-point hits increase precision up to a capped bonus; misses reduce Focus.
- **Strength:** range, traps, accuracy, projectile control.
- **Weakness:** rushed close-quarters battles.
- **Upgrade themes:** Recurve Bloom, Perfect Ledger, Petal Snare, Ricochet Thread, Bloomstring.
- **Visual effects:** soft pink ribbons, gold crosshair petals, polished clean projectile arcs.
- **Secret aspect:** `The Thousandfold Archivist` — linked trap webs and cascading marked arrows.
- **Personality details:** straightens the environment, startled face when enemy breaks formation.

### 06.5 Zaria — Rogue / Chaos Painter

**Gameplay fantasy:** fast experimental assassin who paints dangerous routes and weapon effects. Resource **Spark**, generated from flanks, creative movement and status combinations.

- **Starting weapon:** Iris Twin Daggers.
- **Basic attack:** paired dagger strikes with positional bonus from flank/back angles.
- **Dodge:** painterly blink-slash, with strict line-of-sight and invulnerability rules.
- **Active skill:** `Graffiti Cut` — slash and paint a temporary trail that alters enemy positioning or damage type.
- **Ultimate:** `Beautiful Disaster` — a controlled burst of paint-shard daggers that interacts with existing status and trails.
- **Passive:** `Unfinished Masterpiece` — changing approach/element/angle yields a small combo bonus; repetitive spam has diminishing returns.
- **Strength:** mobility, burst, unusual combos, high-skill route planning.
- **Weakness:** low raw durability, risky positioning.
- **Upgrade themes:** Prism Dagger, Splatter Critical, Color Theft, Painted Exit, Stroke of Luck.
- **Visual effects:** cyan-to-violet trails, multicolor ink cuts; don't confuse base hair color with Angela's paler blue.
- **Secret aspect:** `Living Masterpiece` — paints temporary moving hazard art that the player can choreograph.
- **Personality details:** little doodles after victory, wink when a risky attack lands.

### Hero balancing promise

All five should be viable for both standard clear and endless high-score play. Keep unique advantages; don't homogenize them. Track damage done, average hit taken, clear rates, boss success and item compatibility via offline test runs and manual playtesting. Never require an online balance service.

---

## 07. Dungeon topology, room types and procedural generation

### Core structure

Run consists of chapters containing floors. Each floor has a small directed map graph of room nodes with 1–3 meaningful branching decisions. A room is a discrete walkable combat arena. Doors activate when completion conditions are satisfied. Some nodes are optional risk/reward paths.

### Room types

1. **Combat:** scripted enemy group using encounter budget, changing spawn positions and variant patterns.
2. **Elite:** formidable enemy with announced modifier and better rewards.
3. **Treasure:** choose one of visible rewards or open a risky chest.
4. **Shop:** spend run-only Petals on weapons, relics, healing, rerolls and repairs.
5. **Event:** short text interaction with meaningful cost/benefit and often comedic consequences.
6. **Rest:** recover some health or improve one item, never always both.
7. **Curse altar:** trade a permanent-within-run penalty for major power.
8. **Challenge:** timed survival, avoid hazards, or protect a fragile flower; reward tied to completion.
9. **Secret:** hidden entry with unusual loot, lore, cosmetic discovery or miniboss.
10. **Boss:** gated capstone with entry presentation, attack patterns, phase behavior, actual victory and chapter transition.
11. **Transitional:** safe scenic breathing room, map preview and exit.

### Generator rules

- Use a seeded **graph-first generator**: guarantee route from entrance to boss, then assign branches and room types under constraints.
- Validate connectedness and prevent softlocks, unreachable rooms, intersecting invalid doors, impossible shop positions, unopenable chests, or blocked critical routes.
- Room templates have door sockets, walkable tile mask, cover cells, hazard slots, spawn slots and aesthetic prop placements.
- Choose encounter composition by threat budget constrained to room size, biome, floor, hero mobility and desired difficulty.
- Rewards and enemy spawns derive from stable sub-seeds so adding an unrelated random call doesn't change all later floors unexpectedly.
- Do not place lethal hazards under spawn points or behind non-telegraphed door transitions.
- Allow player agency: room map shows upcoming category icons when discovered; riskier branches promise visible reward categories.
- Spawn pacing: short anticipation, active encounter, clear confirmation, calm loot pickup, path choice.

### Proposed default floor cadence

Each floor commonly offers ~6–10 traversed rooms (from a larger graph of optional nodes); choose shorter patterns for fast play and longer elite/exploration paths when a player opts in. A major boss appears on authored chapter milestones. Seeded variants may alter pacing but not promise infinite unstructured hallways.

### Determinism

RunSeed, chapter/floor IDs, room IDs, item-pool version and relevant RNG substream state are stored. Same seed + game content version should produce reproducible map and loot possibilities, modulo explicitly recorded player decisions. Persist all decisions and draw counters. No dependence on wall-clock time or network.

---

## 08. Biomes and signature room art

Each biome includes ground palette, decorative walls, hazards, enemy roster, themed music/sound, lighting accents, room templates, miniboss and chapter boss. Biomes should not merely swap texture colors.

### I — Forgotten Garden

**Look:** sunlit olive greens, warm brick, overgrown pale stone, cracked fountains, large flowers, abandoned watering cans.  
**Hazards:** snapping thorn patches, root traps, pea-shooter plants.  
**Enemies:** Grumble Tulip, Thorn Slug, Carrot Screamer, Hedge Knight.  
**Boss:** `The Gardener That Forgot` — oversized scarecrow with shears; phase two uproots cover and grows thorn lanes.  
**Readability:** dark-green foes with pale outlines against desaturated light grass; thorn warnings are bright coral.

### II — Mushroom Kingdom

**Look:** luminous violet and teal mushrooms, soft cave floors, damp caps, bioluminescent spores, huge gills.  
**Hazards:** poison clouds, spore pulses, mushrooms exploding after a countdown.  
**Enemies:** Knife Shroom, Puffball Bomber, Spore Butler, Mycelium Leaper.  
**Boss:** `His Moldy Majesty` — comical caped mushroom wielding two butcher knives; telegraphed spinning cleave, spore charges, crown-summon phase.  
**Readability:** projectiles bright lime; explosions first show orange ring.

### III — Clockwork Conservatory

**Look:** brass, pastel turquoise machinery, glass greenhouse panes, floating clock hands, mechanical flowers.  
**Hazards:** timed gears, rotating laser hands, conveyor tiles and crush pistons.  
**Enemies:** Tin Bee, Pendulum Mouse, Clockwork Rose, Brass Butler.  
**Boss:** `The Late Bell` — living grandfather clock with swinging-arm timing puzzle, fixed cadence attacks and phase-broken tempo.  
**Readability:** amber countdown markings and loud attack rhythm cues.

### IV — Bloodbloom Forest

**Look:** pale trunks, vivid crimson flower fields, black vines, hanging lantern blossoms, velvety shadows.  
**Hazards:** lifedrain thorns, infection puddles, blood blossom pulses.  
**Enemies:** Siphon Moth, Hemlock Doe, Bloom Leech, Thorn Widow.  
**Boss:** `The Weeping Orchard` — rooted tree apparition that drains marked floor zones; phase two reveals moving weak points.  
**Readability:** crimson dangers against bone-white soil; avoid red-on-red hazards.

### V — Hollow Palace

**Look:** ivory, dusty rose, cracked mosaic, chandeliers, enormous dining tables, cold stained glass.  
**Hazards:** falling chandeliers, shifting furniture cover, mirror decoys, cursed checkered tiles.  
**Enemies:** Teacup Duelist, Wailing Curtain, Hollow Knight, Dancing Chair.  
**Boss:** `Duchess of the Last Tea` — walking teapot monarch; projectiles, steam arena denial, porcelain clone cups.  
**Readability:** steam indicated with filled hatched circles before it becomes opaque.

### VI — Astral Greenhouse

**Look:** floating glass islands, deep indigo stars, luminous pollen, translucent flowers, improbable constellations.  
**Hazards:** blink portals, delayed starlight rays, periodic low-gravity movement events with clear signage.  
**Enemies:** Starseed Wisp, Orbiting Bloom, Mirror Moth, Nebula Doll.  
**Boss:** `The Starbound Florist` — rearranges star-lanes and summons moving constellations.  
**Readability:** geometry-first attacks, glowing white edges, limited background motion.

### VII — Bloomheart Core

**Look:** ruined cozy hub fragments folded into a giant biome collage; the Bloomheart is a beautiful, malfunctioning wish machine intertwined with flowers.  
**Hazards:** combinations of previously learned mechanics; new tell patterns but no arbitrary instant kills.  
**Boss:** `The Bloomheart, Unraveled` — multistage narrative capstone. The player wins through positioning, mechanics and damage. Defeat of this boss produces a meaningful standard clear ending.

### VIII+ — The Endless

The world recombines biome rooms, curated hazards, enemy families, elites, bosses, rare events and **mutators** beyond the normal chapter arc. Every several floors grants an occasional shrine, rare merchant, mini-story or new boss remix. As floor count grows, difficulty evolves mostly through encounter combinations, pattern complexity and modifiers. HP/damage scaling is capped or softened to avoid turning the mode into pure number inflation. The mode continues algorithmically without requiring authoring a literal infinite number of rooms.

**Sample mutators:** `Double Boss` (only on compatible encounters), `No Free Healing`, `Volatile Corpses`, `Long Shadows`, `Reverse Projectiles` (clear warning), `Triple Loot / Tougher Elites`, `Poison Rain` (safe zones), `Fast Clock`, `Cursed Bargains`, `Brittle Armor`, `Mimic Season`.

**Compatibility matrix:** Mutators have tags and conflict rules; prevent impossible or unreadable combinations. Surface active mutators before the player commits to the floor.

---

## 09. Enemy taxonomy and combat roles

An enemy should be recognized by silhouette and opening animation within a moment. Every roster needs distinct threat behaviors; merely higher HP does not make an enemy new.

**Roles**

- **Chaser:** closes distance, pressures movement, exposed after failed lunge.
- **Shooter:** projects visible, slow enough-to-read bullets or arcs; uses spacing.
- **Controller:** creates zones, traps or slow fields that reshape safe lanes.
- **Flanker:** takes side routes; warns before pounce.
- **Support:** buffs/heals allies with clearly visible link; priority-target puzzle.
- **Bomber:** countdown, predictable telegraph, stronger if ignored.
- **Summoner:** limited adds with quotas to prevent impossible floods.
- **Shielded:** specific counterplay to direction/timing/status.
- **Miniboss:** distinct patterns and a reward worth its risk.

**Elite modifications:** larger but not absurd silhouette, recognizable crown/badge, one added mechanic (e.g., shield pulse, orbiting knives, poison trail), extra drop and currency. Elite modifiers never remove mandatory attack tells.

**Funny attack design examples**

- Knife Shroom raises a ridiculously oversized knife for a full tell, then dashes; a miss leaves it dizzy.
- Teacup Duelist launches a cup saucer in a returning boomerang arc.
- Wailing Curtain briefly blinds only the perimeter, leaving a readable safe center.
- Carrot Screamer's scream shoves nearby enemies into new formations.
- Clockwork Rose fires petals on every second clock tick, allowing deliberate rhythm play.

**Enemy AI fundamentals:** simple deterministic state machines (idle, alert, move, windup, attack, recovery, stagger, death), line-of-sight checks, steering away from invalid geometry, capped nearby attackers, no omniscient instant repositioning. Boss phases use explicit pattern controllers instead of generic wandering AI.

---

## 10. Boss design contract

A full boss encounter has: unique silhouette and arena, readable intro, at least three attacks (including a punishable recovery window), phase transition or significant pattern evolution, fair add management, suitable reward, codex entry and death statistic.

Bosses may become optional mutated Endless versions with altered arena, one added mechanic and additional prize. Hero secrets may spawn **Echo** boss encounters without altering canon.

**Illustrative boss: His Moldy Majesty**

- **Attack A:** dual knife cross-slash; near-side tells appear on floor, followed by short recovery.
- **Attack B:** drops three puffballs with visible fuses; explosion chains can be redirected into boss.
- **Attack C:** crown toss boomerang; leaving a long safe arc in another quadrant.
- **Phase 2 at ~50% HP:** cape tears; dual knife cyclone moves along predicted lanes, and the boss summons exactly two Knife Shrooms. Do not infinitely spawn adds.
- **Counterplay:** find diagonal gaps and punish exposed cap after his failed lunge.
- **Reward:** pick one of `Royal Mycelium`, `Twin Cleavers`, or `Spoiled Crown` curse; rewards change playstyle.

**Illustrative hidden boss:** `Echo of Angela, the Fallen Bride`, an optional corrupted reflection encounter born from accumulated curse conditions. It is not Angela herself. Uses shield-counter patterns and dark sword arcs, with explicit distinct tells from playable Angela.

---

## 11. Weapons, items, rarity, curses and synergies

### Equipment slots

- **Weapon** (hero-specific start; some off-class rare alternatives with appropriate animation support).
- **Relics** (build-altering passives, no need for complex manual equip management).
- **Charms** (small passive modifiers, set pieces).
- **Consumables** (healing, temporary bombs, map reveal, antidotes, special event tokens).
- **Curses** (separate tracked modifiers with both positive and negative consequences).

Make the inventory panel show concise behavior descriptions and synergy tags; long-form exact stats accessible by tap. Allow item comparisons and one-step replacement decisions. Avoid meaningless loot clutter and infinite backpacks.

### Rarity names

Common → Uncommon → Rare → Epic → Legendary → Forbidden. Color plus icon/shape label so rarity is never dependent on color alone. `Forbidden` is risk/reward, not always best.

### Build themes

Guard/Counter, Poison/DoT, Crit, Combo, Projectile/Trickshot, Spell Echo, Summoning, Explosion, Mobility, Low-HP Berserk, Curse Conversion, Trap Network, Elemental Reaction, Petal Economy.

### Item examples — each changes play behavior

1. **Butter Knife of Doom:** weaker basic attacks; every seventh registered hit executes an eligible non-boss normal enemy, with bosses receiving a capped burst instead.
2. **Angela's Wedding Ring:** once per floor, survive an otherwise lethal hit at 1 HP and get brief invulnerability; no loop exploit.
3. **Nixia's Questionable Potion:** healing triggers a small friendly explosion centered on the player; risk from knockback or enemy aggro, not arbitrary self-destruction with no warning.
4. **The Cursed Lily:** double an offensive multiplier in exchange for disabling conventional healing for this run; clearly warn before pick.
5. **Rosebound Refrain:** a spell echoes once at reduced power after a delay, but increases recharge cost.
6. **Pocket Scarecrow:** deploy an expendable decoy on dodge every few seconds.
7. **Ricochet Ribbon:** Virelia's marked arrows bounce once to another marked target.
8. **Painted Exit:** Zaria leaves a temporary portal marker behind after skill use; next dodge can return to it once.
9. **Thornmail:** perfect guards spray thorns toward the most recent attackers.
10. **Compost Dividend:** killing elites grants additional Petals but merchants charge more.
11. **Mushroom Crown:** poison explosions briefly summon a tiny temporary shroom ally.
12. **Cracked Hourglass:** dodging a telegraphed attack at the last moment slightly slows enemy projectiles.
13. **Moth Lantern:** reveal concealed traps; nearby curse foes become more aggressive.
14. **A Suspicious Sock:** huge move speed on empty rooms, reduced defense in combat; intentionally silly.
15. **Teapot Insurance:** first projectile hit each room is nullified but spills slow steam around the hero.
16. **Seven Bad Decisions:** after seven cursed event choices, convert one severe curse into a unique risky legendary modifier.
17. **Bloomstring:** marked enemies share a portion of trap damage with nearby marked enemies.
18. **Guardian's Ledger:** blocks cause the next basic attack to hit an additional adjacent target.
19. **Black Rose Ink:** overlapping magical residue creates a small gravity well.
20. **Glitter Crime:** critical strikes briefly paint the floor; stepping on paint creates an additional low-damage slash.

### Set and evolution system

- Three themed items can unlock a set perk, but do not require rigid exact-match loot every run.
- Some two-item interactions create **evolved weapons** that replace animations and gameplay rules; all evolutions need clear descriptions and visual effects.
- Example: `Thornmail + Guardian's Ledger + Royal Guard mastery → Rosewall Execution`.
- Example: `Rosebound Refrain + Black Rose Ink → Elegy Spiral`.
- Example: `Glitter Crime + Painted Exit → Colorstorm Path`.
- Examples are illustrative: content library must provide multiple real evolutions across all five girls, not just these three.

### Loot fairness

Randomness matters, but prevent dead-end runs with entirely unusable class items. Weighted class synergy and some neutral items; guarantee periodic meaningful choice opportunities. Shop and event costs are shown before commitment. Strong items must carry interesting opportunity costs rather than being unconditionally dominant.

---

## 12. Gold, shops and between-run progress

### Currencies

- **Petals:** acquired only during a run; spent at shops, special altars or rerolls; lost when the run ends. No real money.
- **Garden Seeds:** earned upon run conclusion from achievements, meaningful floor progress, bosses, exploration, discovery and class mastery; used for permanent *breadth-oriented* unlocks. No offline timer/regen.

### Shops

Merchant UI pauses combat. Stock generated deterministically on entering shop, with item rarity linked to floor and economy. Items show exact costs, required slots, and purchase results. Limited reroll cost escalates, preserving meaningful decisions. Special shops may accept HP, curses or a current relic instead of Petals.

### Garden progression

Unlock alternative starting weapons, extra item possibilities, new enemy records, events, costumes, alternate hero aspects, decorative hub elements, music and challenge rules. A small number of permanent mechanical bonuses may exist but are deliberately capped; **player mastery should remain the primary source of success**.

### Codex

Stores discovered enemies, bosses, items, secret aspects, run stories, best streaks, and funny death causes. Undiscovered content appears as silhouettes or question marks; do not expose every secret in default tooltips.

---

## 13. Text events in a real-time game

Text-driven decisions are a compact encounter type, not a substitute for walkable dungeon exploration. Events are short, charming, risk-aware and mechanically meaningful.

**Example — Suspicious Angela Statue**

>A marble Angela holds a cup of glowing tea. A plaque reads: “Trust me, darling.”
>
>**Drink** — Lose 35% of current HP, choose one powerful relic.  
>**Refuse** — Leave unharmed, but the statue looks insulted.  
>**Bow dramatically** — Spend 25 Petals to reveal a hidden reward or harmless joke.

**Example — Nixia's Firewall**

> A tiny purple padlock has sealed the exit and demands proof that you are not a mushroom.
>
>**Punch it** — Fight an elite mini-encounter for good loot.  
>**Solve three rotating runes** — Small timing minigame; earn a safe reward.  
>**Pay its ridiculous fee** — Spend Petals and leave.

**Example — Virelia's Lost Checklist**

> The list is perfectly tidy, except the last line reads “???”.
>
>**Return it** — Reveal next floor node type.  
>**Write your own name** — Obtain a temporary map blessing plus a small curse.  
>**Eat the list** — Restore a little HP, lose a random nonessential consumable.

Event system stores option availability, exact consequences, and RNG outcomes; no arbitrary choices where all text options secretly lead to the same result.

---

## 14. Death, difficulty, clears and Endless

### Death is meaningful

A death closes the active run and destroys temporary equipment, Petals and temporary buffs. A hero-specific funny death quote and explicit cause display. Garden Seeds / codex discovery persist. No permanent deletion of the whole save.

### No false difficulty

- New threats, combined attack patterns, elite types, hazardous routes, mutation restrictions and player decisions drive later difficulty.
- Numeric scaling grows at diminishing rates; danger values are bounded where needed to preserve reactions.
- Never rely on huge sacks of HP as a substitute for encounter design.
- Do not make unavoidable chaos under the pretense of being “hardcore.”

### Standard campaign and Endless

The major arc through the Bloomheart Core provides a defined achievement and ending. Afterwards, the same run can opt into Endless if alive. Endless recombines rooms, mutators, enhanced bosses, reward pools and rare secrets indefinitely as generated content. It tracks deepest floor, elite kills, bosses defeated, score and character-specific records locally.

### Difficulty configuration

- `Garden Walk`: optional accessibility / learning mode with softer timings; clearly separate records.
- `Bloom`: intended punishing standard rules.
- `Thornbound`: unlocked hard rules: more complex patterns, fewer recovery windows, stricter economy, new modifiers; no hidden unfairness.
- Additional optional self-imposed challenge modifiers and seed selection, each recorded in run history.

**No online leaderboard** is required or permitted for the offline design. Personal records and locally seeded challenge runs are sufficient.

---

## 15. Hub, menus and interface

### Home / Garden hub

Animated diorama of a little Garden. Five heroines appear in chibi form and occasionally interact; tap a heroine to select. Hotspots for `Descend`, `Characters`, `Codex`, `Garden Bench`, `Records`, `Settings`. Hub objects are small and tactile without making menus hard to locate. A current suspended run displays `Resume Run` prominently.

### Character selection

Carousel or side-by-side portrait cards, each with silhouette, basic attacks animation preview, class resource, trade-offs, unlockables, difficulty description and button to start. Do not bury class identity in a long encyclopedia.

### In-run HUD

Top: hero portrait, HP, resource, floor, active curses/mutators and pause.  
Center: full-size clean battlefield.  
Bottom/sides: joystick, attack, dodge, skill, special and interact controls with safe-area margins.  
Situational overlays: small floating loot selection, loot inspect, room map, merchant, event dialogue.  
Information hierarchy prioritizes dangerous projectiles over pretty menus.

### End-of-run screen

Hero illustration with context-specific pose; final chapter/floor; cause of death or clear; elapsed active playtime; damage dealt, enemies defeated, biggest hit, perfect dodges, best combo, favorite relic, build summary, Seeds earned, discoveries/unlocks and `Back to Garden` / `New Run`.

### Settings

Audio sliders, music toggle, SFX toggle, virtual joystick behavior, sensitivity, auto-aim cone/strength, control position calibration, left-handed toggle, 30/60 FPS preference, battery saver, screen shake, graphics effects, text size, high contrast, color-safe cues, vibration, language. All stored locally.

---

## 16. Sound and haptics

- Hub: soft music, garden birds, quiet wind chimes and charming footstep effects.
- Dungeons: theme-specific loopable music, subtle danger layering and boss stingers; avoid exhausting constant loudness.
- Every class should have a recognizable sonic identity: Angela shield clang, Vivianne soft bell/ink swish, Nixia quick impacts, Virelia bow twang, Zaria paint slice.
- All damaging attacks need a consistent readable audio cue without relying on audio alone.
- Small haptics for perfect guard, rare loot, critical strike, boss defeat, never compulsory.
- Sound asset licenses must be documented and packaged for offline playback. Do not use streaming audio.

---

## 17. Asset production and concept-art pipeline

### Required pre-production concept sheets

1. **Style board:** one sheet of 2–3 potential stylizations (clean drawn chibi, softer pixel-inspired chibi, storybook vector), each showing the same Angela sprite + mushroom + room corner at approximate in-game scale. Establish a single final consistent style before bulk asset production.
2. **Hero lineup:** all five, front/three-quarter/back silhouette, canonical hair and eye references, game equipment overlays, name and class, color swatches, neutral background.
3. **Expression / animation sheet:** idle, annoyed, hurt, smug, spellcast, sprint, death, victory for each.
4. **Enemy shape sheet:** enemy silhouettes grouped by chaser, shooter, bomber, controller, elite; 6–10 examples and telegraph states.
5. **Biome mood board:** one 2D room sample per major biome, with actual-sized hero/enemy scale, hazard and door visual language.
6. **Boss lineup:** boss silhouette, first/second phase, attack telegraph decals and projectile language.
7. **Loot / skill effects:** common/rare item cards, evolution glow, curse icons, status effects and particle style.
8. **Portrait mobile UI:** real 9:19.5-ish screenshot mock showing the actual game field with controls and no occlusion.
9. **Hub screen:** five chibis around the Garden, portals/entrance, menu touchpoints.
10. **Animation sample:** one enemy, one hero and one boss attack tested in Godot at device-scale before mass production.

### Consistency constraints

- Keep a single master character reference per heroine.
- Document exact canonical hairstyle silhouette, color palette, facial anchors, outfit and accessory before final art export.
- Only licensed/self-made/AI-generated-for-project assets that can be legally distributed.
- Transparent PNG / WebP art with standardized pivot, transparent margins, declared pixels-per-unit and sprite atlas organization.
- Asset names follow `hero_angela_idle_s_00.png`, `enemy_knife_shroom_attack_e_03.png`, `biome_forgotten_floor_01.png` conventions.
- Environment layers: floor, low decor, collisions, props, entities, tall foreground, FX, UI.
- No raster screenshot of an entire game UI as a replacement for real buttons and game state.

### Suggested first art review question

**Does the game feel more like (A) crisp storybook flat-color chibi, (B) tiny bold-outline pixel-inspired chibi, or (C) loose sketchbook chibi?** Current preferred direction: **A**, with comedic animation language from B and C. Confirm visually before commissioning hundreds of sprites.

---

## 18. Data-driven content architecture (Godot)

Organize content so new items, enemies and floors are data, not deeply coupled duplicated scenes.

```text
GardenBadBloom/
├── project.godot
├── README.md
├── docs/
│   ├── GAME_BIBLE.md
│   ├── ART_DIRECTION.md
│   ├── CONTENT_CATALOG.md
│   ├── TECHNICAL_ARCHITECTURE.md
│   ├── EXPORT_ANDROID.md
│   └── TEST_PLAN.md
├── scenes/
│   ├── startup/, hub/, characters/, game/, rooms/, bosses/, ui/
│   ├── props/, enemies/, pickups/, fx/
├── scripts/
│   ├── core/ (GameState, SceneFlow, EventBus)
│   ├── combat/ (Damage, Hitbox, Hurtbox, Projectile, Status, Attack)
│   ├── characters/ (HeroBase, HeroControllers, HeroAbilities)
│   ├── enemies/ (EnemyBase, EnemyBrain, EnemyStates, BossDirector)
│   ├── generation/ (RunSeed, FloorGraph, RoomAssembler, EncounterDirector)
│   ├── items/ (Inventory, Rarity, ItemEffects, SynergyResolver)
│   ├── progression/ (Unlocks, Records, Codex)
│   ├── economy/ (Petals, Merchant, Prices)
│   ├── persistence/ (SaveManager, DataMigration, RunSnapshot)
│   └── ui/ (HUD, TouchControls, MenuNavigation)
├── data/
│   ├── heroes/, weapons/, abilities/, items/, synergies/
│   ├── enemies/, bosses/, biomes/, rooms/, events/, modifiers/
│   └── localization/
├── assets/
│   ├── heroes/, enemies/, environments/, items/, ui/, audio/, effects/
├── tests/
│   ├── generator/, combat/, effects/, saves/, integration/
└── export_presets.cfg
```

### Core service boundaries

- `RunDirector`: owns run lifecycle, floor transitions, seed and defeat/clear states.
- `FloorGraphGenerator`: produces valid route graph and assigned node categories.
- `RoomAssembler`: places authored compatible chunks, collision, doors, enemy spawn anchors and hazards.
- `EncounterDirector`: picks and coordinates wave/elite/boss composition, clear conditions and pacing.
- `CombatResolver`: shared hit logic, status effects, friendly/enemy factions, iframes, defense and kill credit.
- `HeroController`: movement/dodge/attacks, class resource and equipment effects.
- `ItemEffectRegistry` + `SynergyResolver`: tagged event-driven effects and stable ordering.
- `EconomyManager`: Petals, shops and transactions.
- `ProgressionService`: Garden Seeds, permanent unlocks, codex and records.
- `SaveManager`: versioned serialized state, snapshots, recovery and migrations.
- `SettingsManager`: local player settings and accessibility choices.

### Content format example

Content may use Godot `Resource` files or validated JSON, but separate *data* from reusable effect code.

```json
{
  "id": "relic_thornmail",
  "name": "Thornmail",
  "rarity": "rare",
  "tags": ["guard", "retaliation", "physical"],
  "allowed_heroes": ["angela"],
  "description": "Perfect guards fling thorns toward nearby attackers.",
  "effect_id": "on_perfect_guard_thorn_burst",
  "parameters": {"count": 5, "damage_scale": 0.45},
  "icon": "res://assets/items/relic_thornmail.png"
}
```

For every type, define schema validation, unknown-key behavior, stable ID registry, collision rules and placeholder fallback. Avoid stringly typed physics calculations spread across scripts.

---

## 19. Procedural mathematics, scaling and seeded rules

### Encounter threat budgeting

A room receives a target `threat_budget` based on chapter depth, selected mode, discovered/active player kit power estimate and room layout. Enemies have authored `threat_cost` plus compatible tags. Director assembles composition within budget and spatial safety rules. Do **not** dynamically punish a strong build so harshly that upgrades feel pointless; scale with progression primarily, and use hero power only to prevent outlier trivialization in authored challenge modes.

### Endless threat design

Use a slowly increasing threat budget, additional elite types, behavior modifications and mutator slots with compatibility checking. Apply soft caps to enemy HP and damage escalation. Boss survivability can increase in meaningful bands but must include more varied patterns and avoid minute-long damage sponges. Ensure short early Endless sessions and genuinely hard late Endless.

### Random stability

Derive substream seeds from stable concatenation of run seed, stage, room node, entity group and content generation version using a deterministic hash. Maintain and save mutable RNG state where draws depend on player actions. Reopening the same chest after an interrupted save must not reroll its content.

### Reward frequency

Guarantee players regularly get choices between at least two mechanically differentiated rewards. Preserve random surprises and risk; explicitly prevent entire stretches of empty rewards. Rare events and forbidden relic drops should be genuinely exciting, but no loot rarity should be tied to payment or internet access.

---

## 20. Save/resume, reliability and offline behavior

### Persistence model

1. `profile.json`: progression, unlocks, settings, codex, cumulative records, version.
2. `active_run.json`: complete resumable run including seed, generator version, hero, HP/resource, room ID, last completed action boundary, inventory, currency, selected choices, defeated bosses, active mutators, RNG state, and enough per-room state to prevent re-entering a cleared room for free loot.
3. `run_history.json`: bounded local log with outcome, class, cause, floor, elapsed active time and core stats.
4. Backup + checksum and safe write (temp file then replace) to prevent incomplete writes from app kill/power loss.

### Save checkpoints

Autosave after room clear, choice, purchase, loot selection, floor transition, pause/background, and appropriately throttled within combat to support exact resume without severe performance overhead. An app force close must not become a reroll or free-death escape; resume from latest valid consistent snapshot, with clear recovery policy for an interrupted attack.

### Android / privacy requirements

- Build runs entirely with packaged assets. No runtime requests or dependency on Google Play Services.
- Android manifest should not request `INTERNET` unless a proven export dependency makes it impossible (document and remove if unnecessary).
- No account, analytics, cloud save, multiplayer, ads, telemetry or remote configuration.
- All essential content shipped in APK or bundled local asset pack available immediately after install.
- Handle device rotation according to portrait policy, back button, pause/resume, calls, low-memory process death, safe area and audio focus.
- Respect battery, storage and rendering settings.

---

## 21. Performance / technical targets

- Aim for smooth **60 FPS** on Xiaomi 14T Pro; optional 30 FPS battery-friendly cap.
- Optimize for actual in-combat density rather than empty test rooms. Use projectile pooling, reasonable particle budgets, batched sprites/atlases and spatial culling.
- Avoid creating/freeing large scenes every frame, excessive `get_nodes_in_group` scans in hot loops and recursive item-proc explosions.
- Bound active enemy count for fairness; spawn waves and threat patterns rather than thousands of indistinguishable sprites.
- Test touch interaction at native phone aspect ratios and common 16:9/20:9 sizes, including Android system bars.
- Save must not cause noticeable combat freezes.
- Images, fonts and audio should be bundled, compressed and licensed; avoid huge source PNG sets copied indiscriminately into the final APK.
- Prevent runaway item effects with recursion limits, per-hit/event cooldowns and explicit proc triggers.
- Performance overlays for development only: frame time, object counts, AI step cost, generator seed, active status triggers.

---

## 22. Game-feel and content quality bars

### Movement

Snappy acceleration/deceleration, visible footfall bounce, wall slide, readable invulnerability, no slippery movement unless in a clearly marked icy room. Attack-while-moving behavior is class-specific but consistent.

### Combat feedback

Impact sounds, brief hit freeze on heavy attacks, tiny enemy knockback, critical markers and controlled screen shake. All togglable or toned down for accessibility.

### Loot drama

Rarity beams, charming item cards, hero-specific reaction to cursed loot, preview before binding choices, no five-screen ceremony for every common item.

### Comedy

Short, character-specific voice bubbles and absurd descriptions; a joke cannot interrupt player control mid-attack unless it's part of a clearly telegraphed encounter.

### Balance

Baseline hero runs must be beatable through skilled play without permanent grinding. An extreme synergy should feel wild but not break game state; guard against infinite loops and softlocks.

---

## 23. Acceptance scenarios — must actually work

1. Install and first launch in airplane mode; navigate menus, select hero, descend, fight, pause and quit with no connection.
2. Select each of five heroes; verify each has unique resource, starting weapon, active skill, ultimate, attack/dodge behavior and visible identity.
3. Generate 1000+ floor/room graphs across fixed test seeds; every boss reachable and no critical map disconnected; record failing seed if any.
4. Walk into all room types, buy an item, decline an event, activate a curse, collect a relic, open a chest, complete a challenge, choose alternate route.
5. Combat test: collision, damage, armor, i-frames, status, enemy state transitions, boss phases, safe spawn, knockback and kill credit.
6. Trigger at least a dozen interaction combos and all planned class-specific evolutions; verify no recursive crashes or unintended duplicate rewards.
7. Force close during a fight and during a purchase; relaunch and resume with consistent run and currency, no reroll exploit.
8. Deliberately die; death report appears, active run is gone, Garden Seeds and codex persist, next run works.
9. Defeat standard capstone; view ending, unlock Endless, continue into a valid additional floor and a boss remix.
10. Play Endless with multiple mutator combinations; confirm legal patterns, scaling and new content after expected chapter range.
11. Stress test projectile-heavy Vivianne/Zaria build and summoned-minion encounter on target Android device.
12. Verify all touch controls are usable in portrait on real hardware, including near Android gestures and camera cutouts.
13. Launch after fresh install with no cached network assets; all sprite/audio/fonts available locally.
14. Verify settings changes persist and accessibility modes actually alter visuals/controls.
15. Check no placeholder UI claims an action that doesn't work; every visible button has a behavior.
16. Confirm build output and/or transparent manual instructions for Android export, including required SDK/Java paths, export template version and keystore steps.

### Test strategy

- Unit tests / headless scripts for generator graph validity, seeded reproducibility, save migrations, item math, status interactions and loot economy.
- Integration harness for transition into and out of rooms, shops, curses, boss clear, death and resume.
- Manual UI/UX testing with actual device captures, not only editor viewport.
- Real battle smoke-test per hero and a complete-run test after each major integration wave.
- Maintain an issue ledger, fix critical regressions before growing content further, and log exact commands/results.

---

## 24. Implementation roadmap — sustained full-game delivery

**The phases below describe execution order; all remain within the required finished product.** Do not label the work finished after the first playable build. Each phase should leave the repository runnable, with work committed in coherent groups when Git is available.

### Phase A — Foundation and visual contract

Godot project, Android configuration, deterministic run ID and seed utilities, GameState/EventBus, settings, common UI theme, Garden hub shell, character canonical reference documentation, art-style decision, asset import pipeline, collision layers, test scaffolding.

### Phase B — Player feel and combat engine

Movement, camera, touch joystick, aiming, attack, dodge, iframe, damage, projectiles, hit feedback, controls customization, shared effect system, pause/suspend/resume. Get movement and feedback satisfying before multiplying effects.

### Phase C — All five fully playable heroes

Distinct kits, primary resources, skill and ultimate, class-specific animation, equipment display, attack/dodge differences, basic effects and per-hero balancing.

### Phase D — Dungeon and generator

Valid graph generator, authored chunks, biome tiles, door connectivity, room categories, encounter spawning, navigable map, hazards, reward/exit logic and deterministic save state.

### Phase E — Enemies and all major biomes

Full enemy taxonomy, biome-specific enemy rosters, distinctive hazards/room visuals, AI state machines and elite rules. Content created as data plus reusable scripts.

### Phase F — Loot and buildcraft

Weapon/item catalog, rarity, shops, currencies, curse system, item effects, synergies, evolved equipment, event choices, pickups, visual feedback and build inspection.

### Phase G — Bosses, narrative and core clear

Every planned major biome boss, phased patterns, Bloomheart ending, unlockable Endless, secret encounter logic, codex and discovery records.

### Phase H — Endless, alternate aspects and extended content

Infinite floor generation, compatibility-aware mutators, boss remixes, hidden forms, seeded challenge runs, difficulty presets, challenge achievements and detailed history.

### Phase I — Production-grade polish

Art integration, accessible UI, optional audio/haptics, graphics quality settings, local save resilience, device performance optimization, crash recovery, no-Internet manifest, Android export.

### Phase J — Verification and release readiness

Run full acceptance test matrix, verify offline mode, on-device input, quality of all five classes, actual full clear and Endless progression, save recovery, no fake buttons, and produce installation instructions and verified binaries when the environment supports them.

**Agent execution mandate:** Continue implementing rather than returning a concept-only response. Generate real source files and scenes. Write and run tests. On hitting a wall, isolate the blocker and continue other independent work. Report completed functionality truthfully and identify what remains. Never summarize unreached phases as already implemented or claim an APK exists when it has not been built.

---

## 25. Art direction decisions still open for owner review

These are **creative decisions**, not blockers to scaffolding or gameplay infrastructure. Avoid inventing a locked answer and mass-producing incompatible assets:

1. **Stylistic finish:** primary recommendation is crisp, flat-color storybook chibi with bold lines; alternatives are deliberately pixel-inspired or sketchbook chibi.
2. **Overall mood:** bright cozy Garden hub and darkly charming but high-readability dungeons; ratio of comedy to ominous atmosphere can be tuned.
3. **HUD framing:** portrait-primary recommendation, with adjustable controls; evaluate at actual-device scale.
4. **Original character-specific outfits:** retain canon hair/eyes/outfit anchors; show battle overlays rather than redesign each from scratch.
5. **Asset generation:** use consistent master reference sheets for all hero portraits and sprite assets. Avoid image generation that drifts hair/eye identities.
6. **Final name:** `GARDEN: BAD BLOOM` is current working title.

### Immediate concept-art review sequence

Create an art-direction comparison sheet containing: all five characters' canonical 3/4 chibi views; one Knife Shroom; one Forgotten Garden room; one top-down boss telegraph; one phone HUD crop. Check that the same character is recognizable at 100%, 50% and intended gameplay scale. Use the approved sheet as source-of-truth for all future image prompts.

---

## 26. AI coding-agent operating instructions (Gemini / comparable agent)

You are the project's senior game developer, technical artist and QA engineer. The deliverable is a **complete, functional, offline Android roguelike** described by this entire document. Treat every chapter as real implementation requirements. You are expected to write Godot files, scripts, scenes, resources, sample assets, tests and packaging instructions; actually execute commands and fix errors when tools are present. Avoid stopping after a high-level plan, demo or pretty screenshot.

### Workflow contract

1. Inspect repository and tool availability. Read design bible and existing code first; protect functional work.
2. Create/update a concrete task ledger mapping chapters to files and verification checks.
3. Implement coherent vertical dependencies in sequence but keep every remaining feature on the ledger.
4. Prefer a working engine-driven implementation over fake UI mocks and hardcoded menus.
5. When final art is not yet approved, use consistent **temporary modular graphics** that preserve silhouette and color anchors, so gameplay integration can proceed. Never represent these as final art.
6. Run available headless syntax checks, test suite and scene loading where practical; fix errors before expanding.
7. Save and resume correctly; prevent offline-only contract regressions.
8. Keep unimplemented requirements explicit; don't silently drop a complex system because of token or time constraints.
9. Do not burn effort on marketing pages or unrelated infrastructure.
10. Continue milestone-to-milestone whenever execution is possible; if a session must end, leave accurate state, next commands and blockers. Do not falsely promise an autonomous infinite-running process.

### Prohibited shortcuts

- No server, web API, cloud synchronization, paid SDK or network-based generation at runtime.
- No text-only adventure masquerading as the walkable roguelike.
- No motionless UI-only showcase with characters that cannot fight.
- No single giant procedurally colored rectangle pretending to be authored biome variety.
- No placeholder button that does nothing while the UI calls it complete.
- No one-character prototype presented as the five-hero game.
- No endless mode implemented as a score counter without actual playable floors.
- No permanent upgrades so large that meaningful combat skill becomes irrelevant.
- No claim of polished production art before the owner has approved reference sheets.
- No fake tests, fake build verification, or invented APK path.

### Definition of done

A fresh Android install works with internet disabled; every Garden heroine is individually playable with meaningful abilities; multiple themed dungeons and enemy families generate valid walkable rooms; shops, events, loot, curses and evolved builds work; bosses and an actual campaign clear exist; Endless produces fair new floors and modifiers; death is irreversible for the run; progression/save recovery work; touch controls and performance are viable on a phone; visual/audio assets are consistently bundled; tests and build instructions are accurate. Completion must be demonstrated, not asserted.

---

---

# THE GRAND CONTENT EXPANSION — ENFORCED CATALOGUES

The core chapters above define the play experience. The following encyclopedias are **binding production content**, not optional brainstorming. Build their systems and implement the entries as genuine content using shared components and data records. If entries need playtest revisions, rebalance or redesign with the same strategic distinctiveness rather than deleting them. Every catalog also establishes a **minimum variety floor, never a maximum**. After integrating these entries, generate additional coherent variants, items, encounters and combinations with testable behaviors and authored art. The content director must continually seek interesting new mechanics, not recolored duplicates.

Every named entry below requires a permanent ID, gameplay data, icon/sprite, tooltip/codex text, appropriate sound/VFX, balance tests and inclusion in valid drop/spawn pools. Use the prose as the implementation contract; tune numerical parameters through data instead of hardcoding.

## 27. Detailed combat specification, formulas and fairness

### Tick order, collisions and authority

At each physics tick: collect intentions → advance state machines → move actors against walls → resolve attack active windows → identify unique target hits → resolve shields/parries/iframes → apply damage and statuses → emit deterministic events → resolve on-hit/on-kill procs with guards → update encounter clear condition → enqueue rewards/doors. Apply a deterministic stable ID ordering for simultaneous hit resolution. All proc events carry root action ID, generation depth and list of already affected effect IDs. Limit recursive proc depth and apply per-root trigger budgets. Unrelated visual particles never authoritatively determine damage.

**Baseline conceptual damage formula:** `raw = (attack_power × skill_coefficient + flat_bonus) × tagged_modifiers × critical_multiplier`; `after_defense = raw × (100 / (100 + max(-50, effective_armor)))`; `after_resistance = after_defense × (1 - clamp(element_resistance, -0.50, 0.75))`; `final = max(min_chip, round(after_resistance))`, subject to i-frames, guard and invulnerable phase rules. Bosses have explicit caps on percentage-health damage, stunlock, execute, reflection and percentage-based leech. Do not apply a modifier to both damage and healing by accident; document all stat stacking.

**Starting tuning targets, adjustable:** walking speed 125–175 logical pixels/sec, dodge distance 70–110, dodge duration 0.18–0.32 sec, dodge recovery 0.8–1.8 sec; normal telegraph 0.5–1.1 sec, unusually fast threats 0.35 sec only with unmistakable audiovisual cue and predictable line; post-hit mercy i-frames 0.3–0.6 sec; enemy attacks staggered by encounter director so unavoidable simultaneous volleys cannot overwhelm the play area. Boss phase changes offer a short safe recovery window.

### Status catalog

| Status | Gameplay behavior | Counterplay and stacking |
|---|---|---|
| Burn | Damage over time; ignites flammable gas and oil | Timed ticks, capped intensity; extinguish in frost/water field |
| Chill | Gradual movement slowdown before short freeze | Freeze resistance grows after repeated freeze to prevent chain lock |
| Poison | Damage over time plus weak healing suppression | Antidote, cleanse tile, or waiting outside clouds |
| Bleed | Damage pulses on rapid movement/attacks | Stop briefly or cleanse; never force unavoidable self-damage |
| Thornbound | Small root/snare after marked delay | Dodge out of root circle before bloom |
| Marked | Next precision attack deals bonus; specific Virelia interactions | Mark visible; expires after window |
| Exposed | Defense reduced after failed heavy attack | Visually indicated recovery window |
| Brittle | Next heavy physical hit shatters armor | Limited per-target cooldown and boss cap |
| Conductive | Arc jumps between nearby affected actors | Spread telegraphed; friendly targets exempt unless curse explicitly states |
| Hex | One temporary rule change (e.g. reduced dodge distance) | Distinct hex symbol and known duration |
| Drowsy | Slower winding up and weaker target tracking | Can be broken by direct heavy hit |
| Panic | AI flees and may collide with traps | Boss receives staggered disruption rather than control loss |
| Charm | Enemy briefly attacks decoy or its former allies | Control immune targets instead receive brief hesitation |
| Sunder | Breaks shield segments with repeated hits | Shield meter exposed to player |
| Silence | Blocks casting enemies' specials | Never suppress a player's only defensive action without warning |
| Time Slip | Projectile/animation time rate altered inside a field | Physics uses stable projectiles; avoid variable timestep bugs |
| Volatile | Explodes at zero stacks/timer | Obvious fuse and radius |
| Resonance | Nearby same-tag effects amplify one another | Cap chain length; UI explains active synergy |
| Corruption | Builds risk; at threshold grants curse or enemy mutation | Gauge visible; cleanse or embrace via choice |
| Guardbreak | Staggers defender after a readable heavy strike | Limited duration and predictable recovery |

### Room entry and pacing rules

Spawn heroes in a safe zone with two plausible exit directions. Initial room has a non-combat second to orient. Camera frames threat sources and exits. Enemy composition respects role quotas, ranged pressure quota, ground-hazard coverage limit, projectile density ceiling and hero-specific accessibility constraints. The game is allowed to be very hard but **never deceptive**. The player can lose due to strategy, timing, build greed or mistakes—not unavoidable hidden dice-roll lethality.

### Readability priority when screen crowded

Priority 1: hostile telegraph and player silhouette; 2: projectiles and safe ground; 3: key pickups and interactive objects; 4: damage numbers and decorative particles. Reduce nonessential VFX automatically in dense scenes. Never equate more enemies with better challenge when screen becomes unreadable.

## 28. Hero talent encyclopaedia — 120 authored talents

Each hero unlocks talents through Garden progression and run decisions. Talents are selectable choices, **not all equipped at once**; limit active talent slots and enforce incompatible branch rules. Build skill trees with distinct Guard/Spell/Combo/Precision/Chaos branches and three tiers each. Every talent is tied to stable effect logic, icon, rarity weight and on-screen disclosure. Add more talents after these 120 using the same class-specific design language.

### Angela — Counterguard

| Talent | Mechanical implementation |
|---|---|
| 01. **Lily Edge** | Sword third hit releases a short piercing petal wave. |
| 02. **Warmsteel** | Perfect guard briefly warms blade; next attack applies Burn. |
| 03. **Stone Stance** | Standing ground for a moment fortifies frontal guard. |
| 04. **Rosewall** | Guard projects a tiny deployable wall on perfect timing. |
| 05. **Last Word** | Counterattack interrupts eligible enemy windups. |
| 06. **Retribution Chain** | Defeated counter target sends damage to adjacent marked foes. |
| 07. **Fortress Step** | Dodge leaves a short defensive shield for following allies or echoes. |
| 08. **Quiet Resolve** | Resolve drains slower when no enemy in range. |
| 09. **Thorn Receipt** | Blocking a projectile returns a weakened thorn missile. |
| 10. **Defiant Spark** | Low HP strengthens next guard only, with cooldown. |
| 11. **Guard Composer** | Alternating dodge and guard lowers both recoveries slightly. |
| 12. **Ceremonial Blade** | Clean combos generate a petal that improves next critical strike. |
| 13. **Crown Weight** | Heavy sword strikes stagger armored targets more effectively. |
| 14. **Wedding Vow** | One lethal strike per floor is survived at 1 HP if ring synergy active. |
| 15. **Prideful Tempo** | Perfect guard grants one faster combo finisher. |
| 16. **Shield Lotus** | Resolves a burst of thorns after three distinct successful blocks. |
| 17. **Royal Riposte** | Parry arc can hit multiple foes in ordered cone. |
| 18. **Heavy Petals** | Guard-derived petals persist as orbiting interceptors briefly. |
| 19. **Oath of Ash** | Voluntarily spend HP to add fire edge to next skill. |
| 20. **Knight Errant** | Special room rescue events reward temporary Resolve cap. |
| 21. **Blue Bastion** | Ultimate plants a protective lily circle, with clear duration. |
| 22. **No More Running** | Against bosses, clean guard builds stagger meter. |
| 23. **Sunlit Steel** | Entering a new biome changes counter VFX and bonus damage type. |
| 24. **Final Bouquet** | Once per boss, perfect guard during final phase unlocks special finish. |

### Vivianne — Roseweaver

| Talent | Mechanical implementation |
|---|---|
| 01. **Inkblot** | Basic thorns splash small residue patches. |
| 02. **Couplet** | Every second non-identical spell repeats a weaker echo. |
| 03. **Black Rose** | Spell residue becomes brief thorn patches. |
| 04. **Drowsy Waltz** | Spells applying Drowsy increase Ink regeneration. |
| 05. **Moon Margin** | Perfect dodge paints a delayed crescent blast. |
| 06. **Quiet Quill** | Standing still charges next spell, canceled safely by dodge. |
| 07. **Petal Sentence** | Marked enemy death extends nearby residue. |
| 08. **Obsidian Page** | Casting different elements in sequence increases effect range. |
| 09. **Rose Clock** | Spell timings align to a rotating rhythm bonus indicator. |
| 10. **Elegy Shards** | Ultimate spawns fewer, stronger aimed shards. |
| 11. **Crimson Footnote** | Low-health enemies leave readable blood-rose glyphs on defeat. |
| 12. **Ink Familiar** | Summon one raven-shaped quill companion. |
| 13. **Rhyme Break** | Interrupt casting to bank partial Ink and reposition. |
| 14. **Sigh of Winter** | Frost spells slow burning enemies instead of extinguishing them. |
| 15. **Grave Typography** | Hexed enemies take increased residue damage. |
| 16. **Paper Halo** | Quill companion intercepts one projectile, then recharges. |
| 17. **Spell Garden** | Three different residue types bloom into one mixed field. |
| 18. **Last Stanza** | Elite kills store one stanza for next boss room. |
| 19. **Long Verse** | Repeated stationary casting extends range but reduces mobility. |
| 20. **Refrain** | A spell can echo at previous cursor position. |
| 21. **Midnight Veil** | Drift dodge conceals target briefly without granting permanent immunity. |
| 22. **Thorn Grammar** | Projectiles split on wall collision with constrained count. |
| 23. **Broken Sonnet** | Curses trade max HP for extra spell slot. |
| 24. **Blackout Poetry** | Once per boss, consume all Ink for a huge stagger-safe nova. |

### Nixia — Brawler

| Talent | Mechanical implementation |
|---|---|
| 01. **Tiny Terror** | Punches against taller targets build bonus Momentum. |
| 02. **Combo Firewall** | Every tenth clean hit emits a shield-breaking glitch. |
| 03. **Uppercut Express** | Launch hit enemy into another to deal collision damage. |
| 04. **Short Fuse** | Low Momentum grants faster catch-up movement. |
| 05. **Smug Protocol** | No-hit room clears bank one temporary combo charge. |
| 06. **Pocket Meteor** | A charged leap lands with a circular stagger shock. |
| 07. **Firewall Punch** | Consume Momentum to reflect one close projectile. |
| 08. **Purple Afterimage** | Perfect dash leaves a decoy that disappears on hit. |
| 09. **Rapid Refund** | Finisher kill partially refunds dash recovery. |
| 10. **Rage Window** | Damage taken starts a short, visible revenge-combo window. |
| 11. **Big Gloves** | Heavy gauntlets slow movement but add wider arcs. |
| 12. **Headbutt Hero** | Dash into wall creates a small cone stun; short self-recovery. |
| 13. **Orchid Barrage** | Repeated light strikes evolve into a controlled rapid flurry. |
| 14. **Packet Loss** | Marked enemy occasionally whiffs a single melee strike. |
| 15. **Overflow** | At max Momentum, next punch can pierce one foe. |
| 16. **Doom Stomp** | After air-launch, stomping causes an area knockback. |
| 17. **Counter Gremlin** | Just-dodged hits prime an instant counter jab. |
| 18. **Momentum Bank** | Unused Momentum carries across noncombat rooms up to cap. |
| 19. **Smackdown Chain** | Finisher can chain to a nearby staggered target. |
| 20. **Tiny Crown** | Elite stagger briefly grants stagger-resistant gloves. |
| 21. **Glitch Ribbon** | Moving between successive targets creates damaging line. |
| 22. **Denied** | Close-range cancel parries one special attack with loud cue. |
| 23. **Cosmic Suplex** | Ultimate picks one non-boss to throw into others; bosses get grounded burst. |
| 24. **Root Access** | High-skill combo sequence applies unique breach vulnerability. |

### Virelia — Camellia Warden

| Talent | Mechanical implementation |
|---|---|
| 01. **Ribbon Point** | First arrow after dodging gains guaranteed weak-spot alignment assist. |
| 02. **Neat Quiver** | Unused Focus grants temporary arrow capacity. |
| 03. **Petal Radar** | Traps reveal hidden enemies and mimic chests. |
| 04. **Perfect Line** | Arrows piercing one target gain a narrow second-target opportunity. |
| 05. **Snare Bloom** | Traps grow a second delayed snare ring. |
| 06. **Careful Hands** | Placing a trap does not interrupt short movement. |
| 07. **Camellia Rain** | Critical arrows shed small harmless guiding petals before damage. |
| 08. **Marked Lesson** | Attacking a marked target grants modest Focus. |
| 09. **Sewing Thread** | Two traps can be linked into a tripwire. |
| 10. **Polite Warning** | First missed arrow in a room leaves a decoy marker. |
| 11. **Order Restored** | Clearing enemies while all traps intact grants extra Petals. |
| 12. **Sharpsong** | Charged shots emit a musical beat aiding timing. |
| 13. **Safety Pin** | Dodge lays one reusable caltrop with cooldown. |
| 14. **Gardener Eye** | Display weak points on elite armor when target observed. |
| 15. **Crosswind** | Sideways movement bends the next projectile curve. |
| 16. **Threefold Bow** | Every third precise hit spawns two small side arrows. |
| 17. **White Camellia** | Cleanse own poison upon perfect precision streak, limited cooldown. |
| 18. **Rose Trellis** | Traps on wall edges grow a protective baffle. |
| 19. **Quiet Step** | Enemies detect Virelia later in specific stealth rooms. |
| 20. **Petal Accountant** | Choosing cheaper shop gear adds one extra quiver token. |
| 21. **Focus Reserve** | Spend Focus to slow aim reticle locally, not entire game. |
| 22. **Tidy Burst** | Trap detonations can stagger clustered weak foes. |
| 23. **Warden Form** | Ultimate arrows prioritize marked targets without auto-winning. |
| 24. **Final Arrangement** | Hit three separate weak points to unlock a precision finisher. |

### Zaria — Iris Rogue

| Talent | Mechanical implementation |
|---|---|
| 01. **Ink Footsteps** | Dodge leaves slippery paint that slows pursuers. |
| 02. **Heterochrome** | Alternating left/right dagger hits charges a color shift. |
| 03. **Graffiti Crit** | Critical kills leave a marked wall sigil. |
| 04. **Dirty Palette** | Poison and Burn on same foe produce a one-time flash reaction. |
| 05. **Shadow Sketch** | Dash paints a temporary shadow decoy. |
| 06. **Color Theory** | Three distinct status colors create a unique weakness. |
| 07. **Unfinished Work** | Missed finisher leaves blade ink that can be reclaimed. |
| 08. **Neon Cut** | Backstab creates short line projectile. |
| 09. **Pocket Bomb** | Trap item can be attached to enemy by close dodge. |
| 10. **Gallery Opening** | Room entry marks one random elite weakness visibly. |
| 11. **Iris Exchange** | Switch dagger stance between fast/precise modes. |
| 12. **Vandal Stamp** | Damaging environmental prop buffs next dagger throw. |
| 13. **Side Street** | Wall slide improves dodge angle change. |
| 14. **Blue Mirage** | Low HP grants one evasive afterimage with cooldown. |
| 15. **Red Smear** | Bleeding enemies leave risk/reward tracking trails. |
| 16. **Palette Knife** | Daggers can harvest one paint charge from hazards. |
| 17. **Crit Canvas** | Successive crits paint a floor rune, limited once per room. |
| 18. **Broken Frame** | Destroy enemy shield at cost of extra recovery. |
| 19. **Encore Heist** | Steal one consumable charge from treasure guardian (not merchant). |
| 20. **Jitter Step** | A timed attack cancel creates one extra mobility burst. |
| 21. **Chaos Signature** | Random color triggers visible effect selected from disclosed pool. |
| 22. **Night Exhibition** | Ultimate paints a path of delayed slash rectangles. |
| 23. **Stolen Spotlight** | Killing elite briefly shifts nearest enemies to chase a decoy. |
| 24. **Masterpiece** | Complete three-color combo to perform a capped finisher. |

## 29. Enemy bestiary — 154 biome species + 14 Endless oddities

**Implementation key:** `Role` tells the AI package; `Telegraph and attack` is both animation direction and hitbox contract; `Counterplay` must be testable; `Drop motif` informs loot tables, particle colors and codex. All require compact chibi top-down sprites, hurtbox, AI, defeat animation, elite compatibility and biome-specific audio. Designers must invent additional behavioral variants rather than treating this roster as a ceiling.

**Population rules:** starter floors select 2–4 complementary enemy types, then increase tactical composition; limit simultaneous chargers and projectiles. Rare species require a noticeable first appearance and codex discovery. Some species can migrate into other biomes through mutation events with matching floor art cues. A player can learn the enemy by sight and get better at countering it.

### Forgotten Garden — 22 enemy species

| ID | Species | Role | Telegraph → attack | Counterplay | Drop motif |
|---|---|---|---|---|---|
| 01 | **Grumble Tulip** | chaser | Shakes petals, then lunges in a short straight line | Sidestep and strike while uprooted | petal |
| 02 | **Thorn Slug** | controller | Leaves thorn slime then curls into a defensive shell | Circle behind; cleanse path with fire | thorn |
| 03 | **Carrot Screamer** | support | Swells cheeks, releasing a directional sonic blast | Use obstacles; interrupt its inhale | root |
| 04 | **Hedge Knight** | shielded | Points twig lance before a guarded charge | Bait charge into wall and counter its rear | bark |
| 05 | **Pea-Shooter Bud** | shooter | Opens pod before firing three slow peas | Weave gaps; close during reload | seed |
| 06 | **Dandelion Drifter** | flanker | Floats to side and drops one spinning seed ring | Dash beneath while seed ring expands | fluff |
| 07 | **Snapping Lily** | ambusher | Closes petals around floor shadow, then bites | Leave shadow; punish stuck bite | nectar |
| 08 | **Hoe Golem** | bruiser | Raises rusted hoe for a wide two-beat cleave | Move behind on windup; avoid follow-through | iron scrap |
| 09 | **Beetle Gardener** | support | Shovels soil mound to empower nearby sprouts | Break soil mound before buff completes | soil |
| 10 | **Pollen Jester** | controller | Juggles three visible pollen bombs with alternating fuses | Track fuse colors; step through opened lane | powder |
| 11 | **Root Tunneler** | ambusher | Burrow trail shows under tiles until erupting | Follow tremor and leave emergence circle | root |
| 12 | **Watering-Can Wisp** | shooter | Tilts spout to spray arc that grows slippery vines | Stay outside fan then cross behind | dew |
| 13 | **Rosebud Bully** | chaser | Puffs cheeks and shoulder-bashes nearby foes | Lure into thorns; dodge lateral shove | rosebud |
| 14 | **Sundial Snail** | controller | Spins shell shadow that slows enemies and player | Move toward shade break in ring | shell |
| 15 | **Scarecrow Chick** | flanker | Pretends inert until near, then pecks in zigzag | Spot twitching hat; punish after third hop | straw |
| 16 | **Pruning Shears** | animated | Clacks blades twice before sweeping scissor slice | Backstep at second clack; attack hinge | metal |
| 17 | **Ivy Piper** | support | Plays vine flute and calls two timed creeping vines | Interrupt flute; vines expire with player choice | ivy |
| 18 | **Flowerpot Mimic** | mimic | Pot vibrates and soil eyes open before ambush | Inspect off-center shadow and use ranged poke | ceramic |
| 19 | **Sunburnt Petunia** | shooter | Charges tiny sunbeam and rotates narrow cone | Follow rotation, do not sprint across beam | pollen |
| 20 | **Humming Hedgehog** | bruiser | Rolling hedge ball leaves curved thorn track | Bait it into solid cover | thorn |
| 21 | **Grandma Compost** | summoner | Stirs compost cauldron and raises two seedlings | Destroy cauldron to end summons | compost |
| 22 | **Petal Scyther** | elite hunter | Lifts a petal blade above marked lane then returns | Dodge first lane and counter return arc | rare petal |

### Mushroom Kingdom — 22 enemy species

| ID | Species | Role | Telegraph → attack | Counterplay | Drop motif |
|---|---|---|---|---|---|
| 01 | **Knife Shroom** | chaser | Lifts comically large knife before a committed dash | Sidestep and hit while dizzy | spore |
| 02 | **Puffball Bomber** | bomber | Flashes orange cap then expands fuse circle | Leave marked blast or detonate near enemies | puff |
| 03 | **Spore Butler** | support | Opens umbrella to shield two nearby fungi | Break umbrella from side; then strike links | silk |
| 04 | **Mycelium Leaper** | flanker | Squats then leaps over a predictable marked arc | Move toward takeoff point and punish landing | mycelium |
| 05 | **Cap Lantern** | shooter | Turns bioluminescent blue then fires ricochet glow | Bounce around stone pillar; avoid second angle | glow |
| 06 | **Fungal Surgeon** | support | Raises surgical needle and heals one marked ally | Interrupt needle or isolate healer | needle |
| 07 | **Rotcap Hound** | chaser | Sniffs then sprints toward recent player position | Change direction at bark cue | moss |
| 08 | **Stink Spitter** | shooter | Gurgles before arcing poison glob to floor | Read landing shadow and abandon puddle | venom |
| 09 | **Truffle Thief** | flanker | Scuttles toward dropped loot then charges with stolen aura | Intercept path; defeat to recover stolen reward | truffle |
| 10 | **Mossball Roller** | bruiser | Inflates cap then bounces off walls twice | Stand at wall gap and punish exhausted bounce | moss |
| 11 | **Glowgill Jelly** | controller | Pulses luminous rings from rooted center | Step between expanding rings | gill |
| 12 | **Cordyceps Puppet** | summoner | Spreads tendrils to temporarily animate corpse | Burn body or interrupt tendril cast | cord |
| 13 | **Shroom Knight** | shielded | Blocks forward with cap shield then stabs | Strafe behind its cap and stagger | cap |
| 14 | **Spore Bell** | controller | Chimes and produces expanding Drowsy crescent | Follow bell rhythm; hit after echo | bell |
| 15 | **Yeast Baker** | bomber | Throws rising dough bombs that swell before burst | Attack underbaked bombs to redirect | yeast |
| 16 | **Mushroom Twins** | duo | Two connected caps coordinate alternating cross-attacks | Separate with trap; stop link briefly | twin spores |
| 17 | **Blue Mold Monk** | bruiser | Meditates, then retaliates with deliberate spinning kick | Wait out retaliation; break meditation circle | ink mold |
| 18 | **Lurking Morel** | ambusher | Camouflages as wall fungus; eyes light before spear shot | Notice moving gills; bait shot into rock | morel |
| 19 | **Parasite Orchid** | controller | Attaches visible spore leech to player after warning | Roll through cleansing mist, or kill host | orchid |
| 20 | **Razor Chanterelle** | shooter | Launches five knife-like spores in fan | Stand between spokes; approach during recharge | razor spore |
| 21 | **Royal Taste Tester** | support | Tests a mushroom then buffs boss minions briefly | Interrupt tasting; bait tester into poison | royal spore |
| 22 | **Amanita Executioner** | elite hunter | Plants two knife marks then commits to X-shaped rush | Move to a safe quadrant before second mark | crowned spore |

### Clockwork Conservatory — 22 enemy species

| ID | Species | Role | Telegraph → attack | Counterplay | Drop motif |
|---|---|---|---|---|---|
| 01 | **Tin Bee** | flanker | Whirs faster, then makes one straight needle dash | Change lane after rising whine | gear |
| 02 | **Pendulum Mouse** | chaser | Tail swings in beat then slashes in metronome rhythm | Attack during predictable swing recovery | spring |
| 03 | **Clockwork Rose** | shooter | Petals light clockwise before burst | Follow clock-gap around blossom | rose gear |
| 04 | **Brass Butler** | shielded | Polishes tray then launches tray discus | Use pillar to reflect discus back | brass |
| 05 | **Tick-Tock Toad** | bomber | Counts three tongue ticks before a clock bomb | Dodge at third tick; chase slow toad | spring |
| 06 | **Gearling** | swarm | Tiny gears roll in lane and combine into larger gear | Separate and destroy before merge | cog |
| 07 | **Glass Mantis** | bruiser | Raises transparent scythe with obvious glint | Read glint and break fragile rear legs | glass |
| 08 | **Alarm Robin** | support | Rings bell and accelerates nearby constructs | Hit bell attachment to cancel buff | bell |
| 09 | **Conveyor Crab** | controller | Pushes short conveyor strip across floor | Step sideways off track; punish stationary claw | belt |
| 10 | **Hourhand Archer** | shooter | Traces circular aim reticle then fires at fixed angle | Rotate around hand pivot as it locks | arrowhead |
| 11 | **Brass Grasshopper** | flanker | Springs into three predictable numbered jump spots | Hold position until third marker resolves | spring |
| 12 | **Rust Knight** | shielded | Armor plates click in sequence before heavy shoulder attack | Hit loose plate after third click | rust |
| 13 | **Windup Widow** | controller | Spins web wires into visible triangle | Cut anchor or move through opening | wire |
| 14 | **Timekeeper Snail** | support | Slowly rewinds one ally HP after winding animation | Interrupt rewind with guardbreak | time dust |
| 15 | **Steam Salamander** | shooter | Hisses before venting cone of hot steam | Circle toward unvented side | steam |
| 16 | **Chime Collector** | ambusher | Appears at ringing chime and snaps shut metal cage | Listen for location, dodge marked cage | chime |
| 17 | **Cog Chef** | bomber | Throws frying pan bombs that slide on metal floor | Kick pan into enemy with timing | pan |
| 18 | **Mirror Vane** | controller | Turns mirror and redirects one projectile type | Attack mirror back, then use reflected beam | mirror |
| 19 | **Springhare** | chaser | Compressed spring trembles before long-axis leap | Step orthogonally; punish recoil | spring |
| 20 | **Minute Reaper** | elite hunter | Sweeps hand-shaped blade along one full clock quadrant | Watch clock-face mark; enter safe quadrant | minute hand |
| 21 | **Copper Choir** | support | Three singing heads pulse shields in rotating order | Strike unshielded singer; others stagger | voice gear |
| 22 | **Secondhand Specter** | elite hunter | Briefly duplicates previous attack at delayed marker | Remember first telegraph; avoid echo | ghost gear |

### Bloodbloom Forest — 22 enemy species

| ID | Species | Role | Telegraph → attack | Counterplay | Drop motif |
|---|---|---|---|---|---|
| 01 | **Siphon Moth** | flanker | Circles then dives and briefly drains HP on contact | Wait for red wing flare then dodge | moth dust |
| 02 | **Hemlock Doe** | bruiser | Stamps red flower path before charging | Use side lane; punish antlers in wall | antler |
| 03 | **Bloom Leech** | chaser | Stretches body for short latch attack | Break latch with one dodge or quick strike | leech |
| 04 | **Thorn Widow** | controller | Marks crisscross thorn web and waits | Cut corner anchor, move into gap | spider silk |
| 05 | **Rosegrave Crow** | shooter | Caws then fires three linear black feathers | Track crow beak; use trees | feather |
| 06 | **Sanguine Sapling** | summoner | Plants blood root that releases two small shoots | Kill root to stop additional shoots | sap |
| 07 | **Pale Bark Sentinel** | shielded | Raises bark shield before a shield-piercing overhead | Go sideways; strike exposed knot | bark |
| 08 | **Bleeding Broom** | animated | Sweeps cursed leaves into moving damage lane | Follow broom handle and sidestep swath | broom twig |
| 09 | **Poppy Lullaby** | support | Sings Drowsy tune and grows healing red poppies | Destroy poppies or interrupt hum | poppy |
| 10 | **Vine Harpooner** | shooter | Shows stretched vine line then pulls target | Cut vine or dash sideways as it fires | vine |
| 11 | **Mourning Fox** | flanker | Circles invisibly through visible fallen leaves | Track leaf swirl; break ambush with light attack | fur |
| 12 | **Bloodbeetle** | bomber | Fills abdomen with glowing fluid and explodes on death | Kill from range or dodge death burst | blood resin |
| 13 | **Heartwood Rook** | bruiser | Places a tall chess-rook thorn marker then charges lane | Change file; counter into flank | wood |
| 14 | **Leech Nurse** | support | Tethers to ally to transfer life from player-shaped effigy | Destroy effigy, cut tether | needle |
| 15 | **Guilt Blossom** | controller | Projects three forbidden floor petals that detonate when stood on | Read petals, wait before crossing | guilt pollen |
| 16 | **Scab Knight** | shielded | Scab armor flakes with successive hits then heals if ignored | Commit to break stage before regen | scab |
| 17 | **Candlethorn** | shooter | Burns wick then sends creeping ground flame | Cross behind wick before flame unfolds | wax thorn |
| 18 | **Orchard Weeper** | ambusher | Pretends tree stump; cries before root slam | Hear sniffle; hit exposed trunk | tear |
| 19 | **Bone Petunia** | shooter | Fires bone-seed spiral from flower jaws | Move tangentially toward clear arc | bone seed |
| 20 | **Thirsty Magnolia** | controller | Creates draining puddle with safe lily pad | Hop between pads with marked timing | magnolia |
| 21 | **Grief Hound** | chaser | Charges faster after near-miss but pauses to howl | Use howl as stun window; avoid greed | shadow fur |
| 22 | **Red Crown Stag** | elite hunter | Antlers mark five branching lanes then stampede | Pick branch gap, punish after collision | crimson crown |

### Hollow Palace — 22 enemy species

| ID | Species | Role | Telegraph → attack | Counterplay | Drop motif |
|---|---|---|---|---|---|
| 01 | **Teacup Duelist** | flanker | Throws saucer out and back on same arc | Avoid return path; strike while cup empty | saucer |
| 02 | **Wailing Curtain** | controller | Draws curtain around edges then pulses gloom | Remain in lit center and cut drawstring | silk |
| 03 | **Hollow Knight** | shielded | Displays sword stance then performs two disciplined slashes | Wait for second swing, counter open side | armor |
| 04 | **Dancing Chair** | chaser | Taps three legs then leaps chair-first | Dodge diagonal; attack wobbling leg | chair wood |
| 05 | **Haunted Teapot** | shooter | Spouts steam pellets in fan | Circle behind handle | porcelain |
| 06 | **Napkin Specter** | swarm | Folds into paper spear and glides at head height | Destroy folded point with ranged attack | linen |
| 07 | **Mirror Duchess** | controller | Projects two mirrored decoys with non-damaging shadows | Find unique reflection shadow and strike original | mirror shard |
| 08 | **Fork Butler** | bruiser | Balances silverware then jabs three-prong volley | Dodge third prong, punish clumsy reset | cutlery |
| 09 | **Clockface Portrait** | shooter | Eyes follow player before portrait fires spectral frame | Move off painted gaze line | paint |
| 10 | **Banquet Blob** | bomber | Swallows plates and expands before messy burst | Force it to spit at other enemies | jelly |
| 11 | **Chandelier Bat** | flanker | Dangles then drops marked glass shards | Move under safe chain shadow | glass |
| 12 | **Porcelain Hound** | chaser | Paws scratch tile before quick zigzag rush | Observe paw direction; counter fragile side | porcelain |
| 13 | **Velvet Undertaker** | support | Covers dying ally with cloth, reviving once | Pull shroud aside via hit before seal | velvet |
| 14 | **Royal Bookmark** | shooter | Flaps pages and throws razor paper arcs | Stand near spine side; dodge page fan | paper |
| 15 | **Mimic Armchair** | mimic | Cushion eyes blink before a grab and launch | Check pillow stitching; use distance poke | button |
| 16 | **Cursed Harpsichord** | support | Keys glow then applies tempo buff to allies | Attack wrong note key to scramble song | key |
| 17 | **Cake Executioner** | bruiser | Raises cake cleaver then makes sticky frosting puddle | Bait hit onto unimportant tile | icing |
| 18 | **Marble Page** | shielded | Raises marble book as cover, revealing weak spine | Flank book spine after charge | marble |
| 19 | **Royal Umbrella** | controller | Opens umbrella casting cone of projectile reflection | Wait for close; attack from below edge | umbrella pin |
| 20 | **Sealed Letter** | ambusher | Floats as envelope then unfolds sharp text ribbons | Observe wax seal crack and roll aside | wax |
| 21 | **Grand Piano Spider** | elite hunter | Walks eight legs across keyboard tiles with rhythmic slams | Follow highlighted notes; enter safe chord | ivory key |
| 22 | **Crownless Butler** | elite hunter | Alternates tray shield and boiling-tea lance with audible change | Change attack angle on each stance | royal porcelain |

### Astral Greenhouse — 22 enemy species

| ID | Species | Role | Telegraph → attack | Counterplay | Drop motif |
|---|---|---|---|---|---|
| 01 | **Starseed Wisp** | shooter | Orbits tiny star before firing slow homing mote | Bait mote into wall; punish orbit pause | star dust |
| 02 | **Orbiting Bloom** | controller | Rotates petals into safe wedge and moving danger spokes | Move with wedge, not against spokes | starlight |
| 03 | **Mirror Moth** | flanker | Shows clone reflection then crosses to opposite side | Strike shadow bearing real glint | mirror wing |
| 04 | **Nebula Doll** | summoner | Unwinds yarn galaxy and releases miniature comets | Interrupt unravel, clear finite comets | nebula thread |
| 05 | **Comet Tadpole** | chaser | Tail traces arc then charges along it | Exit traced curve before comet arrives | comet |
| 06 | **Void Marigold** | controller | Creates black circle that pulls projectiles inward | Keep distance; exploit predictable bullet bend | void pollen |
| 07 | **Lunar Gardener** | support | Plants moon seed which boosts nearby astral foes | Destroy seed before first pulse | moon seed |
| 08 | **Stellar Jelly** | bomber | Body twinkles in countdown before implosion | Leave inner ring; avoid delayed outer burst | jelly star |
| 09 | **Sunspot Finch** | shooter | Aims thin solar line then emits rapid tiny rays | Cross behind line pivot after aim locks | sunspot |
| 10 | **Prism Beetle** | shielded | Faces reflective prism shell and redirects beam | Approach non-reflective side marked by dull face | prism |
| 11 | **Space-Time Snail** | controller | Lays slow-time tape across floor | Stay out of tape; sprint through after pulse | time silk |
| 12 | **Constellation Crow** | flanker | Forms dotted line toward future landing spot | Break line with a new position | star feather |
| 13 | **Galaxy Mantis** | bruiser | Sweeps two blade arms along luminous orbit rings | Step into central hollow of ring | star chitin |
| 14 | **Planetary Teapot** | shooter | Spins orbiting teacups, launches one per beat | Track missing orbit segment | planet cup |
| 15 | **Luminous Orchid** | support | Transfers shield through visible light bridge | Cut bridge by crossing it with attack | glow orchid |
| 16 | **Dark Matter Rat** | chaser | Swells dark tail then warps one short tile | Read black tail arrow and counter arrival | dark pellet |
| 17 | **Event Horizon Hare** | ambusher | Leaves stable portal shadow, leaps from shown exit | Camp offset to portal exit | portal fur |
| 18 | **Starlace Spider** | controller | Stretches constellations across room corners | Break knot that powers hard lane | starlace |
| 19 | **Moonphase Knight** | shielded | Changes frontal resistance at fixed phases | Fight during pale phase or flank dark shield | moon armor |
| 20 | **Astral Scribe** | support | Writes delayed constellation attack map | Interrupt pen tip or find empty glyph | ink star |
| 21 | **Meteor Chef** | bomber | Tosses three burning pans with projected landings | Attack pan to nudge impact point | meteor pan |
| 22 | **Zenith Harbinger** | elite hunter | Marks sun and moon lane then swaps danger at second cue | Wait for swap marker; move once deliberately | zenith crown |

### Bloomheart Core — 22 enemy species

| ID | Species | Role | Telegraph → attack | Counterplay | Drop motif |
|---|---|---|---|---|---|
| 01 | **False Angela Petal** | echo | Projects defensive stance, then a short counter arc | Attack outside counter window and reposition | echo petal |
| 02 | **False Vivianne Quill** | echo | Casts delayed script on marked tiles | Exit script before letters solidify | echo ink |
| 03 | **False Nixia Glove** | echo | Builds combo tell by clacking gauntlets | Break line before third punch | echo spark |
| 04 | **False Virelia Arrow** | echo | Places visible crosshair and fires single precision beam | Use pillar or dodge on glint | echo arrow |
| 05 | **False Zaria Dagger** | echo | Leaves two painted feints; real one has shadow | Track shadow and dodge committed slash | echo pigment |
| 06 | **Wish Husk** | chaser | Charges only after a glowing wish bubble bursts | Wait for bubble pop, move orthogonal | wishglass |
| 07 | **Broken Bouquet** | controller | Releases petals that turn safe floor into thorns | Destroy bouquet knot before spread | bloomheart petal |
| 08 | **Memory Moth** | flanker | Projects previous-room attack silhouette in advance | React to silhouette, not old timing | memory dust |
| 09 | **Glitch Rose** | shooter | Fires mirrored bullets that swap after a clear chime | Wait for chime, use widened lane | glitch petal |
| 10 | **Hope Collector** | support | Steals one visible temporary buff, holds it as orb | Strike orb carrier to return buff | hope fragment |
| 11 | **Garden Doppelpot** | mimic | Mimics free healing pot but wobbles on approach | Inspect handle and test with weapon | doppel ceramic |
| 12 | **Fractured Root** | controller | Splits tile platform into temporary safe islands | Move to marked stable tiles | root shard |
| 13 | **Promise Serpent** | bruiser | Coils ring around player, leaves highlighted exit | Leave through highlighted exit before close | promise scale |
| 14 | **Archive Puppet** | summoner | Pulls one previously fought foe echo at reduced power | Cut archive string to stop additions | archive string |
| 15 | **Heart Clock** | support | Accelerates selected foe after eight audible heartbeats | Break clock before eighth beat | clock heart |
| 16 | **Unspoken Word** | shooter | Letters fly as thin projectiles in readable sentences | Use spaces between letters and break punctuation node | word shard |
| 17 | **Curse Lantern** | controller | Attaches glowing curse to a floor tile | Leave tile, destroy lantern | lantern |
| 18 | **Faded Guardian** | shielded | Cycles shields copied from earlier biomes | Recognize icon and use learned counter | guardian shard |
| 19 | **Wishbreak Beetle** | bomber | Carries orb that bursts into three shaped hazards | Back away and choose safe spoke | wish fragment |
| 20 | **Last Tea Echo** | shooter | Throws spectral teacups from a disappearing table | Move after impact marker appears | echo porcelain |
| 21 | **Almost Hero** | elite hunter | Copies one currently equipped skill with weaker readable tell | Recognize own icon, dodge and punish imitation | mirror seed |
| 22 | **Bloomheart Warden** | elite hunter | Alternates two familiar boss patterns with full transitions | Observe transition flower before each move | core shard |

### The Endless — 14 unusual composite enemy species

| ID | Species | Role | Telegraph → attack | Counterplay | Drop motif |
|---|---|---|---|---|---|
| X01 | **The Unpaid Intern** | support | Tries to copy random elite aura but drops it after visible error | Interrupt tiny paperwork animation | receipt |
| X02 | **Upside-Down Tulip** | flanker | Burrows from ceiling tile with inverted warning circle | Move out of circle and strike after faceplant | inverted seed |
| X03 | **Clockcap Shroom** | bruiser | Alternates timed knife slash and delayed gear explosion | Follow one beat and bait second into empty floor | spore gear |
| X04 | **Teapot Supernova** | bomber | Boils until patterned 8-way starburst | Find one marked safe lane before final whistle | star porcelain |
| X05 | **Rose Paladin** | shielded | Holds shield unless struck with matching status color | Adapt attack element or flank | royal rose |
| X06 | **Quantum Scarecrow** | ambusher | Two versions occupy hinted tiles; only blinking one is real | Attack blinking straw shadow | quantum straw |
| X07 | **Painted Mirror Moth** | flanker | Leaves colored copy then reverses its dash target | Wait for reversal flash | paint wing |
| X08 | **Bureaucratic Slug** | controller | Places approval stamps that slow movement until expired | Avoid stamp boxes; attack stamp holder | stamp |
| X09 | **Void Potluck** | summoner | Opens miniature banquet with limited mixed-biome adds | Destroy central picnic table | tablecloth |
| X10 | **Tiny Doom Goose** | chaser | Honk signals sharp three-step charge and brief wobble | Sidestep honk third beat | feather |
| X11 | **Extremely Normal Chair** | mimic | Sits quietly; walking shadow betrays movement | Test suspicious shadow; never auto-open | chair leg |
| X12 | **Refunded Curse** | support | Steals one curse stack and places it on floor as hazard | Touch cleansing tile after enemy defeated | curse receipt |
| X13 | **Garden Tax Collector** | elite hunter | Marks loose Petals then vaults toward player in line | Spend or reposition; reclaim dropped Petals | tax stamp |
| X14 | **The Bad Bloom** | elite hunter | Blooms all five status colors in sequential sectors | Read bloom order and move sector to sector | bad blossom |

### Enemy evolution model and animation responsibilities

For each species create idle, navigate, windup, attack active, recover, stagger, damage flash and defeat states. Small creatures may share animation rigs **only when their silhouette and attack timing are still identifiable**. Every species gets one behavioral hook, one counterskill, one preferred terrain, and at least one elite modification candidate.

The enemy director should maintain a vector of strategic roles and forbid degenerate rooms composed exclusively of unanswerable ranged suppressors. Enemy variants can be generated by combining base species with **one coherent mutation, one visible costume/silhouette cue, and one reward adjustment**. Never treat a palette swap as an entire additional species; it is a skin. Elite and mutator tables later multiply this bestiary into thousands of valid encounters without requiring thousands of separate AI scripts.

## 30. Weapon codex — 120 starting, found, cursed and cross-class weapons

All weapons have explicit **equip compatibility**, attack animation pack, windup, range, damage coefficient, knockback, projectiles, status tags, rarity band, source, audio and upgrade/evolution family. Weapon names must not be mere stat sticks: each of the **120 authored weapons below** gets its own mechanical hook. A cross-class weapon uses one of a few deliberately authored universal animation sets; do not pretend a sword can use a witch's grimoire animation unchanged.

**Acquisition:** standard starter weapons, chest discoveries, elites, merchants, chapter boss rewards, event bargaining, hidden achievements and curses. A hero starts only with its canonical weapon; other weapons must be found/unlocked. Keep loot curated to hero eligibility, with occasional universal crossover for surprise. Tooltips state control differences before equip. Retain the possibility of refusal and weapon comparison, not auto-replace.

### Angela • swords, shields and oaths — 20 weapons

| # | Weapon | Unique gameplay effect | Tags |
|---|---|---|---|
| 01 | **Lilyblade** | Three-hit knight combo; third slash pushes and trims thorn tiles | `guard,physical` |
| 02 | **Royal Cleaver** | Slow heavy cleave applies Guardbreak to shielded enemies | `heavy,guard` |
| 03 | **Thornmail Saber** | Perfect guard fires thorn projectiles along facing | `guard,thorn` |
| 04 | **Morning Promise** | First blade hit each room creates a tiny defensive aura | `guard,light` |
| 05 | **Blueglass Rapier** | Low-damage fast thrusts get bonus after exact-timed dodge | `precision,counter` |
| 06 | **Ceremonial Longsword** | Finisher gains extra reach if last two hits connected | `combo,physical` |
| 07 | **Iron Lily Mace** | Short reach; stagger value doubles against armor | `stagger,heavy` |
| 08 | **Oathbreaker Greatsword** | Consumes small HP on charged slash for huge cleave | `curse,low_hp` |
| 09 | **Sunrise Parasol** | Parasol blocks frontal bullets then thrusts at short range | `guard,reflect` |
| 10 | **Petal Guillotine** | On third clean counter, sends vertical petal blade | `counter,projectile` |
| 11 | **Cold Vow** | Successful parry chills attacking enemy; cooldown per target | `guard,frost` |
| 12 | **Rose Rampart** | Wide blade attack plants brief rose hedge at endpoint | `control,thorn` |
| 13 | **Clocksteel Edge** | Attacks gain rhythmic crit window at audible ticks | `rhythm,crit` |
| 14 | **Queenless Scepter** | Sword-shaped scepter turns guard Resolve into short beam | `resource,magic` |
| 15 | **Fallen Brideblade** | Curse weapon trades max health for leech after kill | `curse,leech` |
| 16 | **Dueling Teaspoon** | Tiny thrust range, exceptionally fast parry recovery | `counter,comedy` |
| 17 | **Moonlit Bastion** | Guard stores intercepted projectile and releases on skill | `guard,return` |
| 18 | **Marble Halberd** | Large horizontal sweep breaks fragile props and creates space | `cleave,environment` |
| 19 | **Last Bouquet** | Critical finisher explodes only if previously perfect-guarded | `crit,guard` |
| 20 | **Absolutely Fine Sword** | Higher damage after taking nonlethal hit, fades on recovery | `berserk,risk` |

### Vivianne • grimoires, staves and ink — 20 weapons

| # | Weapon | Unique gameplay effect | Tags |
|---|---|---|---|
| 01 | **Rosebound Grimoire** | Small homing rose-thorns through a fixed tracking cone | `spell,rose` |
| 02 | **Black Margin** | Ink spells leave short-lived cutting serif edges | `ink,dot` |
| 03 | **Moonquill Staff** | Aimed lunar orb blooms after traveling full range | `arcane,range` |
| 04 | **Sleepy Comet** | Slow comet applies Drowsy then bursts on wall | `drowsy,burst` |
| 05 | **Vesper Bell** | Every third cast creates a concentric bell pulse | `rhythm,area` |
| 06 | **Cursed Anthology** | Cast alternates from three revealed status pages | `random,curse` |
| 07 | **Inkstorm Umbrella** | Channels small rain of ink droplets in aimed wedge | `channel,area` |
| 08 | **Paperback Apocalypse** | Thrown pages orbit once then fly outward at marked foes | `orbit,burst` |
| 09 | **Winter Haiku** | Three small frost words form a short frozen line | `frost,control` |
| 10 | **Bloodrose Wand** | Spells spend tiny HP to apply Bleed and recover via precision | `curse,bleed` |
| 11 | **Tombstone Bookmark** | First spell after dodge summons stone-page projectile | `dodge,projectile` |
| 12 | **Astral Fountain Pen** | Critical spells duplicate as weaker delayed afterimages | `crit,echo` |
| 13 | **Silent Poetry** | No cast audio; stronger single hit but slower follow-up | `single_hit,heavy` |
| 14 | **Tanglewood Script** | Missed magic bolts plant short-lived thorn sigils | `miss,control` |
| 15 | **Lullaby Lantern** | Small radius slows enemies while active, drains Ink | `aura,ink` |
| 16 | **Wicked Thesaurus** | Spells shift damage tag on every fourth cast with indicator | `element,cycle` |
| 17 | **Glass Sonnet** | Piercing spell that shatters into limited shards on wall | `pierce,glass` |
| 18 | **Raven Manuscript** | Creates one raven familiar that pecks foes near residue | `summon,spell` |
| 19 | **Last Poet Quill** | At low HP, spells widen but player casts are interruptible | `low_hp,range` |
| 20 | **Ten Thousand Roses** | Long-charge area spell; each killed rose reduces recovery | `ultimate,aoe` |

### Nixia • gauntlets, boots and ridiculous fists — 20 weapons

| # | Weapon | Unique gameplay effect | Tags |
|---|---|---|---|
| 01 | **Orchid Gauntlets** | Fast punch strings build Momentum with clean hits | `combo,physical` |
| 02 | **Pocket Thunder** | Final jab charges one short chain lightning | `combo,arcane` |
| 03 | **Firewall Knuckles** | Block one bullet with perfect combo finisher | `guard,combo` |
| 04 | **Tiny Hammerfists** | Slower punches, huge knockback; collisions damage bystanders | `heavy,collision` |
| 05 | **Violet Boxing Gloves** | Punches mark targets; switch targets to cash bonus damage | `target_switch,combo` |
| 06 | **Root Admin Fists** | At max Momentum, special applies Breach mark | `resource,breach` |
| 07 | **Spore Punchers** | On kill, gloves shed small poison cloud behind target | `poison,on_kill` |
| 08 | **Clockwork Mitts** | Every fourth hit delivered exactly on beat stuns | `rhythm,stagger` |
| 09 | **Waffle-Iron Gauntlet** | Wider smash leaves square heat mark that briefly burns | `fire,area` |
| 10 | **Overclock Sneakers** | Damage lower while still; increasing movement builds punch speed | `move,haste` |
| 11 | **Metallic Ribbon Wraps** | Dash through target leaves short delayed hit thread | `dash,trap` |
| 12 | **Almost Legal Gloves** | Crit chance increases after near-misses with cooldown | `dodge,crit` |
| 13 | **Mushroom Slappers** | Against fungal enemies, damage builds cap-bounce effect | `biome,control` |
| 14 | **The Insulting Palm** | Very short-range open-hand slap taunts one hostile | `taunt,single` |
| 15 | **Breachbreaker** | Guardbreak on finisher; low attack speed during recovery | `guardbreak,heavy` |
| 16 | **Exploding Handshake** | First punch to a fresh target plants timed mini-bomb | `burst,mark` |
| 17 | **Double-Or-Nothing Claws** | Consecutive hits grow damage; whiff resets streak | `combo,risk` |
| 18 | **Cosmic Boxing Gloves** | Perfect dash briefly enlarges next punch hitbox | `dodge,range` |
| 19 | **Moon Bounce Boots** | Leap attack ricochets once to nearby target | `air,mobility` |
| 20 | **Final Argument** | Rare gauntlet; ultimate ends with capped screen-wide shockwave | `ultimate,shock` |

### Virelia • bows, arrows and botanical traps — 20 weapons

| # | Weapon | Unique gameplay effect | Tags |
|---|---|---|---|
| 01 | **Camellia Longbow** | Charged arrow benefits from aimed weak-point hits | `precision,bow` |
| 02 | **Trellis Recurve** | Arrows plant tiny vines on walls after misses | `trap,wall` |
| 03 | **Ribbon String** | Every marked hit pulls weak target a short distance | `mark,position` |
| 04 | **Orchard Harpbow** | Firing on audible beat adds one faint second arrow | `rhythm,multishot` |
| 05 | **Hollowglass Bow** | Pierces first enemy, shatters after second | `pierce,glass` |
| 06 | **White Thorn Quiver** | Poisoned arrows become thornbound after third hit | `poison,control` |
| 07 | **Sunflower Ballista** | Slow charged shot ignores shields but creates aim commitment | `heavy,guardbreak` |
| 08 | **Dewdrop Sling** | Light arcing droplets extinguish fire then chill targets | `water,frost` |
| 09 | **Bellflower Hunter** | Arrows ring a bell that reveals hidden enemies | `reveal,precision` |
| 10 | **Mothwing Crossbow** | Fires in a wide arc; manual aim can tighten spread | `spread,aim` |
| 11 | **Snarewood Bow** | Arrows leave tripwire anchors between two valid walls | `trap,link` |
| 12 | **Astral Compass** | Guided arrow curves once toward mark; limited turn angle | `homing,mark` |
| 13 | **Feather Ledger** | Reward for no-miss room: one temporary bonus arrow | `streak,economy` |
| 14 | **Crimson Trellis** | Marked enemies drop blood vines that heal one tiny amount on pickup | `mark,leech` |
| 15 | **Petal Harpoon** | Charged shot drags fragile enemies toward positioned trap | `pull,trap` |
| 16 | **Glass Orchard** | Crit arrow splits into three non-recursive seeds | `crit,split` |
| 17 | **Windblown Camellia** | Moving laterally before firing bends shot into sweep | `move,curve` |
| 18 | **Moonthread Sniper** | Stationary focus unlocks one long-range line shot | `focus,charged` |
| 19 | **Royal Gardener** | Trap-triggered arrows hit nearby marked targets once | `trap,synergy` |
| 20 | **Perfect Arrangement** | Rare bow; ultimate converts three precision marks into petal rain | `ultimate,mark` |

### Zaria • daggers, paint and strange equipment — 20 weapons

| # | Weapon | Unique gameplay effect | Tags |
|---|---|---|---|
| 01 | **Iris Twin Daggers** | Alternating left/right hits grow Color Charge | `combo,paint` |
| 02 | **Palette Knives** | Different colored hits alternate Burn and Chill | `element,alternate` |
| 03 | **Graffiti Shivs** | Crit kills leave wall sigils that fire one short shard | `crit,environment` |
| 04 | **Streetlight Stiletto** | Attack from near shadow amplifies first backstab | `stealth,backstab` |
| 05 | **Splash-Tip Daggers** | Throw dagger paints small slow zone, then returns | `ranged,control` |
| 06 | **Neon Razor** | Dash leaves colored slash line that pops after delay | `dash,trap` |
| 07 | **Heterochrome Blades** | Alternating crits builds two-color finishing attack | `crit,color` |
| 08 | **Ink-Slick Kukri** | Bleeding enemies leave a speed-giving paint trail | `bleed,mobility` |
| 09 | **Lucky Spraycan** | Short-range paint cone applies one visible random status | `random,status` |
| 10 | **Midnight Marker** | Backstab places a decoy at former position | `backstab,decoy` |
| 11 | **Clockface Shank** | Every fourth attack repeats after fixed time interval | `echo,rhythm` |
| 12 | **Rose Tattoo Needle** | Poisoned dagger hits briefly spread to neighboring targets | `poison,spread` |
| 13 | **Shattered Gallery** | Breaking scenery loads first strike with glass splinters | `environment,burst` |
| 14 | **Pocket Cutlass** | Wide but lower-damage cross slash to manage swarms | `cleave,physical` |
| 15 | **Astral Sprayblade** | Projectiles mark floor; dash over marks reloads blade | `ranged,dash` |
| 16 | **Bad Idea Switchblade** | High crit damage, but critical miss buffs next enemy swing | `risk,crit` |
| 17 | **Color Wheel Daggers** | Every third distinct status produces a limited colorful nova | `tricolor,burst` |
| 18 | **Gallery Thief** | Damaging merchant props is prohibited; treasure guardians drop bonus coins | `theft,economy` |
| 19 | **Rooftop Ripper** | Side-dash attack pierces one target and seeks next shadow | `mobility,pierce` |
| 20 | **Final Masterpiece** | Rare dagger pair; completion of three-color combo unlocks capped execution | `ultimate,color` |

### Universal and bizarre crossover armory — 20 weapons

| # | Weapon | Unique gameplay effect | Tags |
|---|---|---|---|
| U01 | **Butter Knife of Doom** | Weaker basic hits; every seventh registered hit executes eligible normal foe, bosses receive capped burst | `universal,execute` |
| U02 | **Squeaky Hammer** | Heavy impact stuns weak enemies; sound draws additional attention from distant enemies | `universal,comedy` |
| U03 | **Haunted Broomstick** | Sweeps foes away while automatically collecting loose Petals in short cone | `universal,utility` |
| U04 | **Mushroom Launcher** | Lobs timed spores; unsafe for tight rooms unless aimed | `universal,explosive` |
| U05 | **Comically Large Ladle** | Slow scoop attack lifts ground hazards and throws one back | `universal,environment` |
| U06 | **Broken Mirror** | Counter/evade casts one delayed mirror projectile | `universal,reflect` |
| U07 | **Garden Hose** | Continuous short water beam extinguishes fires, adds slippery floor | `universal,water` |
| U08 | **Clock Key** | Windup hit stores brief attack speed surge after perfect timing | `universal,rhythm` |
| U09 | **Cursed Toothpick** | Rapid low chip damage stacks Bleed with strict stack cap | `universal,bleed` |
| U10 | **Starfish Wand** | Five-prong arcane spray with reduced single-target accuracy | `universal,arcane` |
| U11 | **Borrowed Umbrella** | Deflects one directional projectile each cooldown, weak melee | `universal,guard` |
| U12 | **Rosemary Frying Pan** | Charged slam creates fragrant decoy that attracts fungal enemies | `universal,decoy` |
| U13 | **Void Bubble Blower** | Slow bubbles capture minor enemy projectiles and pop | `universal,control` |
| U14 | **Paper Fan of Regret** | Fan disperses clouds but cannot pierce armor | `universal,utility` |
| U15 | **Bell of Questionable Luck** | Fires random note that is telegraphed before each cast | `universal,random` |
| U16 | **Catastrophic Rolling Pin** | Rolling attack gains distance damage, hard recovery | `universal,charge` |
| U17 | **Floating Photo Frame** | Orbiting blunt frame protects one side of hero | `universal,orbit` |
| U18 | **Wishbone Spear** | Long thrust has small heal chance only on weak-point hits | `universal,precision` |
| U19 | **Potted Cactus** | Place a small cactus turret with tight summon limit | `universal,summon` |
| U20 | **The Receipt** | Converts purchased item discounts into one room-long attack buff | `universal,economy` |

## 31. Relic encyclopedia — 130 bespoke build-modifying relics

Each relic has ID, rarity, allowed tags, stacking rule, trigger, clear status icon and hard cap where appropriate. These are **130 distinct mechanical relics** distributed across thirteen themes; combinations must be tested. In particular, avoid proc storms: a reflected attack should not automatically trigger another reflect or on-hit loop unless specifically authored. A tooltip says exactly what it changes and whether it is consumed, floor-limited or permanent for the run.

### Guard, retaliation and resistance — 10 relics

| # | Relic | Meaningful effect |
|---|---|---|
| 01 | **Crown of Patience** | After two consecutive blocks, next counter fires a thorn fan. |
| 02 | **Thornmail** | Perfect guard sends small thorns to latest attacker. |
| 03 | **Polished Lily** | First block in each room clears one negative status. |
| 04 | **Borrowed Shield** | Dodge direction becomes briefly shielded after a perfect guard. |
| 05 | **Proud Buttons** | Every armor repair drops one harmless petal that becomes Resolve if collected. |
| 06 | **Stone Tea Set** | Standing near intact cover grants modest resistance; breaks when cover falls. |
| 07 | **Counterclock Locket** | Parry one projectile and send it back at reduced damage. |
| 08 | **Stubborn Ribbon** | Taking a hit increases knockback resistance temporarily. |
| 09 | **Tiny Fort** | Heavy melee impact plants a short-lived cover fragment. |
| 10 | **Ceramic Resolve** | Breaking enemy guard refreshes one shield segment. |

### Crit, precision and exposed targets — 10 relics

| # | Relic | Meaningful effect |
|---|---|---|
| 01 | **Needle Crown** | Weak-point critical hit places a visible follow-up mark. |
| 02 | **Glass Eyelash** | Perfect dodge makes next shot or slash narrowly pierce. |
| 03 | **Lucky Eyebrow** | First critical hit each room gains a minor extra Petal chance. |
| 04 | **Precision Glove** | Consecutive hits at a single target narrow aiming spread. |
| 05 | **Two-Toned Lens** | Alternating targets preserves one crit streak charge. |
| 06 | **Shattered Monocle** | Breaking glass props exposes nearby hostile briefly. |
| 07 | **Golden Ruler** | Attacks from beyond normal melee range have capped precision bonus. |
| 08 | **Quiet Bookmark** | Taking no damage in a room highlights the next elite weak point. |
| 09 | **Falling Star Pin** | Critical damage drops a star that can be collected to reload skill. |
| 10 | **The Last Dot** | Three correctly timed crits trigger one capped burst. |

### Poison, bleed and thorn ecology — 10 relics

| # | Relic | Meaningful effect |
|---|---|---|
| 01 | **Cursed Lily** | Double damage potential while cursed; healing heavily restricted as disclosed. |
| 02 | **Snakeflower Badge** | Poison ticks sometimes drop one tiny thorn seed. |
| 03 | **Red Sap Bottle** | Bleeding enemy defeat leaves a dangerous yet harvestable sap pool. |
| 04 | **Roseworm Ring** | Poisoned enemies that charge drag their own thorn trail. |
| 05 | **Thimble of Nettles** | Melee contact with attacker applies minor poison with cooldown. |
| 06 | **Thorn Nursery** | Two thorn traps within range bloom into a stronger single trap. |
| 07 | **Black Pollen** | Poison clouds briefly reduce enemy accuracy. |
| 08 | **Garden Scalpel** | Striking a Bleeding marked foe heals one small capped amount. |
| 09 | **Venom Lantern** | Shops reveal poison-related items more often after unlock. |
| 10 | **Rotting Bouquet** | When poisoned enemies die, a small spore bomb appears with a fuse. |

### Fire, frost, arcane and elemental — 10 relics

| # | Relic | Meaningful effect |
|---|---|---|
| 01 | **Teacup Volcano** | Fire stacks ignite one small puddle after threshold. |
| 02 | **Snowdrop Earring** | Perfect dodge while Chilled creates ice shard. |
| 03 | **Conductive Spoon** | Lightning seeks the nearest second Conductive target. |
| 04 | **Moon Prism** | Different elements in sequence create one small arcane flash. |
| 05 | **Boiling Ribbon** | Burn duration longer against rooted enemies. |
| 06 | **Cold Oven** | Frost attacks against burning foes create brief steam screen with hazard outline. |
| 07 | **Astral Salt** | Arcane kills leave pickups that restore tiny class resource. |
| 08 | **Glass Thermometer** | Alternating Fire/Frost triggers one thermal shock with cooldown. |
| 09 | **Cinder Bouquet** | Entering room with no Burn active grants one primed flame projectile. |
| 10 | **North Star Tea** | Frost effects are shorter but improve player movement on ice. |

### Projectiles, ricochets and range — 10 relics

| # | Relic | Meaningful effect |
|---|---|---|
| 01 | **Bouncy Button** | First wall collision bounces eligible bolt once. |
| 02 | **Scarecrow Eye** | Projectile that misses a target can return as weaker bolt. |
| 03 | **Split Pea** | Every fifth shot splits into two weaker side shots, no recursive splitting. |
| 04 | **Teapot Spout** | Aimed projectiles gain accuracy after standing still. |
| 05 | **Corner Ribbon** | Shots aimed around cover curve slightly with visible tracer. |
| 06 | **Barrel Lens** | Projectiles that hit barrels create a small expanding attack ring. |
| 07 | **Pinwheel** | After a clean dodge, next projectile gains one orbit then launches. |
| 08 | **Sniper Camellia** | Long-range hits prime a small recovery speed buff. |
| 09 | **Kite Thread** | Arrows and knives can tether two weak foes briefly. |
| 10 | **Return Address** | One thrown weapon returns faster if it hit an elite. |

### Combo, momentum and attack rhythm — 10 relics

| # | Relic | Meaningful effect |
|---|---|---|
| 01 | **Orchid Punch Card** | Every eight clean hits grant one cheap burst. |
| 02 | **Metronome Heart** | Attacking on visual beat refunds a portion of ability cost. |
| 03 | **Rude Applause** | Combo finisher makes weaker enemies briefly flinch. |
| 04 | **Pocket Stopwatch** | A perfect-timed dodge prevents combo decay for a moment. |
| 05 | **Hype Ribbon** | Swapping targets without whiff gives a short move-speed boost. |
| 06 | **Practice Bell** | Hitting training dummy in hub teaches timing, no paid stats. |
| 07 | **Fistful of Petals** | Five-hit combo releases a tiny petal ring. |
| 08 | **No Breaks** | Combo score slows decay when enemy enters invulnerable phase. |
| 09 | **Sensible Shoes** | Attack recovery can be dodge-canceled once per room. |
| 10 | **Absolute Menace** | Sustained no-hit combo shows silly crown and raises stagger. |

### Dodge, mobility and positioning — 10 relics

| # | Relic | Meaningful effect |
|---|---|---|
| 01 | **Painted Exit** | Dodge leaves a visible temporary safe-zone arrow. |
| 02 | **Petal Skates** | Perfect dodge over a hazard grants brief speed. |
| 03 | **Moonlight Sneakers** | Every third dodge with no damage leaves decoy. |
| 04 | **Sidewalk Chalk** | Sliding along a wall draws a damaging small line. |
| 05 | **Lily Compass** | One highlighted safe gap appears on first unfamiliar boss attack. |
| 06 | **Slippery Tea** | Shorter dodge cooldown while inside wet tiles, but less control. |
| 07 | **Feather Boots** | Walk over one small trap before it arms, once per room. |
| 08 | **Tiny Umbrella Handle** | Dodge through projectile gives a one-shot shield against next. |
| 09 | **Ghostly Ribbon** | After dodge, first swing has slightly longer reach. |
| 10 | **Cheeky Shortcut** | Open one optional noncombat route after flawless floor clear. |

### Summons, familiars and orbitals — 10 relics

| # | Relic | Meaningful effect |
|---|---|---|
| 01 | **Pocket Scarecrow** | Place one decoy scarecrow; only one active. |
| 02 | **Tea Familiar** | Tiny animated cup follows and sometimes blocks pea shot. |
| 03 | **Rose Raven** | One raven attacks marked targets with long cooldown. |
| 04 | **Clockwork Firefly** | Firefly reveals traps and emits harmless targeting blink. |
| 05 | **Potted Bodyguard** | Portable cactus reflects one close hit before breaking. |
| 06 | **Three Bad Bees** | Spawn max three tiny bees that expire after room. |
| 07 | **Notebook Ghost** | A ghost repeats a small portion of last valid spell. |
| 08 | **Orchid Drone** | Small drone marks enemies that take combo finishers. |
| 09 | **Gentle Slug** | Slug pet paints one short safe slick path. |
| 10 | **Starflower Totem** | Single stationary totem emits periodic tiny arcane pulses. |

### Economy, discovery and curiosity — 10 relics

| # | Relic | Meaningful effect |
|---|---|---|
| 01 | **Petal Purse** | Collect loose Petals from a slightly larger radius. |
| 02 | **Merchant Smile** | Reveal next shop discount before route choice. |
| 03 | **Honest Receipt** | A purchase writes a small refund voucher for future room. |
| 04 | **Mapmaker Seed** | Reveal one adjacent optional room on floor map. |
| 05 | **Treasure Smell** | Noncombat chests emit subtle gold particle clue. |
| 06 | **Broken Piggybank** | On death, slightly more Garden Seeds, but starting Petals fewer. |
| 07 | **Friendly Tax** | Elite drops a bonus Petal if its special move was countered. |
| 08 | **Bargain Rose** | First shop reroll per floor costs fewer Petals. |
| 09 | **Appraiser Glass** | Item choice reveals hidden synergy tags. |
| 10 | **One More Chest** | Room with no heal may offer an extra risky optional chest. |

### Low HP, berserker and sacrifice — 10 relics

| # | Relic | Meaningful effect |
|---|---|---|
| 01 | **Angela’s Wedding Ring** | Once per floor survive lethal attack at 1 HP, gain brief iframes. |
| 02 | **Cracked Heart** | Under 30% HP, attacks create red afterimage every third swing. |
| 03 | **Rose Hemostat** | After a damage-boost sacrifice, next kill has limited heal. |
| 04 | **Dangerous Smile** | Low HP enables small guaranteed stagger after dodge. |
| 05 | **Last Teaspoon** | At one HP, next basic attack gains wide cone once. |
| 06 | **Debt of Petals** | Spend max HP at altar for immediate relic choice. |
| 07 | **Fractured Mirror Heart** | Low HP creates one decoy only on entering new combat room. |
| 08 | **Blooming Bruise** | Recent damage increases retaliatory thorn area. |
| 09 | **Unhealthy Optimism** | Healing item consumed below 15% HP restores extra but adds curse. |
| 10 | **Red Wedding Veil** | Cursed damage buffs increase when attacks are narrowly dodged. |

### Curses, gambles and chaos — 10 relics

| # | Relic | Meaningful effect |
|---|---|---|
| 01 | **Questionable Potion** | Healing triggers friendly outward blast; also alerts nearby enemies. |
| 02 | **Two-Sided Coin** | After elite kill choose immediate safe reward or higher-risk unknown item. |
| 03 | **Wrong Way Sign** | Reveals rare shortcut but turns one ordinary room into challenge. |
| 04 | **Greedy Crown** | Elite frequency rises; elite loot better. |
| 05 | **Bent Dice** | First critical hit each room may double or halve bonus effect with preview. |
| 06 | **Doom Coupon** | One expensive shop item free, next shrine cost rises. |
| 07 | **Shifting Label** | Once per floor reroll one item offered; accept random new item. |
| 08 | **Tragic Opera Ticket** | Secret room with dangerous mini-performance may appear. |
| 09 | **Rotten Star** | Gain arcane damage; positive status durations shortened. |
| 10 | **Unstable Halo** | Orbitals become stronger but pop into visible hazards on expiry. |

### Room, terrain and trap engineering — 10 relics

| # | Relic | Meaningful effect |
|---|---|---|
| 01 | **Gardener Gloves** | One placed trap may be repositioned before arming. |
| 02 | **Porcelain Repair Kit** | Breaking fragile prop restores small class resource. |
| 03 | **Dustpan** | Clearing a hazard leaves tiny chance of seed pickup. |
| 04 | **Clockface Tile** | Moving across marked clock tile empowers next timed attack. |
| 05 | **Maple Floor Wax** | Wet tiles make enemies slide after a failed charge. |
| 06 | **Portable Garden Bed** | Rest room lets player plant one later healing bloom at cost. |
| 07 | **Emergency Exit Sticker** | Once per run show emergency route during a cursed room. |
| 08 | **Rope and Ribbon** | Allows connecting two compatible placed snares. |
| 09 | **Singing Floorboard** | Stepping on trap warns nearest ambusher before attack. |
| 10 | **Tiny Architect** | Destroying wall-cover creates one beneficial but risky projectile path. |

### Boss hunting, mutations and endgame — 10 relics

| # | Relic | Meaningful effect |
|---|---|---|
| 01 | **Moldy Crown** | Defeat knife mushroom elites faster through one extra weakness. |
| 02 | **Chandelier Trophy** | Boss arenas sometimes expose one destructible useful prop. |
| 03 | **The Sixth Petal** | After five different status applications to boss, gain tiny recovery window. |
| 04 | **Echo Diary** | Shows last defeat’s boss attack cue in codex before rematch. |
| 05 | **Timepiece Rose** | Boss phase transition refills tiny fraction of class resource. |
| 06 | **Crownless Medal** | Elite-kill streak increases next elite loot tier chance slightly. |
| 07 | **Astral Bookmark** | Reveals one compatible Endless mutator before entry. |
| 08 | **Boss Tax Return** | No-hit boss victory grants extra Garden Seeds later. |
| 09 | **Rotating Halo** | Each biome change reselects one visible elemental resistance. |
| 10 | **Endless Lily** | Every ten Endless floors choose one trade-off modifier to keep. |

## 32. Curse catalog — 30 voluntary bargains

Curses are announced and described **before** binding, except explicitly marked mystery choices that list the possible pool and maximum downside. A curse adds power, danger and flavor. A curse should never quietly disable touch controls, permanently softlock the player or remove all counterplay. Add reveal conditions, clear icons and hero-specific reaction bubbles.

| # | Curse | Positive trade / negative cost |
|---|---|---|
| 01 | **Shaking Hands** | Attack speed +; precision reticle drifts slightly; never unplayable. |
| 02 | **Fogged Glass** | More rare loot; rooms show limited minimap until visited. |
| 03 | **Greedy Roots** | Extra Petals; if player carries too many, a visible tax collector may spawn. |
| 04 | **Red Moon Debt** | Damage up at low HP; healing items cost more. |
| 05 | **Moth’s Attention** | Crit damage up; moth ambushers spawn more often. |
| 06 | **Cracked Shield** | Parry reward doubled; blocking window narrower and signaled. |
| 07 | **Spoiled Crown** | One extra relic choice per boss; one additional elite attack in boss phase. |
| 08 | **Unreliable Clock** | More skill power; ability cooldown alternates clearly between two durations. |
| 09 | **Ashen Tongue** | Burn stronger; frost heals less from elemental interactions. |
| 10 | **Thorn Breath** | Melee hits apply thorns; player leaves short visible thorn path while dodging. |
| 11 | **Poet’s Tax** | Spells cost less Ink; shop prices rise after chapter boss. |
| 12 | **Broken Umbrella** | Reflected bolts stronger; defensive umbrella duration shortened. |
| 13 | **Unpaid Royalty** | Bosses give more Garden Seeds; elite drops give fewer Petals. |
| 14 | **Color Blind Fate** | Tri-color effects stronger; warning UI uses pattern markers to stay accessible. |
| 15 | **Smaller World** | Rooms contain more treasure but less walking clearance, validator still enforces dodge lanes. |
| 16 | **Very Loud Shoes** | Movement speed up; hidden enemies detect player sooner. |
| 17 | **Wet Matches** | Fire AoE larger; self-applied Burn resistance reduced but bounded. |
| 18 | **Honeyed Blade** | Leech from kills; killing too slowly starts a visible fatigue debuff. |
| 19 | **Dollmaker’s Favor** | Summons live longer; each summon slightly reduces direct damage. |
| 20 | **Contract of Threes** | Every third room grants relic; every third room contains harder encounter. |
| 21 | **No Second Cup** | Shop discounts; resting rooms cannot heal unless rare shrine appears. |
| 22 | **Glittering Doom** | Crit bursts look gigantic; visual clarity mode automatically limits particle count. |
| 23 | **Royal Embarrassment** | Parries cause bigger stagger; failed parries taunt nearest foe. |
| 24 | **Astral Drift** | Dodge range up; aim snaps to targets less aggressively. |
| 25 | **Hollow Appetite** | Consumable effects stronger; consumables cannot stack beyond two. |
| 26 | **Stolen Spring** | Faster attack recovery; max Resolve/Ink/Momentum/Focus/Color reduced. |
| 27 | **Eternal Bloomer** | Thorn traps persist; fewer trap slots available. |
| 28 | **Last Page** | Ultimate more powerful; it charges only from skilled actions, not idle. |
| 29 | **Glass Crown** | Rare weapons drop more; max HP reduced by meaningful fixed amount. |
| 30 | **Forgotten Anniversary** | Once per run fatal blow prevented; one random noncritical relic shatters afterward. |

## 33. Authored synergistic combinations — 35 craft discoveries

On meeting the conditions, show a quick discovery banner and codex entry. Unlocking a synergy must not require online data. The resolver uses **effect IDs with event provenance** and forbids unbounded feedback cycles. These 35 are authored examples to implement, not a limit: expand with additional sensible combinations after balance coverage.

| # | Synergy | Combination | Evolved interaction |
|---|---|---|---|
| 01 | **Iron Bouquet** | Thornmail + Counterclock Locket | Perfect guard reflects a projectile and plants one thorn at landing. |
| 02 | **Poet’s Funeral** | Black Margin + Raven Manuscript | Raven pecks trigger ink residue echo once per enemy. |
| 03 | **Orchid Overclock** | Orchid Punch Card + Metronome Heart | Rhythm perfect combo charges shorter ultimate burst. |
| 04 | **Tidy Disaster** | Snarewood Bow + Sewing Thread | Linked snares trigger arrows across the thread once. |
| 05 | **Gallery Fire** | Neon Razor + Teacup Volcano | Paint trails can ignite after a small warning fuse. |
| 06 | **Crown of Moths** | Moth’s Attention + Moldy Crown | Moth kills refresh fungal elite weak-point mark. |
| 07 | **Frozen Tea** | Snowdrop Earring + Teapot Spout | Wet projectile collision has small frost bloom. |
| 08 | **Rose Receipt** | Honest Receipt + Royal Cleaver | Shop receipt converts into one temporary counter charge. |
| 09 | **Ink and Glass** | Glass Sonnet + Shattered Monocle | Shattered projectile pieces briefly expose targets. |
| 10 | **Tiny Meteor** | Cosmic Boxing Gloves + Pocket Meteor | Airborne landing releases one extra stagger wave. |
| 11 | **Wedding Day** | Angela’s Wedding Ring + Last Bouquet | Surviving lethal blow primes one enormous guarded finisher. |
| 12 | **Rope Trick** | Rope and Ribbon + Ribbon String | Arrows tug marked weak foes into active snare lines. |
| 13 | **Moon Orchestra** | Orchard Harpbow + Vesper Bell | Beat-aligned attacks add a clear harmonic shockwave. |
| 14 | **Doom Ledger** | Butter Knife of Doom + Feathers Ledger | Seventh hit execute makes a visible quiver token rather than extra kill loops. |
| 15 | **Broken Opera** | Tragic Opera Ticket + Silent Poetry | Opera room offers unique silent spellbook reward. |
| 16 | **Infinite Tea** | Tea Familiar + Duchess reward porcelain | Cup familiar gets one emergency projectile interception per room. |
| 17 | **Red Camellia** | Crimson Trellis + Rose Hemostat | Trap-triggered Bleed creates tiny limited HP petals. |
| 18 | **Star Architect** | Tiny Architect + Starlace Spider trophy | Cover break creates temporary constellation bridge. |
| 19 | **Root Access** | Root Admin Fists + Combo Firewall | Combo breach makes one shielded enemy vulnerable to next finisher. |
| 20 | **Greedy Gardener** | Petal Purse + Greedy Roots | Increased collection radius but collector appears with extra warning. |
| 21 | **Clockwork Waltz** | Clocksteel Edge + Pocket Stopwatch | A perfect dodge stores one rhythm beat. |
| 22 | **Charming Chaos** | Two-Sided Coin + Color Wheel Daggers | Choosing risky reward loads one random revealed color effect. |
| 23 | **Orchid Crown** | Absolutely Menace + Tiny Crown | No-hit combo changes sprite expression and extends capped stagger. |
| 24 | **Briar Comet** | Tanglewood Script + Moonquill Staff | Missed orb grows thorns where it lands. |
| 25 | **Zero Mercy** | Cracked Heart + Red Wedding Veil | Low HP changes charged slashes into short-range cone with visual tell. |
| 26 | **Pressed Flower** | Pocket Scarecrow + White Thorn Quiver | Decoy death leaves snare petals once. |
| 27 | **Sensible Tax** | Sensible Shoes + Friendly Tax | Countering elite special while dodging earns Petals once. |
| 28 | **Backstreet Bloom** | Iris Exchange + Painted Exit | Stance-switch dodge plants safe exit arrow and paint shard. |
| 29 | **Night Garden** | Midnight Veil + Void Marigold reward | Decoy shadow collects hostile bullets briefly then bursts. |
| 30 | **Endless Date** | Endless Lily + Rotating Halo | Every tenth-floor trade-off includes a visible resistance option. |
| 31 | **Sunstroke** | Sunburnt Petunia trophy + Cinder Bouquet | Fire finisher generates one tiny beam on Elite kill. |
| 32 | **Big Little Problem** | Big Gloves + Tiny Hammerfists | Knockback collision creates second hit with per-target cooldown. |
| 33 | **Librarian of Doom** | Cursed Anthology + Appraiser Glass | Mystery page selection reveals one extra option. |
| 34 | **The Good Bad Idea** | Bad Idea Switchblade + Questionable Potion | Potion damage counts toward dagger combo but self-splash remains hazardous. |
| 35 | **Bloomheart Resonance** | The Sixth Petal + Starflower Totem | Fifth different status application triggers one extra totem pulse. |

## 34. Boss encyclopedia — 40 major, hidden and Endless encounters

Each entry is a **design packet** that must be expanded into full state-machine timelines, timings, hurtboxes, hit windows, death animation, intro, boss music variation, reward screen and codex page. All listed attacks should become actual distinct mechanics. Any boss with multiple phases gets a properly telegraphed transition. **Bosses are scarce, memorable, readable and hard**—never merely a red health bar above a common enemy.

The standard arc uses chapter bosses as anchors; optional bosses are distributed through challenge rooms, alternate routes, shrine contracts and Endless permutations. Defeating a named boss can unlock remixed versions, but remixes must feature a new attack and arena constraint with clear preview, not a hidden HP multiplier.

### Forgotten Garden — 4 bosses

| Boss | Arena identity | Three attack families | Escalation | Counterplay | Reward ideas |
|---|---|---|---|---|---|
| **The Gardener That Forgot** | Ruined fountain with removable hedges | Pruning shear cleave / watering-can rain / root-wall shove | At 55% drops watering can, opens more lane hazards and calls two saplings | Bait heavy shear into fountain stone; strike back while replanting | Forgotten Shears, Fountain Blessing, Old Key |
| **Queen of Dandelions** | Circular field with rising seed platforms | Fan seed volley / gust knockback / airborne seed bombs | At half HP her crown floats away and seeds reverse direction | Move with wind instead of against it; attack landed crown | Feather Crown, Windstep Sandals |
| **Compost Colossus** | Vegetable heap surrounded by compost pits | Hoe-slam shockwave / rolling cabbage / stench cloud | Armor sheds at 60% exposing a weak compost heart; pits expand | Strike exposed glowing knot after slam; do not stand in backwash | Hearty Compost, Fermented Flask |
| **The First Scarecrow** | Hay maze with two destructible posts | Needle throw / scarecrow lunge / fake stationary clones | Phase 2 swaps masks and telegraphs using twitching straw shadows | Identify real post by shadow; make lunge hit hay wall | Straw Crown, Honest Eyes |

### Mushroom Kingdom — 4 bosses

| Boss | Arena identity | Three attack families | Escalation | Counterplay | Reward ideas |
|---|---|---|---|---|---|
| **His Moldy Majesty** | Fungal royal court with four sturdy stalagmites | Dual knife X-slash / crown boomerang / timed puffball mines | At half HP cape tears, cyclone attack begins and exactly two Knife Shrooms arrive | Use diagonal X gap, detonate puffballs near his exposed crown | Twin Cleavers, Royal Mycelium, Spoiled Crown |
| **Mother of Spores** | Shallow cave lake with safe stepping mushrooms | Spore fan / poison floor bloom / drifting gas bubbles | Phase 2 reverses wind and makes gas blooms alternate safe color | Read wind banner and move to clean platforms | Mothercap Veil, Spore Vessel |
| **The Truffle Bandit** | Gold-flecked fungal vault with moving chest decoys | Corkscrew dash / stolen coin volley / rolling truffle | At 40% switches to fake coin magnet that pulls player toward hazard | Attack actual satchel; retrieve your displayed Petals afterward | Truffle Satchel, Loot Magnifier |
| **Saint Morel the Hollow** | Vertical fungus cathedral with narrow central aisle | Mycelium lances / bell spores / parasitic doll summons | After first stagger breaks staff into two; spore bells double rhythm | Watch bell rhythm and shatter left gill after second chant | Hollow Sporestaff, Silent Hymn |

### Clockwork Conservatory — 4 bosses

| Boss | Arena identity | Three attack families | Escalation | Counterplay | Reward ideas |
|---|---|---|---|---|---|
| **The Late Bell** | Clocktower floor with giant readable clock sectors | Clock-hand swipe / bell shock ring / winding gear missiles | At 50% tempo doubles for a short burst then stabilizes in alternating cycle | Count hand ticks; follow safe clock wedge; punish when bell jammed | Golden Hand, Late Bell Medal |
| **Baroness Brasswing** | Greenhouse rails with three linear moving carts | Needle dive / rotor gust / armor feather volley | At half HP detaches wings to make two destructible drones | Lead drones into rails and strike stationary brass core | Brasswing Pin, Rotor Boots |
| **The Unfinished Hour** | Two interlocking rotating ring platforms | Delayed time echo / repeated beam / rewind trap placement | At 60% repeats the last selected attack from two mirrored anchors | Treat echoes as fixed independent hazards; stand between rings | Second Chance Dial, Temporal Glass |
| **The Gearfather** | Furnace room with steam vents and lever switches | Rolling gear stampede / piston fist / rotating burner beam | At half HP overheats, vents open but weak joints glow | Operate lever during telegraph to vent heat safely | Gearfather Core, Hot Brass |

### Bloodbloom Forest — 4 bosses

| Boss | Arena identity | Three attack families | Escalation | Counterplay | Reward ideas |
|---|---|---|---|---|---|
| **The Weeping Orchard** | Huge tree-root center with four winding side lanes | Root lash / blood petal rain / marked lifedrain floor | At 55% trunk splits to reveal moving exposed heart | Use side lane when root lifts; strike heart after drain ends | Weeping Root, Red Orchard Crown |
| **Bride of Thorns** | Moonlit clearing with scattered thorn arches | Thorn bouquet throw / ribbon bind / sweeping veil cut | At half HP veil tears, thorn lanes weave opposite directions | Break bind marker before it closes; punish long veil recovery | Thorn Veil, Bloodrose Vein |
| **The Antlered Choir** | Pale tree amphitheater with three cursed bells | Antler charge / singing spirit cone / red flower explosion | At 40% surviving bells change pitch and extend charge routes | Silence one bell to change pattern; bait charge into trunk | Choir Antler, Bellflower Blood |
| **Widow of the Last Spring** | Swamp roots with retracting leaf bridges | Needle web / spider brood / spring-leech splash | Phase 2 raises web roof and rotates safe bridge selection | Destroy web anchor first; remain on bridge with green edge | Widow Silk, Last Spring Nectar |

### Hollow Palace — 4 bosses

| Boss | Arena identity | Three attack families | Escalation | Counterplay | Reward ideas |
|---|---|---|---|---|---|
| **Duchess of the Last Tea** | Banquet hall with safe moving tables | Hot tea fan / porcelain clone cups / steam circle | At 50% shatters cups, adds narrow returning saucer rings | Find cool-table lane and attack exposed spout after steam | Royal Porcelain, Duchess Saucer |
| **The Crownless Prince** | Mirror ballroom with two reflective panels | Fencing trio / mirrored clone slash / falling chandelier | At half HP removes mirror mask, clones gain a unique shadow indicator | Only attack prince with true floor shadow; let chandelier shatter mirror | Crownless Rapier, Prince’s Pin |
| **The Sleeping Banquet** | Dining room that transforms into moving food labyrinth | Fork hail / table slide / exploding soup pots | At 60% tables retreat; plates animate into staggered waves | Bait fork volley into sturdy table, then take free central lane | Banquet Napkin, Midnight Ladle |
| **Madam Black Velvet** | Stage with curtains and spotlights | Shadow spotlight / ribbon pull / puppet chorus | At 45% spotlights become damaging but reveal invisible puppets | Stay at edge of lit stripe, sever stage strings | Velvet Ribbon, Stage Pass |

### Astral Greenhouse — 4 bosses

| Boss | Arena identity | Three attack families | Escalation | Counterplay | Reward ideas |
|---|---|---|---|---|---|
| **The Starbound Florist** | Floating glass islands connected by bridges | Constellation ray / falling stars / orbiting thorn planets | At half HP reorders bridges but preview shows destination safely | Follow glowing safe constellation edge; strike after ray finishes | Starflower Crown, Planetary Thorn |
| **Queen of Two Moons** | Dual moon altar with rotating light/dark halves | Moon beams / lunar gravity pull / crescent slice | At 50% light and dark moons swap effects with loud chime | Enter neutral seam, track chime, aim after moon collision | Twin Moon Pendant, Lunar Compass |
| **Astral Gardener Number Zero** | Laboratory with three broken gravity nodes | Comet rake / gravity well / seed missile cluster | Phase 2 gravity nodes awaken sequentially; one is destructible | Destroy active node during safe period; dodge toward inert node | Zero Seed, Gravity Spade |
| **The Nebula Librarian** | Floating books on dark transparent grid | Star-letter barrage / bookcase rotation / delayed page bomb | At 40% books orbit to form temporary corridors | Read illuminated pages; cross empty letters not filled ones | Nebula Index, Galactic Page |

### Bloomheart Core — 4 bosses

| Boss | Arena identity | Three attack families | Escalation | Counterplay | Reward ideas |
|---|---|---|---|---|---|
| **The Bloomheart, Unraveled** | Fragmented Garden hub reforming around huge wish machine | Five-flower sequence / memory echo rush / petal gravity pulse | At 70% and 35% changes combat language but retains visible tells and safe transitions | Break named five flower nodes, then strike revealed heart | Garden Restored ending, Endless Key, Heartseed |
| **The Forgotten Promise** | Circular memory garden with fading portrait anchors | Echo counter / thorn spiral / vow chains | At 50% splits into two linked promises, one damages one shields | Observe chain color and break shield anchor before damage phase | Promise Seal, Vow Ribbon |
| **Five Shadows at Tea** | Garden table with five separate echo stations | Five recognizable heroine-fake skills in rotating turns | At half HP combines two at a time with fewer projectiles per move | Read silhouette and use class-matching counters learned in campaign | Mirror Tea Set, Fifth Seat |
| **The Empty Sixth Chair** | Quiet room with unused sixth seat and moving shadow | Chair charge / unspoken beam / invitation bind | At 40% chair unfolds into enormous shadow puppet with obvious string anchors | Break two string posts then punish chair collapse | Sixth Seat Trinket, Lost Guest Diary |

### The Endless — optional and remix bosses — 12 bosses

| Boss | Arena identity | Three attack families | Escalation | Counterplay | Reward ideas |
|---|---|---|---|---|---|
| **Tax Collector Supreme** | Golden receipt office, coin lanes | Stamped lane / receipt whip / coin tornado | At half HP files moving invoices with clear safe signatures | Destroy stamp desk, not every coin | Tax Crown |
| **The Very Large Goose** | Pond garden with bell towers | Triple honk dash / wing gust / egg mine | At 40% dons tiny crown and adds fake honks | Move only on real third honk indicated by footprint | Doom Feather |
| **Clockcap Emperor** | Mixed fungus-clockwork throne | Knife slash / gear cap spin / mushroom jump | At half HP alternates fast clock and slow spore phase | Track mechanical tick vs fungal pulse | Imperial Cap |
| **Curator of Bad Ideas** | Gallery of unsafe but marked upgrades | Paint hazard / cursed item toss / gallery frame crush | At 50% drops three tempting buffs with explicit drawbacks | Take only safe buff or reject them all | Bad Idea Ribbon |
| **Rose Paladin Prime** | Thorn-palace arena with shield mosaic | Counter shield / rose missiles / armor slam | At half HP exposes three elemental shield cycles | Read emblem and alternate elements or flank | Prime Rose Crest |
| **Archivist of Defeats** | Library of local run-history echoes | Previous death cause replay / book tornado / memory stamp | At 50% calls one safe-scaled enemy echo from a past run | Replay is telegraphed and never copies impossible build loops | Defeat Archive |
| **Pocket Moon** | Small orbiting moon in giant greenhouse | Gravity shove / lunar beam / crater volley | At 60% splits into two smaller moons with separate cues | Stay in neutral overlap and hit bright crater | Pocket Crater |
| **The Nap King** | Enormous bed in ruined palace | Pillow slam / snore cloud / dream clones | At 40% wakes up, moving much faster but with short naps | Destroy alarm clock during wake animation | Nap Crown |
| **Director of Spores** | Fungal theater with stage left/right | Mushroom actors / spotlight spore / knife curtain | At half HP opening curtain reveals giant vulnerable bulb | Use stage wing safe lane; cut curtain cord | Director’s Cap |
| **The Unsolicited Advice** | Living speech bubble in astral sky | Dialogue box projectile / contradictory arrow / opinion tornado | At 50% text becomes shorter but tells remain shape-coded | Choose displayed safe choice, punish after final punctuation | Opinion Eraser |
| **The Unfinished Run** | Mirror floor using one archived build snapshot | Adapted player weapon echo / ground slam / item proc display | At half HP drops copied relic effects and fights with base kit | Counter your own known weapon; proc copies capped strictly | Run Fragment |
| **The Garden After Midnight** | Everything looks cozy but all furniture is hostile | Furniture dash / lamp beam / blanket pull | At 40% furniture forms one gigantic stomping greenhouse | Bait stomp into fountain, hit exposed door hinge | Midnight Key |

## 35. Authored rooms — 56 modular set pieces

These are hand-authored **room archetypes** that the procedural assembly system rotates, decorates, connects and populates. Every entry needs door anchors, spawn anchors, terrain collision map, cover zones, lighting, acoustic cue, hazard slots and automated reachability validation. Add mirrored/rotated versions only when attack telegraph consistency survives. The procedural generator should have further variants beyond these 56 via furnishings, side-objectives, elite placements and hidden routes.

### Forgotten Garden — 8 rooms

| Room | Walkable layout / unique gameplay |
|---|---|
| **Petal Courtyard** | Four flowerbeds create safe side lanes; root traps at cardinal points. |
| **Broken Fountain** | Central cover allows boss-like projectile dodges; fountain can dry up. |
| **Hedge Maze** | Small U-shaped walls; two visible exits; flanker paths never enclosed. |
| **Sunken Greenhouse** | Three glass panels break and change projectile line-of-sight. |
| **Compost Bridge** | One safe narrow bridge and two optional risky detours. |
| **Picnic Disaster** | Animated food props; one table can be pushed as shield. |
| **Flowerbed Siege** | Two Garden enemy waves with between-wave rest reward. |
| **The First Gate** | Story mural, seed choice, optional nearby miniboss path. |

### Mushroom Kingdom — 8 rooms

| Room | Walkable layout / unique gameplay |
|---|---|
| **Fungal Crossroad** | Bioluminescent caps mark three choice doors with distinct hazards. |
| **Spore Nursery** | Puffballs placed as redirectable explosives around chests. |
| **Knife Orchard** | Visible mushrooms conceal safe wall holes; charge counterplay. |
| **Glowpool** | Stepping pads over shallow toxic ground; pads never vanish unexpectedly. |
| **Queen’s Pantry** | Fungal merchant stalls with safe commerce zone. |
| **Mycelium Bridge** | Bridge length changes between waves, validated safe width. |
| **The Gilled Choir** | Spore bells fire in sequence; one optional reward bell. |
| **Royal Audience** | Pre-boss antechamber with readable giant cap shadows. |

### Clockwork Conservatory — 8 rooms

| Room | Walkable layout / unique gameplay |
|---|---|
| **Clockface Atrium** | Floor sectors fire by hour; safe wedges persist every beat. |
| **Gear Orchard** | Rotating cogs open and close cover, no fully sealed exits. |
| **Brass Lift** | Platform rises one tile between short waves, with clear pause. |
| **Greenhouse Rails** | Carts traverse three marked rails; enemies can be run over. |
| **Steam Pantry** | Vent switches can be activated to clear attack lane. |
| **Ticking Nursery** | Clockwork saplings grow into enemies only if ignored. |
| **Lost Workshop** | Blueprint chest surrounded by optional timing challenge. |
| **Bell Tower** | Climbing illusion on flat 2D plane; rhythmic bell attack. |

### Bloodbloom Forest — 8 rooms

| Room | Walkable layout / unique gameplay |
|---|---|
| **Redroot Corridor** | Four rooted barriers contract and expand with visible warning. |
| **Moonlit Clearing** | Open fighting area with three stable cover trunks. |
| **Leech Pond** | Drain pools have obvious clean lily pads. |
| **Poppy Cathedral** | Flowers pulse Drowsy; their center can be disabled. |
| **Widow Crossing** | Web lines can be cut to make alternate navigation routes. |
| **Antler Path** | Directional stomp lanes; strong enemy charges can open shortcuts. |
| **Candle Grove** | Burning candles clear blood fog but make nearby enemies aggressive. |
| **Weeping Altar** | Optional max-HP sacrifice for single special reward. |

### Hollow Palace — 8 rooms

| Room | Walkable layout / unique gameplay |
|---|---|
| **Broken Ballroom** | Mirror panels reflect visually outlined projectiles. |
| **Royal Kitchen** | Hot soup hazards, breakable counters, knife-shroom crossover event. |
| **The Long Table** | Sliding chairs shift cover but never trap player. |
| **Chandelier Hall** | Ceiling lights cast large danger markers before dropping. |
| **Lost Library** | Animated books offer two text choices and a hidden bookshelf. |
| **Velvet Stage** | Curtain attacks fill edges, center remains readable. |
| **Guest Rooms** | Four small chambers connected by doors for short explorations. |
| **Final Tea Table** | Intimate arena with three distinct safe routes around giant table. |

### Astral Greenhouse — 8 rooms

| Room | Walkable layout / unique gameplay |
|---|---|
| **Starfield Patio** | Decorative stars behind map; projectiles have distinct high-contrast colors. |
| **Orbit Chamber** | Two rotating rings with wide safe paths. |
| **Glass Bridge** | Transparent bridge tiles reveal fall zones before arming. |
| **Zero Gravity Bed** | Brief low-gravity movement modifies acceleration, not collision reliability. |
| **Constellation Conservatory** | Line diagrams telegraph attack pathways in sequence. |
| **Lunar Aquarium** | Floating drops move through room; no obscuring particle haze. |
| **Black Flower Planetarium** | Void pull wells have clear escape vectors. |
| **Moon Orchard** | Two moon statues create alternating safe halves. |

### Bloomheart Core — 8 rooms

| Room | Walkable layout / unique gameplay |
|---|---|
| **Memory of Home** | Ruined Garden hub architecture, safe central flower path. |
| **Five Portrait Hall** | Five recognizable faux-hero attack stations with clear labels. |
| **Broken Promise Bridge** | Two walkable choices merge after different narrative event. |
| **Wish Machine Vault** | Four interactive flower generators supply room hazards. |
| **Little Goodbye** | Brief no-combat chamber with optional character dialogue. |
| **Rooted Atrium** | Corrupted arches shift but guarantee clear passage. |
| **Almost Home** | Pre-capstone shrine, full warning and run summary. |
| **The Bloomheart** | Final multi-phase circular arena with safe core breakpoints. |

## 36. Procedural choice events — 84 biome-specific event cards

Events are short text moments *inside a walkable dungeon*, not a replacement for gameplay. Most present two choices with different tactical consequences; the player sees the **type and upper bound** of the risk before selection. Some have a small timing puzzle or combat detour. Each event requires location, character-specific one-liners, two unique selection illustrations, deterministic RNG state, persistent resolution and coherent in-world object sprite. No event should remove a completed run through an invisible random instant-kill.

### Forgotten Garden — 12 events

| Event | Option A / consequence | Option B / consequence |
|---|---|---|
| **The Sulking Statue** | Compliment the statue: gain small Guard boon, pay 10 Petals | Ignore: nothing, statue mutters. |
| **Garden Tax Form** | Sign: gain rare chest, spawn tax collector later | Tear: gain Petals now, receive a tiny curse. |
| **Empty Watering Can** | Fill with HP: convert loss to a bloom healing later | Leave dry: get free common Petals. |
| **The Pruning Contest** | Trim vines: timed safe minigame, relic if successful | Skip: save HP and time. |
| **A Very Tiny Grave** | Plant flower: spend one Seed for codex cosmetic | Read marker: reveal hidden room clue. |
| **Angry Picnic Basket** | Open: fight food mimic for Epic chance | Walk away: recover tiny stamina. |
| **The Blue Gate** | Challenge guard: elite encounter plus weapon choice | Take side road: ordinary fight and no weapon. |
| **Sleeping Root** | Step across: shortcut but root may wake with clear tell | Water: pay Petals for safe route. |
| **Polite Hedge** | Ask to pass: give one small item for safe lane | Cut: enter thorn challenge, loot premium. |
| **Fountain of Should-Have-Known** | Drink: heal and take visible random minor curse | Bottle: gain one consumable, no instant heal. |
| **Petal Thief’s Apology** | Forgive: unlock optional friendly merchant once | Fight: reclaim Petals and gain riskier loot. |
| **The Door Named Door** | Knock: reveal silly dialogue and choose chest | Kick: spawn two enemies but save route key. |

### Mushroom Kingdom — 12 events

| Event | Option A / consequence | Option B / consequence |
|---|---|---|
| **Cap Inspection** | Inspect cap: identify mimic and take safe item | Eat cap: temporary damage buff plus poison. |
| **Truffle Exchange** | Trade rare spore: buy class relic discounted | Keep spore: later evolution ingredient. |
| **Lost Knife** | Return: Knife Shrooms become less aggressive for room | Keep: gain Butter Knife variant, elite ambush next room. |
| **Sporing Wedding** | Dance: rhythm test grants cosmetic cape | Leave: gain healing mushroom from guest. |
| **Fungus Census** | Count caps: answer puzzle for map reveal | Skip: fight short fungal wave for coins. |
| **Royal Mushroom Tax** | Pay Petals: bypass bad guard | Refuse: face Royal Taste Tester elite. |
| **The Suspicious Omelet** | Eat: heal and roll small bonus or Drowsy | Sell: take safe Petals. |
| **Mossy Elevator** | Ride: shortcut with surprise challenge | Climb: ordinary route and guaranteed chest. |
| **Spore Poet** | Recite: gain Ink/Focus boon depending hero | Heckle: spawn Cursed Morel for high reward. |
| **Blue Mushroom Fork** | Take blue path: frost hazard, better relic | Take green path: poison hazard, more Petals. |
| **Sleeping Mycelium** | Tiptoe: avoid all enemies but forfeit drop | Stomp: awakened enemy wave, rare chance. |
| **The Moldy Crown** | Try on: elite crown boon and curse | Polish: cash reward, no curse. |

### Clockwork Conservatory — 12 events

| Event | Option A / consequence | Option B / consequence |
|---|---|---|
| **Clock Repair** | Spend gears: repair clock for ability cooldown boon | Smash clock: gain salvage and summon guardian. |
| **Time Lost Counter** | Trade active time score: unlock timepiece codex | Keep time: gain short attack speed buff. |
| **The Wrong Bell** | Ring: spawn one timed challenge with Legendary chance | Stay silent: receive one small clock seed. |
| **Stuck Conveyor** | Oil gears: gain moving platform shortcut | Push through: small trap room with coin reward. |
| **Mechanical Rose** | Water: bloom Rose relic choice | Overwind: rare metal weapon, extra hazard. |
| **Copper Choir Audition** | Play rhythm: win summon relic | Decline: listen to hint about boss timing. |
| **The Rewinder** | Undo one noncombat purchase for fee | Keep receipt: next shop discount. |
| **Old Engineer’s Diary** | Read: reveal dangerous bonus room | Burn: get safe heat protection for three rooms. |
| **Lost Spring** | Install: one extra dodge charge but reduced damage | Sell: cash and no mechanics. |
| **Glass Ceiling** | Break: expose treasure and awaken birds | Leave intact: use cover in next room. |
| **Robot Date** | Help lost construct: gain a tiny companion | Scrap: resource and possible elite anger. |
| **Perfect Timing** | Attempt hard timed crossing for two relic offers | Take marked safe bridge for one common reward. |

### Bloodbloom Forest — 12 events

| Event | Option A / consequence | Option B / consequence |
|---|---|---|
| **Weeping Flower** | Comfort: spend some HP to cleanse Corruption | Harvest: gain Bleed relic, gain Corruption. |
| **Red Ribbon Tree** | Tie vow: gain resistance at next boss | Cut ribbon: cashout plus aggressive enemies. |
| **The Quiet Fox** | Follow: hidden trail to risky chest | Feed: safe fox charm consumable. |
| **Leech Doctor** | Donate blood: max HP down, strong lifesteal | Refuse: take antidote sample. |
| **The White Stag** | Bow: peaceful buff to Focus/Resolve | Hunt: elite challenge with unique antler relic. |
| **Heartwood Confessional** | Tell truth: lose one curse, lose some Petals | Lie: gain Petals, add named Hex. |
| **Mourning Picnic** | Eat red cake: heal then apply delayed Drowsy | Take box: healing consumable for future. |
| **Ashen Lantern** | Light it: reveal ambushers, attract one elite | Carry unlit: longer map visibility but no fight. |
| **Bloodbloom Seed** | Plant: garden hub cosmetic after run | Crush: short powerful Burn/Thorn buff. |
| **The Last Dance** | Dance: dodge rhythm challenge for relic | Walk: gain small safe heal. |
| **Crimson Bargain** | Surrender one item: choose better cursed item | Leave: retain inventory. |
| **Widow’s Thread** | Snip: remove one trap ahead, spawn hunter | Weave: obtain tripwire consumable. |

### Hollow Palace — 12 events

| Event | Option A / consequence | Option B / consequence |
|---|---|---|
| **The Empty Seat** | Sit: receive short-rest meal, triggers silly quote | Stand guard: gain block charge instead. |
| **Tea Ceremony** | Sip: random disclosed tea blessing and drawback | Serve: earn porcelain relic, reduced heal. |
| **Royal Invitation** | Accept: duel optional miniboss, unique reward | Decline: common chest and no duel. |
| **Chandelier Insurance** | Sign: pay Petals for hazard shield once | Refuse: keep Petals, navigate marked danger. |
| **Book of Bad Manners** | Read: obtain one random useful trap recipe | Rip page: immediate power, hex. |
| **Broken Mirror** | Polish: find true portrait and reveal shop | Smash: gain shards, summon Mirror Moth. |
| **The Last Cupcake** | Eat: gain large healing with short slowdown | Offer: earn helpful teapot pet. |
| **Crownless Tailor** | Tailor costume: unlock cosmetic outfit | Sell robe: gain relic offer but lose cloth token. |
| **Dancing Furniture** | Join: movement challenge, speed relic | Hide: gain basic currency with no fight. |
| **Velvet Understudy** | Perform: mini-boss stage encounter | Leave stage: get safe scroll consumable. |
| **Missing Guests** | Search: reveal hidden elite and rare reward | Wait: gain temporary defense blessing. |
| **Poorly Worded Etiquette** | Answer polite: raise merchant favor | Answer rude: open cursed treasure route. |

### Astral Greenhouse — 12 events

| Event | Option A / consequence | Option B / consequence |
|---|---|---|
| **Moon Fountain** | Drink starlight: Ink/Focus refill and small Hex | Bottle starlight: rare spell consumable. |
| **The Two Suns** | Choose bright: more crit, less defense for floor | Choose dim: more defense, fewer Petals. |
| **Constellation Puzzle** | Link stars: room route reveal and relic | Ignore sky: receive small rest token. |
| **Orbiting Teapot** | Catch cup: precision challenge for tea familiar | Let orbit: gain safe lunar scrap. |
| **Event Horizon Sign** | Enter rift: bonus challenge plus forbidden chance | Walk around: guaranteed standard chest. |
| **Lost Astronaut Flower** | Rescue: gain companion petal, no treasure | Harvest: strong damage seed, Corruption. |
| **Gravity Switch** | Flip: alter next room gravity but double loot | Leave: ordinary next room. |
| **Star Map Vendor** | Trade map tokens for boss tell preview | Keep tokens for local codex art unlock. |
| **Black Hole Picnic** | Sit: heal and endure visible gravity minigame | Avoid: gain a small movement charm. |
| **The Unwritten Star** | Name it: choose one class-resource blessing | Forget it: reroll current relic choices. |
| **Moonphase Promise** | Accept: next boss modifier disclosed, reward elevated | Decline: keep normal route. |
| **Falling Wish** | Catch before landing: earn rare item, risky timed move | Let fall: harvest small safe Petals. |

### Bloomheart Core — 12 events

| Event | Option A / consequence | Option B / consequence |
|---|---|---|
| **The Familiar Bench** | Sit: hear class-specific memory and recover modest HP | Keep walking: earn resolve fragment. |
| **The Fifth Portrait** | Inspect: get hint for five-shadow attack pattern | Ignore: obtain one minor currency cache. |
| **Wish Machine Manual** | Read: reveal capstone weak node order | Burn: immediate offensive blessing, one Corruption. |
| **The Original Rose** | Take: unlock a personal ending dialogue choice | Leave: gain restorative blossom. |
| **A Letter Unsent** | Open: discover next run secret sidequest | Seal: gain small class-resource refill. |
| **The Home Key** | Use: safer room path with less loot | Keep: risk elite detour for Legendary chance. |
| **Blanket Fort** | Build: spend Petals to create safe rest cover | Ignore: carry Petals forward. |
| **The Fourth Vow** | Choose sacrifice: gain giant short boon, max HP down | Choose patience: short defensive boon. |
| **Tiny Birthday Cake** | Eat: heal before final arena | Save: unlock Garden cosmetic after win. |
| **Forgotten Footsteps** | Follow: optional Echo miniboss | Resist: obtain stable map clue. |
| **Five Paper Lilies** | Fold: choose one unlocked hero blessing | Scatter: random mixed-biome reward chest. |
| **The Door to Home** | Enter: commit to capstone with preview | Turn aside: one final high-risk challenge room. |

### Cross-biome event cards — 16

| Event | Option A / consequence | Option B / consequence |
|---|---|---|
| **Angela’s Suspicious Statue** | Kiss statue: choose class boon, trigger funny Angela line | Refuse: harmless pout, optional small trade later. |
| **The Missing Sandwich** | Eat: safe small heal and sandwich costume clue | Offer to monster: reveal peaceful bypass. |
| **Merchant’s Cat** | Pet: lower price of one displayed item | Ignore: merchant remains normal. |
| **Lucky Bathroom Break** | Rest: pause-safe effect and small recovery | Leave: keep fast-run bonus. |
| **Unlabeled Potion** | Inspect: pay Petals to identify effects | Drink blind: roll from bounded disclosed effect pool. |
| **The Unfair Contract** | Sign: one Forbidden relic, one severe named curse | Decline: receive common consumable. |
| **Pigeon With a Letter** | Read: hidden Garden story and map hint | Trade: one rare ingredient for courier boon. |
| **Unreasonably Large Door** | Knock: random mini-room with preview of hazard type | Shrink: pay Petals to enter loot-only alcove. |
| **Room of Complaints** | Complain: restore class resource; enemies gain haste next room | Stay polite: get small temporary armor. |
| **A Coin That Screams** | Pick up: more Petals, louder enemy aggro | Leave: unlock harmless codex joke. |
| **Five-Color Flower** | Touch petal of chosen hero color for tailored boon | Burn plant: one area bomb, no boon. |
| **The Refund Desk** | Return one purchased item for partial Petals | Keep purchases, gain small store loyalty buff. |
| **A Very Honest Mimic** | Open: fight mimic with disclosed gear reward | Feed: spend consumable to receive one random charm. |
| **Garden Reunion** | Help sleeping echo: unlock one short story | Wake echo: optional fair duel and rare gear. |
| **Secret Screenshot Spot** | Pose: local photo-mode screenshot if platform supports | Leave: earn tiny stylishness score for run. |
| **The Afterparty** | Accept: face a boss remix for huge choice reward | Go home: bank normal clear and finish run. |

## 37. Elite mutation library — 36 illustrated affixes

Every mutation adds a recognizable silhouette accessory **and** one mechanical change; these 36 can be applied to compatible base species to generate a large but *legible* encounter space. Do not combine two mutations until the compatibility checker validates the composite and its telegraph density. Elite names can be generated as `Mutation + Species`, but codex descriptions must explain the real modified behavior. Mutations are not counted as new species in the bestiary.

| # | Affix | Behavior and visual cue | Safety/stacking condition |
|---|---|---|---|
| 01 | **Thorn Crown** | Counterattack leaves one thin thorn crescent; violet thorn crown. | No on-hit reflect loops. |
| 02 | **Volatile** | Enemy corpse displays fuse then bursts in small ring; orange heart icon. | Never spawns under hero without escape. |
| 03 | **Mirrored** | One faint decoy repeats non-damaging move; mirrored eye. | True body has ground shadow. |
| 04 | **Royal** | Extra deliberate swing before recovery; tiny gold crown. | Extra attack always telegraphed. |
| 05 | **Briarfoot** | Leaves short-lived thorns while walking; root shoes. | Caps ground coverage. |
| 06 | **Doubletime** | Faster movement with unchanged readable windup; two clock hands. | Only compatible enemies. |
| 07 | **Icethorn** | Hit adds Chill; blue thorn trim. | Freeze resistance respects player immunity. |
| 08 | **Siphoning** | Deals small life steal on landed hit; red flask. | Cannot heal from blocked attack. |
| 09 | **Beacon** | Nearby foes gain aim hint; glowing lantern head. | Link breaks on death. |
| 10 | **Withered** | Lower HP but more rapid projectile count; dried flower. | Projectile density cap. |
| 11 | **Bulwark** | One frontal armor segment that breaks on heavy hit; stone shoulder. | Back exposed clearly. |
| 12 | **Burrowing** | Can move underground before alert, visible soil trail; shovel emblem. | No teleport directly onto hero. |
| 13 | **Sporebound** | Death releases slow Drowsy cloud; fungal halo. | Cloud outline visible first. |
| 14 | **Gold-Plated** | Drops more Petals and summons one tax minion; gold shell. | Only one minion alive per elite. |
| 15 | **Hush** | Spell projectile quieter, tell brighter; mute bell icon. | Audio not primary tell. |
| 16 | **Charged** | Attacks apply Conductive with small arc; lightning antenna. | Chain target cap. |
| 17 | **Lanterned** | Creates rotating bright cone and reveals stealth; lantern. | Cone safe sectors maintained. |
| 18 | **Heavyweight** | Pushes harder and moves slowly; enormous boots. | Stagger threshold more generous. |
| 19 | **Clockwork** | Attacks always at metronome beat; ticking gear. | Beat preview in HUD. |
| 20 | **Skittish** | Flees after hit then returns via predictable arc; tiny whiskers. | No unreachable offscreen stalls. |
| 21 | **Summoner** | Calls one allied tiny species at threshold; little nest. | Spawn quota enforced. |
| 22 | **Splitcap** | Death splits into two weak non-elites; mushroom split. | No recursive splitting. |
| 23 | **Prismatic** | Alternates two visibly signaled elements; rainbow visor. | Element symbols accessible without color. |
| 24 | **Echoing** | Repeats first attack after a delay with weaker hitbox; sound ripple. | Do not duplicate screen-filling attacks. |
| 25 | **Shy Shield** | Shield activates when looked at and drops when flanked; blushing visor. | No instant turning. |
| 26 | **Berserk** | Below 35% HP adds one move and changes expression; red band. | Keeps windups readable. |
| 27 | **Luminous** | Creates visible safe light zone while damaging outside ring; sun crown. | Safe zone width valid. |
| 28 | **Gambler** | On defeat offers one risky bonus chest with optional accept; dice hat. | Risk disclosed before opening. |
| 29 | **Hollow** | Briefly phases through walls on path, but emerges at fixed gate. | Cannot hit while intangible. |
| 30 | **Scholar** | After observing player attack, counters that attack type once; spectacles. | Counter telegraph long and clear. |
| 31 | **Royal Guard** | Grants allied enemy one frontal shield pulse; shield crest. | No infinite mutual shields. |
| 32 | **Frostbite** | Creates small delayed icy floor on dash; snow petals. | Ice impact tile marked. |
| 33 | **Vengeful** | One last weak attack after HP zero before fade; angry mask. | Loot appears after final attack. |
| 34 | **Pacemaker** | Accelerates one ally for six seconds, then tires; pulse heart. | Only one pacemaker aura. |
| 35 | **Trickster** | Swaps places with compatible nearby ally after a sparkle; swap mask. | No swap during uninterruptible hero attack. |
| 36 | **Blooming** | Every fourth attack adds one flower projectile; petal halo. | Per-room projectile cap. |

## 38. Endless mutator library — 48 compatible floor-rule modifiers

The director chooses **1–3 mutators** for most Endless stages and sometimes a special boss contract. Show all active modifiers in a floor preview, including hazard icon, strategic implication and reward multiplier. Build a compatibility matrix with hard constraints on map coverage, timing, control interference and simultaneous projectiles; some combinations are outright forbidden. Ensure generated rules work offline and survive save/reload deterministically.

| # | Mutator | Rule and player-facing promise |
|---|---|---|
| 01 | **Mimic Season** | Some ordinary-looking chests visibly breathe; increased reward when defeated. |
| 02 | **Double Boss** | Two coordinated bosses at reduced damage; never two overlapping screen-wide attacks. |
| 03 | **No Free Healing** | Rest rooms sell healing instead; at least one recoverable option retained. |
| 04 | **Volatile Corpses** | Death explosions appear after unmistakable fuse. |
| 05 | **Long Shadows** | All movement shadows stretch and telegraph ambushers earlier. |
| 06 | **Triple Loot, Tougher Elites** | Elite attacks gain one move; three curated rewards after victory. |
| 07 | **Poison Rain** | Timed patterned poison drops, with consistent safe tiles. |
| 08 | **Fast Clock** | Clockwork enemies quicken movement, windup minimum unchanged. |
| 09 | **Cursed Bargains** | More altars; each offer has stronger power and clearer downside. |
| 10 | **Brittle Armor** | Both hero and enemies stagger easier; bosses have stagger caps. |
| 11 | **Big Heads** | Sprites gain silly oversized heads, collision never changes. |
| 12 | **One Safe Lantern** | Darkened room except one movable light; danger tells remain visible. |
| 13 | **Exploding Money** | Uncollected Petals burst after audible countdown; can collect safely. |
| 14 | **Sticky Shoes** | Movement has slightly more inertia, dodge independent. |
| 15 | **Heroic Hiccups** | Every fourth skill leaves a harmless animation hiccup and brief burst. |
| 16 | **Knife Appreciation** | All fungi spawn with prop knives; only actual Knife Shrooms deal knife attacks. |
| 17 | **Broken Compass** | Minimap reveals one step less; doors remain visible in room. |
| 18 | **Broken Mirror World** | Map mirrored left-right, controls are NOT reversed. |
| 19 | **Petal Parade** | Slow petal storm moves through center, concealing no telegraphs. |
| 20 | **Big Game Hunting** | More elite hunters, fewer normal foes, stronger drops. |
| 21 | **Boss Encore** | Boss gets one new attack after each phase; significant reward. |
| 22 | **Chilly Evening** | Floor has slippery patches, hero and enemies subject to same rules. |
| 23 | **Tea Time** | Periodic tea circles appear as neutral temporary safe zones. |
| 24 | **Midnight Market** | Shops appear more often, prices higher; occasional free sample. |
| 25 | **Pollen Allergy** | Poison clouds dissipate faster but arrive more often. |
| 26 | **Silent Alarm** | Enemy sound cues reduced, visual and haptic tells enhanced. |
| 27 | **Counterclockwise** | Directional rotating traps turn opposite, warned on floor entrance. |
| 28 | **One Extra Door** | Every floor has one additional optional route with escalating danger. |
| 29 | **Noisy Garden** | Aggro radii rise, enemies use slightly slower attack speed. |
| 30 | **Long Corridor** | Rooms longer, fewer simultaneous ranged projectiles. |
| 31 | **Glass Floor** | Cover is fragile but reveals weak points through walls. |
| 32 | **Fungal Embassy** | Mushroom species can visit another biome with proper assets. |
| 33 | **Overgrown Palace** | Gardens bloom through palace floors; mixed thorn/chandelier traps. |
| 34 | **Clockwork Orchard** | Gear species mix with root hazards and coherent visual tiles. |
| 35 | **Astral Pollen** | Projectiles occasionally curve around glowing gravity seeds. |
| 36 | **Last Chance Deal** | At low HP, one high-risk healing offer appears per boss floor. |
| 37 | **Royal Inspection** | Merchant appears as optional elite challenger before shop. |
| 38 | **Petal Debt** | Start stage with an indicated small debt; earn more loot if repaid. |
| 39 | **Three Times Charming** | Exactly three obvious charm shrines per ten floors; one cursed. |
| 40 | **The Floor Is Cake** | Floor dessert tiles are slippery, no hidden damage. |
| 41 | **Friendly Fireworks** | Occasional neutral fireworks can hit both enemies and hero, radius marked. |
| 42 | **Slow Motion Moment** | After perfect dodge, local actors briefly slow; preserves physics tick. |
| 43 | **Duelists Only** | Elite composition favors fewer stronger close-range enemies. |
| 44 | **Garden Swarm** | More tiny enemies with lower HP; active enemy cap respected. |
| 45 | **Overtime** | Long battles cause gradual reinforcement capped per room. |
| 46 | **Bounty Board** | Specific enemy species worth bonus loot on this floor. |
| 47 | **Theatre Mode** | Enemy entrances get dramatic 0.5-sec poses without invulnerability exploit. |
| 48 | **The Bad Bloom** | Two unrelated biome hazards combine under compatibility validation. |

## 39. Environmental hazard library — 42 authentic mechanics

Each hazard gets: art layer, animation, affected faction policy, activation timing, visual/sound warning, collision masks, save state, per-floor pool tag, and at least one active countermeasure. Environmental danger should create interesting positioning decisions, not randomly chip unavoidable HP.

### Botanical — 7 hazards

| Hazard | Active rules |
|---|---|
| **Snap Vine** | Two-frame windup opens a short lane bite. |
| **Thorn Carpet** | Ground grows spikes in marked squares after timer. |
| **Root Grapple** | Root reaches from soil shadow and grabs for brief snare. |
| **Pea Turret** | Neutral plant fires into fixed cone on beat. |
| **Hedge Collapse** | Hedge falls, changing line-of-sight and routes. |
| **Flower Burst** | Blossom pops after swelling animation. |
| **Pollen Gust** | Wind blows particles and slows crossing arrows. |

### Fungal — 7 hazards

| Hazard | Active rules |
|---|---|
| **Spore Vent** | Vent pulses pale green rings with poison outline. |
| **Puff Fuse** | Puffball detonates with a persistent radius marker. |
| **Slippery Moss** | Movement slides at readable edge tile. |
| **Mycelium Bridge** | Bridge grows/shrinks between combat waves. |
| **Luminous Decoy** | Fake heal mushroom flashes tell before exploding. |
| **Rot Pool** | Short-lived toxic puddle with clean lily pad. |
| **Gilled Bell** | Mushroom chime causes an area Drowsy wave. |

### Mechanical — 7 hazards

| Hazard | Active rules |
|---|---|
| **Clock Sector** | Arc advances by one clock segment each beat. |
| **Gear Rail** | A gear rotates along fixed readable track. |
| **Steam Piston** | Piston extends after valve whistle. |
| **Conveyor Belt** | Floor moves actor at stable capped speed. |
| **Glass Shatter** | Panel glints then breaks into small tiles. |
| **Metronome Laser** | Line fires only on every second beat. |
| **Bell Weight** | Heavy clock weight drops onto target marker. |

### Bloodbloom — 7 hazards

| Hazard | Active rules |
|---|---|
| **Lifedrain Petal** | Standing on crimson flower slowly drains, explicit edge. |
| **Crimson Thread** | Two thorns link into severable line. |
| **Sobbing Root** | Root emits wave after audible sob. |
| **Leech Slick** | Short puddle temporarily slows healing. |
| **Scarlet Lantern** | Lantern brightens warning of next ambush. |
| **Blood Mist** | Fog reduces distant view but never hides urgent hitbox. |
| **Antler Lane** | Ground antlers push actors when sprouting. |

### Palace — 7 hazards

| Hazard | Active rules |
|---|---|
| **Falling Chandelier** | Shadows outline fall ellipse in advance. |
| **Boiling Tea** | Marked steam circle bursts from floor. |
| **Mirror Ray** | Ray reflects at one known orientation. |
| **Dance Tiles** | Tiles change safe/danger on ballroom beats. |
| **Flying Saucer** | Neutral saucer returns along same boomerang arc. |
| **Curtain Pull** | Side walls shift toward room center slowly. |
| **Table Slide** | Covered table crosses predetermined rails. |

### Astral — 7 hazards

| Hazard | Active rules |
|---|---|
| **Gravity Well** | Pull direction shown by orbit arrows. |
| **Starfall** | Falling star has long impact marker. |
| **Portal Pair** | Objects move between two clearly linked entrances. |
| **Orbit Laser** | Ray rotates with a visible safe wedge. |
| **Moonphase Floor** | One half safe and one hazardous, swaps on chime. |
| **Void Bloom** | Flower expands a dark ring and leaves central safe zone. |
| **Meteor Bell** | Bell telegraphs falling comet sequence. |

## 40. Inventory objects — 30 consumables and 30 charms

Consumables are tactile choices with limited stack count, visible effects and no remote requirement. Charms are lighter-slot passive items that provide small utility or set progress without replacing relics. A permanent inventory reference lists icon, rarity, description, tags, max stack, vendor price, drop pool and effect hook. Keep manual use touch-accessible and never auto-consume rare items without a setting.

### Consumables — 30

| # | Item | Behavior | Type |
|---|---|---|---|
| 01 | **Dew Tea** | Recover 20–30% max HP, capped per run. | `heal` |
| 02 | **Fungal Antidote** | Remove Poison and prevent reapplication briefly. | `cleanse` |
| 03 | **Rose Hemostat** | Remove Bleed and gain short armor. | `cleanse` |
| 04 | **Pocket Campfire** | Plant safe warm fire; burn nearby slime. | `utility` |
| 05 | **Smoke Bomb** | Break target tracking for short window. | `dodge` |
| 06 | **Clockwise Tonic** | Short movement and recovery buff with clear icon. | `haste` |
| 07 | **Starpop Grenade** | Thrown star explosion with marked radius. | `bomb` |
| 08 | **Petal Bomb** | Small physical explosive knocks weak foes. | `bomb` |
| 09 | **Spore Basket** | Places a delayed fungal poison mine. | `trap` |
| 10 | **Emergency Umbrella** | Block one frontal projectile within short timer. | `guard` |
| 11 | **Flask of Frost** | Freeze a small floor patch, enemy slow; boss cap. | `frost` |
| 12 | **Firecracker Lily** | Burns one direction and alerts remaining enemies. | `fire` |
| 13 | **Fortune Cookie** | Reveal one route branch before choosing. | `map` |
| 14 | **Silly Sandwich** | Small heal with goofy character idle animation. | `heal` |
| 15 | **Paper Key** | Open one special locked common cache. | `key` |
| 16 | **Royal Teacup** | Restore class resource to moderate value. | `resource` |
| 17 | **Spare Ribbon** | Recover one placed trap charge. | `trap` |
| 18 | **Tiny Compass** | Show nearest unrevealed non-boss room. | `map` |
| 19 | **Dandelion Parachute** | Negate one fall-style hazard, not damage broadly. | `defense` |
| 20 | **Mushroom Soup** | Heal and grant Drowsy for a short warning period. | `risk` |
| 21 | **Thorn Bait** | Attract nearest weak foe into prepared trap. | `control` |
| 22 | **Pigeon Letter** | Deliver a small guaranteed merchant discount later. | `economy` |
| 23 | **Glitter Grenade** | Reveal invisible ambushers in visible radius. | `reveal` |
| 24 | **Dream Bottle** | Briefly reduce enemy alert range. | `stealth` |
| 25 | **Iron Petal** | Protect against one Guardbreak. | `guard` |
| 26 | **Star Compass** | Change one optional Endless mutator offer. | `endless` |
| 27 | **Seed of Return** | Mark one room to revisit via legal door graph. | `travel` |
| 28 | **Cursed Marmalade** | Apply strong melee buff and one disclosed minor curse. | `curse` |
| 29 | **Rose Seedling** | Plant delayed healing flower in rest/clear room only. | `heal` |
| 30 | **Emergency Apology** | Reset nearby enemies to windup after one major stun; once per stage. | `panic` |

### Charms — 30

| # | Charm | Passive behavior |
|---|---|---|
| 01 | **Amber Hairpin** | Tiny Resolve gain on perfect guard. |
| 02 | **Platinum Rose** | Tiny Ink gain after third unique spell. |
| 03 | **Orchid Ribbon** | Tiny Momentum boost after combo clear. |
| 04 | **Camellia Clip** | Tiny Focus gain after precision dodge. |
| 05 | **Iris Paint Pin** | Tiny Color gain on alternating dagger hit. |
| 06 | **Pocket Flower** | Increases item pickup radius slightly. |
| 07 | **Crown Sticker** | Shows elite role on hover/tap. |
| 08 | **Tiny Clock** | Displays local attack rhythm cue. |
| 09 | **Glass Button** | Minor projectile size clarity, no hidden damage change. |
| 10 | **Merchant Coin** | One small shop discount per floor. |
| 11 | **Thorn Bandage** | Reduces first bleed tick. |
| 12 | **Sporesocks** | Reduces poison floor exposure window. |
| 13 | **Padded Shoes** | Slightly dampens knockback. |
| 14 | **Tea Pin** | Tea-rest healing slightly improved. |
| 15 | **Dandelion Charm** | Minor air-push resistance. |
| 16 | **Paper Shield** | One weak projectile block each chapter. |
| 17 | **Moon Egg** | Extra arcane resist but not invincibility. |
| 18 | **Worn Quill** | Residue duration slightly longer. |
| 19 | **Red Thread** | Dagger backstab mark lasts a fraction longer. |
| 20 | **Brass Leaf** | Small clockwork enemy awareness bonus. |
| 21 | **Broken Mirror** | Shows clone shadow contrast strongly. |
| 22 | **Lost Bouquet** | Enhances flowers in Rest room only. |
| 23 | **Friendship Bead** | Slight companion lifetime boost, cap enforced. |
| 24 | **Shy Medal** | Tiny bonus after low-enemy-count rooms. |
| 25 | **Bent Spoon** | Increases knockback against tiny enemies. |
| 26 | **Moldy Button** | Tiny extra fungus drop chance. |
| 27 | **Star Map Pin** | Reveals current biome hazard guide. |
| 28 | **Tidy Notebook** | Remembers next elite weakness in codex. |
| 29 | **Safety Bell** | One extra audio cue for offscreen targeted hazards. |
| 30 | **Golden Thread** | Minor chance to preserve one shop coupon. |

## 41. Achievements and local goals — 50 hand-authored milestones

Achievements are purely local and never tied to external accounts, social features or daily wall-clock deadlines. Most grant cosmetics, codex lore, visible trophies, alternative starting choices or small build options; avoid large automatic permanent combat advantage. Popups cannot cover telegraphs. Add hidden achievements for amusing first discoveries and Endless feats. All progress survives save migration.

| # | Achievement | Trigger / objective |
|---|---|---|
| 01 | **One More Run** | Complete the first defeated run. |
| 02 | **Actually Offline** | Complete a boss entirely in airplane mode. |
| 03 | **Knight Shift** | Perfect-guard ten attacks in one run as Angela. |
| 04 | **One Last Poem** | Land a three-spell residue combo as Vivianne. |
| 05 | **Tiny Threat** | Defeat elite with a Nixia launch collision. |
| 06 | **Tidy Business** | Clear room using Virelia traps without taking damage. |
| 07 | **Color Theory** | Proc all three Zaria color statuses on one boss. |
| 08 | **Crownless** | Defeat any boss without equipping a relic. |
| 09 | **I Regret Nothing** | Accept five curses in one run and survive chapter boss. |
| 10 | **Mushroom Appreciation** | Defeat Moldy Majesty with mushroom-themed weapon. |
| 11 | **The Honest Hero** | Reject three suspicious bargain events in one run. |
| 12 | **The Accountant** | Collect 1,000 Petals across multiple runs. |
| 13 | **No Refunds** | Win a run without buying from merchant. |
| 14 | **A Good Hiding** | Find one hidden Garden route. |
| 15 | **The Fifth Flower** | Unlock all five playable heroes. |
| 16 | **The Bad Bloom** | Defeat the Bloomheart and see standard ending. |
| 17 | **Afterparty** | Defeat one optional boss remix. |
| 18 | **Dinner Is Served** | Win against Duchess using a teapot familiar. |
| 19 | **Perfect Timing** | Disable a clock hazard with exact beat interaction. |
| 20 | **Needle and Thread** | Trip three enemies with connected Virelia snares. |
| 21 | **Suplex Customer** | Launch a tiny foe into a miniboss with Nixia. |
| 22 | **Knight of Flowers** | Finish Angela run using guard/counter build. |
| 23 | **Paperwork** | Read 25 event cards. |
| 24 | **Unpaid Intern** | Defeat the Unpaid Intern in Endless. |
| 25 | **The Large Goose** | Beat The Very Large Goose without being honked into wall. |
| 26 | **Honk Honk** | Acquire Doom Feather. |
| 27 | **Garden Collector** | Discover 50 unique weapons. |
| 28 | **Bad Habit** | Discover 100 relic effects. |
| 29 | **Who Asked** | Defeat The Unsolicited Advice. |
| 30 | **Never Again** | Die to a Knife Shroom for the first time. |
| 31 | **Did It Again** | Die to a Knife Shroom in ten different runs. |
| 32 | **Oath of Blood** | Unlock Angela’s Bloodbride aspect. |
| 33 | **The Last Poet** | Unlock Vivianne’s Last Poet aspect. |
| 34 | **Root Administrator** | Unlock Nixia’s Root Administrator aspect. |
| 35 | **Warden of Camellias** | Unlock Virelia’s hidden specialist aspect. |
| 36 | **Final Masterpiece** | Unlock Zaria’s hidden artist aspect. |
| 37 | **Three Safe Steps** | Dodge three visible ground hazards consecutively. |
| 38 | **Briar Bride** | Trigger Wedding Day synergy. |
| 39 | **The Sixth Seat** | Find the secret chair chamber. |
| 40 | **First 100** | Reach Endless floor 100. |
| 41 | **First 500** | Reach Endless floor 500. |
| 42 | **First 1000** | Reach Endless floor 1000 with valid save. |
| 43 | **Run Historian** | Browse ten defeat records in local codex. |
| 44 | **No Battery Drama** | Suspend mid-run, resume later successfully. |
| 45 | **Curtain Call** | Defeat Madam Black Velvet. |
| 46 | **All Seasons** | Clear one full floor in each biome. |
| 47 | **Five Different Fates** | Clear a full run once with each heroine. |
| 48 | **The Royal Refusal** | Reject a Forbidden relic at a final altar. |
| 49 | **A Toast to Chaos** | Consume questionable potion during boss fight. |
| 50 | **A Garden Worth Keeping** | Unlock all cozy Garden hub decorations. |

## 42. Hub personalization, character relationship and comedy

### The Garden is a place, not a static menu

Five chibi characters wander between furniture while the player is in the hub. There is a fountain, tiny flowerbeds, a shared cozy table, archive shelf, weapons display, practice dummy, pet corner, secret door, merchant stand and decorative lily trees. Their conversation bubbles are short and can be skipped immediately. Each hero can be tapped for a few unique lines, idle gags and current-run reactions. Every decoration is optional and lightweight: if performance matters, idle NPC animation rates can drop.

**Hub interactables:** `Run Gate` (start or resume), `Roster Bench` (five playable heroes and cosmetics), `Weapon Arbor` (discoveries and starting loadouts), `Relic Archive` (relic catalog and synergy hints), `Merchant Cart` (unlocked starting conveniences), `Training Circle` (safe testing dummy), `Garden Journal` (lore, statistics, run history), `Seed Fountain` (meta unlock currency), `Pet House` (cosmetic companions), `Settings` (offline and accessibility controls).

**Visual micro-comedy examples:** Nixia shadowboxes a very tall plant; Angela pretends not to watch and then straightens a fallen lily; Vivianne sleeps on an open grimoire; Virelia measures spacing between pots with a tiny ruler; Zaria paints a mustache on the scarecrow, which objects. Characters must have recognizable silhouettes in every gag. Keep animation sequences short so touching menus remains responsive.

### Character voice design

Use short optional subtitles in Bahasa Indonesia and English. Store dialogue strings in localization files with interpolation tokens rather than hardcoded speech. No requirement for voice acting. Sample tone: Angela protective and prickly; Vivianne sleepy, poetic, quietly devastating; Nixia feral, smug and tiny; Virelia gentle, precise, unexpectedly firm; Zaria playful, artistic, chaotic. Avoid nonstop fourth-wall references; comedy should be surprising, not exhausting.

### Cosmetic progression

Skins: normal Garden outfits, winter scarves, tea party, knight ceremony, fungal raincoats, moon festival, pajama day, bloodbloom formalwear (still fully clothed), clockwork tailoring and silly cardboard armor. Cosmetics should keep canonical hair and face identity unless intentionally marked as transformation aspects; gameplay collision remains constant. Unlock through achievements, boss trophies and Garden Seeds; never through purchases or online passes.

## 43. Character ascensions and irreversible run decisions

Two alternate aspects exist for each hero: one built around expanding its base identity and one riskier supernatural or comic transformation. **Both are optional run discoveries**, not mandatory superior versions. Aspects affect posture, attack VFX, move set and dialogue; class readability remains intact. Exact transformation triggers must appear in the Codex as progressively revealed hints, not pure guesswork.

| Hero | Aspect A | Aspect A mechanics | Aspect B | Aspect B mechanics |
|---|---|---|---|---|
| Angela | **The Bloodbride** | Voluntary HP sacrifice, wounded sword range, kill-limited leech and dangerous burst ultimate | **The Sunwarden** | Shield lilies, safer reflected rays, protection over raw damage |
| Vivianne | **The Last Poet** | Max-HP for extreme spell glyph reach, forbidden endings and paper summons | **The Dawn Scribe** | Supportive cleansing verses, precision spell echoes, more mobility |
| Nixia | **Root Administrator** | Breach marks, perfect-combo lockdown and giant comic finishers | **Orchid Meteor** | Jump/landing impacts, devastating throw physics, less sustained combo |
| Virelia | **The Camellia Sovereign** | Extreme marked-target precision, triple-arrow finisher and delicate defense | **The Briar Cartographer** | Trap networks, route reveal, battlefield terrain shaping |
| Zaria | **The Last Masterpiece** | Three-color final attacks, crit art galleries, risky backstab bursts | **The False-Color Ghost** | Decoy painting, stealth reposition, status exchange and lower direct burst |

**Aspect activation rule:** required item family, a clean performance feat, an optional shrine/event and a revealed confirmation dialogue. No hidden permanent sacrifice should occur without explicit consent. Aspect art variations need portrait, gameplay sprite overlay, one transformation effect and optional victory pose. Never discard the five girls' canonical identities.

### Example run-only quest chains

- `The Missing Wedding Ring`: find ribbon → survive a vow altar → take guard challenge → unlock Angela's ring discovery.
- `Three Stanzas for Midnight`: locate three poetic fragments from different rooms → cast three element types → awaken Vivianne's rare verse.
- `Unauthorized Access`: beat three guard enemies with precise Nixia combos → confront a talking firewall door → unlock Root Administrator.
- `Camellia Arrangement`: place three different trap geometries and beat one precision room → reveal Briar Cartographer.
- `The Unfinished Portrait`: gather three colors and refuse one cursed canvas bargain → unlock Zaria's Masterpiece path.
- `A Very Bad Tea Party`: find two porcelain relics, defeat a teapot elite, then unlock secret Duchess remix.
- `Night of One Thousand Petals`: collect a seed from every biome without dying, open a late Garden shrine.
- `The Fallen Echo`: die with a unique curse weapon, then later meet its safe-capped Echo boss without duplicating exploit gear.
- `Chef's Regret`: use a ladle to defeat three food enemies, discover the absurd King of Napkins miniboss.
- `Starless Bloom`: defeat a high-tier astral encounter without using gravity assistance, unlock one special flower cosmetic.

More hidden quest chains should be added by Gemini, grounded in existing inventory, enemies and environments rather than arbitrary click combinations.

## 44. Economy, statistics and balance mathematics

### Run economy

- **Petals** are acquired from enemies, breakables, exploration, event choices and chests during a single run. They are lost on death. Use them in current-run merchants, healing, event negotiations, consumable purchases and a small number of rerolls.
- **Garden Seeds** are a separate permanent meta currency earned from genuine achievements, chapter milestones and run performance. They unlock item families, character aspects, cosmetics, training modules, alternate starting loadouts and Codex categories. Death should still yield modest Seeds but cannot be farmed by suiciding on the first room repeatedly.
- **Biome ingredients** are temporary run-bound catalysts (`spores`, `brass`, `thorn resin`, `porcelain`, `starlight`, `heartseed`), carried in a small limited pocket. They evolve class weapons at forge altars or enable special event choices.
- **Treasures** are collectible codex/lore records and cosmetics, not premium monetization. All content unlocks fully offline.

Suggested baseline Petal flow: normal room 5–16, elite room 15–40, treasure 12–45, boss 40–75, shop common 20–35, rare 45–80, healing 25–45, expensive rare 90+. These figures are **initial balance knobs**, not immutable promises. Runs should offer meaningful purchase decisions but not guarantee every build becomes complete. Item prices scale with chapter progression modestly, and money value does not explode into irrelevant millions in Endless. As depth increases, prices plateau and rare ingredients/quality decisions become the challenge.

Garden Seeds baseline: first new boss defeat 15–30, repeat boss defeat 5–12, chapter completion 8–20, clean challenge 5–15, first standard clear significant cosmetic/aspect unlock. Reward repeated learning but cap exploit loops. Expensive unlocks should require interesting goals instead of grinding hundreds of identical runs. No real-world spending.

### Suggested character baseline tuning matrix

| Stat | Angela | Vivianne | Nixia | Virelia | Zaria |
|---|---:|---:|---:|---:|---:|
| Starting HP | 125 | 80 | 100 | 95 | 90 |
| Armor (relative) | High | Very low | Medium | Low | Low |
| Speed (relative) | 0.94 | 1.00 | 1.09 | 1.00 | 1.13 |
| Basic reach | Short | Long | Very short | Long | Short/medium |
| Burst | Medium/high via parry | Very high setup | High sustained | High precision | High conditional |
| Crowd control | Shield push | Arcane area | Juggle | Traps | Decoys/bleed |
| Resource | Resolve | Ink | Momentum | Focus | Color Charge |

Values are starting hypotheses to playtest. All heroes must be able to complete every mandatory standard encounter without a lucky relic drop. Character-specific advantage is welcome; a missing fundamental capability is not. Ensure exact support for all five heroes in boss puzzles, event class checks, shop gear filters, and control profiles.

### Loot system — deterministic quality weighted picks

1. Build a candidate pool from biome, chapter, hero compatibility, progression unlocks and rarity budget.
2. Remove forbidden incompatibilities (e.g., summoning relic when summons disabled by player accessibility profile is not automatically forbidden unless it makes item ineffective; use effect descriptions).
3. Multiply rarity weights by chosen difficulty/challenge and pity counters **without** using hidden long-run paid incentives.
4. Draw at most three distinct reward candidates, using a separate seeded RNG stream for reward generation.
5. Reroll consumes Petals and advances the saved reward RNG once; cannot be exploited by reopening app.
6. Store item choice and selection in persistent run state before room exits are unlocked.
7. Display effect tags and activated synergies; avoid offering three functionally equivalent `attack +x%` options.

Suggested default rarity weights: Common 42%, Uncommon 28%, Rare 17%, Epic 9%, Legendary 3.5%, Forbidden 0.5%, then tune per source and challenge. Forbidden can appear via altars much more often than generic room drops because the player chooses risk. Show these probabilities in an optional Codex if precise odds are important to players. Keep agency through reward pools even when RNG is unlucky.

### Enemy threat and spawn cost

Assign base role costs: Swarm 1, Chaser 2, Shooter 3, Controller 3, Flanker 3, Shielded 3, Support 4, Summoner 4, Bruiser 5, Elite 7–12, Miniboss 14–24. A room can be assigned budget 6–10 early, 10–18 mid, 16–28 late, adjusted for stage and arena geometry. This is only a seed for test calibration. Check maximum active enemy count, ability projectile ceiling, available dodge lanes, maximum concurrent attack windups and buff loops before spawning. **A room with 10 cheap enemies can be more dangerous than a room with three expensive ones; use encounter composition heuristics, not sum alone.**

### Endless scaling

The Endless must not become enemies with 10^20 HP. Use difficulty plateaus: every 5 floors add one encounter composition variant or elite chance, every 10 offer a boss and player choice, every 20 introduce one authored remix or new mutator pairing, every 50 a major milestone and new reward/cosmetic or run record. Smooth small-stat scaling is allowed, but boss defense and enemy damage eventually approach soft caps while complexity continues to grow. The player can lose because they are overwhelmed by increasingly sophisticated combinations rather than arbitrary arithmetic overflow. Floor generation remains valid at huge integer indices; do not allocate arrays sized by floor number.

### Healing and fairness budget

Baseline healing opportunities appear at disclosed Rest/Shop/event intervals. Difficulty presets change resource scarcity or enemy composition, not essential control safety. No guaranteed full heal after every boss, but a player should never be forced into a 0% chance-of-survival room due solely to generator choices. The game can reward experienced players for carrying low HP into a dangerous challenge. Preserve the user's appetite for brutal roguelike stakes while making mistakes legible.

## 45. UI screen-by-screen production design

### Screen 01 — Title and boot

Opening animation: five tiny flowers sprout around the title **GARDEN: BAD BLOOM**, then one mushroom with a knife peeks from below the logo. Menu shows `Continue` when a valid run exists, `New Run`, `Garden`, `Collection`, `Settings`, `Credits`. First launch skips a long cinematic and immediately presents an intuitive path to play. The app boots fully in airplane mode without nagging permissions. Artwork has the illustration-sheet's pastel-dark fantasy composition but button contrast suitable for a real phone.

### Screen 02 — Garden hub

Top: current heroine/chosen portrait and local Seed balance. Center: friendly, lightly animated courtyard and five Garden girls. Bottom navigation: `Adventure`, `Roster`, `Arbor`, `Codex`, `Garden`. Interactables are real tappable objects with large invisible touch padding. Hub is touch-scrollable only when map camera design allows it; otherwise single-room screen. Users can pause small NPC movement to reduce distraction.

### Screen 03 — Hero selection

Five portrait cards with separate eyes/hair silhouette, hero name, class icon, HP bar, speed rating and resource emblem. Tapping a card shows short gameplay animation and two or three visible strengths/weaknesses; press `Select`, then choose available starting weapon/skin. Show more than just character portraits: `Attack`, `Dodge`, `Skill`, `Ultimate` mini clips or controlled preview playback; no internet clips. Every character usable from game start unless the owner explicitly approves story unlock rules; alternate aspects can be unlockable.

### Screen 04 — Run preparation

Selected hero portrait and silhouette on the left; gear and status on right; relic choice row, seed label, challenge modifier, difficulty, `Enter Dungeon` as prominent primary action. Quick return to roster. Daily challenge should be **locally generated seeded challenge** that does not depend on real-time internet, and should be optional. For an indefinite offline app, a `Random Challenge` is better than wall-clock dependency.

### Screen 05 — In-game battle

Portrait mode. Top: hero icon, HP number and bar, class-resource pips, chapter/floor and pause. Middle: 2D walkable room with fully visible environmental threats, exits and enemy silhouettes. Small top-right minimap or route indicator. Bottom-left: responsive adjustable virtual joystick. Bottom-right: attack circle, larger dodge circle, skill, ultimate and optional consumable slot. UI clears enough floor area for 3–30 minute sessions; buttons fade slightly in noncombat but never disappear unexpectedly. Text-based choices can pause action after room is cleared and use a bottom-sheet with two or three large choices.

### Screen 06 — Rewards and item detail

After clearing, one to three cards show rarity shape, item illustration, exact effect statement, active synergies, no misleading hidden stats. A selection can replace weapon or bind relic; a `Leave` choice exists when appropriate. A close-up item comparison uses a readable vertical layout rather than tiny horizontally squeezed tables. A rare drop gets a brief particle effect that cannot freeze input excessively.

### Screen 07 — Shop

Vendor is a tiny chibi creature with visual personality appropriate to biome. Inventory has 3–5 offers, one service (heal, cleanse, reroll or upgrade), and clear current Petals. Buying decrements balance exactly once and saves immediately. Grayed-out choices say why unavailable; there is always a `Leave` action. Some vendors may offer risky bargains, but costs and downsides visible beforehand.

### Screen 08 — Map and branch decision

A small scrollable floor graph with visited rooms, known room classes (combat, elite, chest, shop, rest, event, boss), discovered secrets and forecast modifier icons. Graph corresponds to actual doors/walkable transitions and is not a detached fiction. Tap a branch at a junction; alternatives are still selectable until the character commits through the corresponding doorway. Avoid trapping the player in a completely undisclosed dead end.

### Screen 09 — Boss introduction

Large boss art slides in with name, tiny silly subtitle and warning icon. The player has a safe short window before the first attack. Boss bar and phase markers visible; use a musical cue and geometry-first danger telegraph. Boss death plays a celebratory but brief chibi animation; loot appears reliably and does not spawn inside damaging terrain.

### Screen 10 — Death, victory, Endless milestone

Death: hero-specific reaction, exact enemy/attack that killed the player, stage, elapsed active time, main items, kill count, critical events, Garden Seeds earned and `Return to Garden`. Victory: capstone defeated, satisfying visual resolution, stats and choice to `End Run` or `Continue into Endless` if valid. Endless milestones: floor number, modifiers survived, best score, optional replay seed and locally stored achievement. **Do not pretend the app uploads leaderboards.** Personal records are stored on-device.

### Screen 11 — Collection and Codex

Tabbed `Heroes`, `Weapons`, `Relics`, `Enemies`, `Bosses`, `Rooms`, `Story`, `Achievements`, `Run History`. Discovered items show art/name/description/counterplay; hidden ones show a silhouette and hint. Full search and category filters operate on packaged local data. A small `Favorite Build` note is stored locally. Profile export/import can be added as local file sharing with user-initiated Android picker, not via accounts.

### Screen 12 — Settings / accessibility

`Graphics`: 30/60 FPS, reduced particles, simplified lighting, VFX density, shake. `Controls`: button size, position, left-handed mirror, aim assist, sensitivity, tap-target, joystick deadzone. `Access`: high-contrast ground telegraphs, colorblind-safe patterns, larger fonts, reduced motion, damage numbers. `Audio`: music/SFX volume, mute on background, haptics, route warnings. `Data`: save integrity, export/import if implemented, privacy notice: no internet/account/analytics. Every slider must work and persist.

### Portrait typography / color tokens

- Main title uses warm ivory on dark plum scene, with floral serifs or readable fantasy display type; body text uses a modern high-legibility sans font.
- Menu surface: cream `#F4E9DB`, light card `#FFF7EC`, ink `#252338`, muted ink `#696374`, border brass `#AE8E6C`, violet UI accent `#67518B`.
- Angela: icy `#A6D5F1` + amber `#E2AC55`; Vivianne: platinum `#ECE9F0` + crimson `#BC4C72`; Nixia: orchid `#9966D3` + magenta `#E15CBB`; Virelia: camellia `#E6A0BA` + gold `#D9AC58`; Zaria: teal `#409FAF` + electric indigo `#4A65B8`.
- Warning color should never be the biome's dominant hue without a separate bright outline/pattern. High-contrast mode prioritizes saturated geometric telegraphs over decorative background.
- Rarity uses both shapes and colors: Common circle/gray, Uncommon leaf/green, Rare triangle/blue, Epic diamond/violet, Legendary sun/gold, Forbidden cracked rose/red-black.

Keep responsive layout within Android safe area. Treat these tokens as proposals to tune against the attached concept sheet and actual in-engine captures, not hard restrictions on the artist.

## 46. Art asset manifest and creative prompts

### Asset naming and file organization

Use paths like `assets/heroes/angela/portrait_neutral.png`, `assets/heroes/angela/idle_sheet.png`, `assets/heroes/angela/attack_sheet.png`, `assets/enemies/mushroom_king/telegraph.png`, `assets/biomes/forgotten_garden/tiles_floor.png`, `assets/ui/relics/relic_thornmail.png`. Keep all runtime sprites transparent where appropriate, with predictable logical scale and pivot points. Preserve source layered art in a separate editable source area; Godot imports optimized PNG/atlas. Use filenames that correspond to stable IDs, not display names, to avoid brittle renaming.

### Hero art pack — per heroine

- One clean full-body adult chibi turnaround: front, left, right, back, 3/4, plus black silhouette.
- One expressive face sheet: neutral, smug, angry, worried, delighted, focused, exhausted, surprised, dramatic defeat.
- Four directional idle/walk states with consistent pivots; attack, dodge, skill, ultimate, receive hit, fall, victory.
- Base outfit, one combat upgrade overlay, a curse overlay, an alternate-aspect overlay, a comedic low-health expression.
- Portrait crop for hero select; small round HUD icon; dialogue bust; loading-screen cut-in.
- Separate shadow/depth anchoring layer; in-world sprite never includes an opaque rectangle or unremovable background.

### Enemy art pack — per distinct species

- True top-down/three-quarter gameplay stance, 1–2 head-high normal enemy, except intentionally large brutes.
- Idle/walk frames and at least one readable attack warning animation matched to AI timings.
- Damage flash, hitstun, defeat, elite crown accessory, small codex portrait/icon, ground shadow.
- A tiny palette swatch showing biome legibility, not just pretty illustration. Test against hazard-colored floor.

### Boss pack

- Large illustration, scaled top-down sprite, vulnerable parts layer, arena background, three attack telegraphs, phase-two changes, defeat animation, trophy icon, splash-title card. Boss silhouette readable even under reduced VFX.

### Biome pack

- Tile ground, paths, walls, doors, pillars, collision overlays, shadows and corners. Modular cover chunks for room builder. Props must signal whether decorative, breakable, interactive or hazardous. Include alternate room moods and one coherent accent light per biome. All combat geometry must be represented in collision; no invisible walls pretending to be decoration.

### UI and item pack

- Distinct class emblems and resource shapes; all 120 weapon icons, 130 relic icons, 30 curses, 30 consumables and 30 charms.
- Rarity borders, chest open animations, pickups, shop counters, inventory slot icons, actual interactive controls and map node categories.
- Tiny screenshot-ready mockups for all 12 screens, at actual portrait viewport dimensions.

### Ten optional concept-art requests Gemini may give an image generator

1. **Five-hero lineup:** unified five-adult-chibi turnaround, preserving hair/eye/outfit traits from canonical table, clearly differing silhouettes and weapons, neutral transparent/white background, no new characters.
2. **Menu title frame:** overgrown moonlit greenhouse, foreground cream fantasy title, sword-wielding icy-blue Angela in dramatic 3/4, four other girls peeking around plant pots, cozy-dark atmosphere, leave interactive menu space.
3. **Garden hub:** isometric-feeling but actual top-down-layout courtyard with central fountain, five small chibis, benches, merchant cart, flower beds and safe navigation areas; do not bake fake buttons into background.
4. **Character select:** five medium portrait cards, separate color-coded resources, one selected Angela card, cream/gold/dark-plum UI, accurate character identities, actual phone aspect ratio.
5. **Forgotten Garden gameplay:** top-down tile room, Angela swinging blue sword at angry tulip and thorn slug, chest to right, strong joystick and readable HUD zones without decorative clutter.
6. **Knife Shroom enemies:** a sprite and animation reference of ordinary, elite crown, and boss caped knife mushrooms, each with real tell frames and no gore; clean silhouette at tiny scale.
7. **Mushroom boss arena:** His Moldy Majesty with two huge knives, large X-shaped telegraph, mushroom pillars, easy-to-see safe diagonal lane, separate phase-two torn cape design.
8. **Weapon and relic collection:** clear grid of 25 legible icon designs from named catalog, icon style consistent, clean background and no fabricated item labels.
9. **Biome mood board:** seven separate thumbnail rooms with proper palette and unique floor geometry; visualize cross-biome difference while keeping same sprite scale.
10. **Death and Endless screens:** deliberately adorable dramatic Angela defeat card on one side, dark-violet Endless milestone card on other; legible data slots, no false online ranking.

**Rendering strategy:** Generate *reference sheets* first and review continuity. For implementation, prefer editing and cleaning assets into animation-ready sheets or recreating consistent small-shape vector sprites programmatically. Raw beautiful image-model mockups are **not usable sprite sheets by themselves**. Do not pretend screenshots are interactive scene assets.

### Existing visual reference

The concept board supplied alongside this file is named `GARDEN_BAD_BLOOM_CONCEPT_SHEET.png`. It depicts the five heroine identities, main menu, Garden hub, character selection, prep screen, combat UI, item visual language, enemy families, boss art and seven biome thumbnails. Use it as a **visual target**, not as a literal text/data specification. If there is a conflict, the written combat and offline rules in this bible govern behavior, while the canonical character reference sheets govern likeness. If the image is absent, use this document's descriptions and do not block source-code work.

## 47. Godot 4 architecture implementation detail

### Scene composition

```text
RootGame (Node)
 ├─ Bootstrap (reads assets and validates data)
 ├─ LocalSaveManager
 ├─ SettingsService
 ├─ AudioRouter
 ├─ ScreenManager
 └─ ScreenInstance (Garden / Preparation / Run / Summary / Codex)

RunScene (Node2D)
 ├─ RunDirector
 ├─ FloorGraph
 ├─ RoomManager
 │   ├─ CurrentRoom (Node2D)
 │   │   ├─ TileMap layers (floors/walls/decor/hazard)
 │   │   ├─ DoorAnchors
 │   │   ├─ Interactables
 │   │   ├─ EnemyActors
 │   │   ├─ Projectiles
 │   │   ├─ HazardActors
 │   │   └─ PickupActors
 ├─ HeroActor (CharacterBody2D)
 │   ├─ AnimatedSprite2D
 │   ├─ CollisionShape2D
 │   ├─ HurtboxArea
 │   ├─ WeaponPivot
 │   ├─ AbilityHandler
 │   ├─ ResourceHandler
 │   └─ StatusContainer
 ├─ Camera2D
 └─ HUD (CanvasLayer)
     ├─ HealthResourceBar
     ├─ FloorMap
     ├─ TouchJoystick
     ├─ AttackDodgeSkills
     └─ ContextInteraction
```

Godot 4 `TileMapLayer` support differs across releases, so implement using the exact chosen installed Godot version and migrate deprecated nodes as necessary. Never blindly paste old Godot 3 APIs. Lock Godot minor version when starting automated work; tests and Android exporter must match. Use typed GDScript where practical; avoid dynamic dictionaries with unchecked missing keys for core combat state.

### Core data schemas

**HeroDefinition**: `id`, `display_name`, `portrait`, `sprite_pack`, `move_speed`, `health`, `armor`, `resource_type`, `starting_weapon_id`, `basic_attack_pack`, `dodge_behavior_id`, `active_skill_id`, `ultimate_id`, `passive_id`, `talent_ids`, `aspect_ids`, `voice_set`.

**EnemyDefinition**: `id`, `display_name`, `biome_tags`, `role`, `hp_band`, `move_speed`, `hurtbox_radius`, `threat_cost`, `attack_pattern_ids`, `navigation_type`, `drop_pool`, `telegraph_style_id`, `elite_compatibility_tags`, `codex_counterplay`, `sprite_pack`.

**WeaponDefinition**: `id`, `display_name`, `allowed_hero_ids`, `rarity`, `damage_coefficient`, `attack_interval`, `reach`, `attack_scene`, `effect_ids`, `effect_params`, `tags`, `evolution_family`, `icon`, `drop_weight`.

**RelicDefinition**: `id`, `display_name`, `rarity`, `tags`, `effect_ids`, `effect_params`, `proc_limit`, `stack_behavior`, `description`, `icon`, `unlocked_by`, `hero_compatibility`.

**RoomDefinition**: `id`, `biome`, `width_tiles`, `height_tiles`, `tilemap_scene`, `door_anchors`, `safe_entry_rects`, `spawn_points`, `cover_tags`, `hazard_slots`, `encounter_role_constraints`, `secret_tags`, `min_open_lane_width`.

**EventDefinition**: `id`, `name`, `eligible_biomes`, `condition_tags`, `choice_ids`, `readable_risks`, `hero_dialogue_keys`, `resolution_effects`, `repeat_policy`, `event_sprite`.

**BossDefinition**: `id`, `arena_id`, `phase_thresholds`, `pattern_ids`, `pattern_weights`, `telegraph_config`, `weakpoint_components`, `reward_pool`, `codex_entry`, `remix_variants`.

**ActiveRunSnapshot**: `schema_version`, `content_version`, `run_id`, `seed`, `substream_states`, `hero_id`, `hp`, `resource`, `currency`, `equipment`, `statuses`, `talents`, `curse_list`, `aspects`, `graph`, `current_room_id`, `room_clear_state`, `event_choices`, `boss_states`, `floor_index`, `elapsed_active_seconds`, `pending_interaction`, `snapshot_checksum`.

### Deterministic procedural algorithm

```text
function GenerateRun(seed, content_version):
  biome_order = authored campaign order with optional alternate routes
  for chapter in biome_order:
    rng_map = DeriveSubstream(seed, content_version, chapter, "graph")
    graph = GenerateConnectedDAG(rng_map, bounds, node_distribution)
    Assert(hasReachableStartAndBoss(graph))
    Assert(hasAtLeastOneSafeNoncombatNode(graph))
    AssignRoomArchetypes(graph, biome, door_compatibility)
    for node in stableSort(graph.nodes):
      rng_room = DeriveSubstream(seed, chapter, node.id, "room")
      room = AssembleRoom(archetype, rng_room, valid_geometry_only)
      ValidateWalkability(room, door_anchors, minimum_safe_area)
      rng_encounter = DeriveSubstream(seed, chapter, node.id, "encounter")
      enemies = ComposeThreatBudget(room, biome, rng_encounter, role_caps)
      ValidatePatternDensity(enemies, hazards, room.safe_areas)
      rng_reward = DeriveSubstream(seed, chapter, node.id, "reward")
      LockRewardChoices(enemies, node, rng_reward)
    SaveGeneratedChapterManifestBeforeEntering()
```

**IMPORTANT:** A single RNG object shared across navigation and loot is vulnerable to accidental content shifts when users perform unrelated actions. Derive stable streams; save stream state and already drawn outcome manifests. Include `content_version` in deterministic hash so old saves can either keep old manifests or migrate honestly. Implement connectivity validation with flood fill or A* path at player-collision radius, not only checking grid adjacency. Spawn safety must also consider projected hazards and nearby door positions.

### Attack and buff trigger pipeline

Use a registry of events: `on_attack_windup`, `on_attack_hit`, `on_critical`, `on_perfect_guard`, `on_dodge_iframe`, `on_kill`, `on_room_enter`, `on_room_clear`, `on_item_pickup`, `on_shrine_choice`, `on_boss_phase`, `on_low_hp_threshold`. Every effect tracks `source_actor_id`, `source_effect_id`, `root_event_id`, `proc_depth`, and `trigger_count`. Effects set caps and cooldown. An event produced by a triggered effect should not activate identical triggers without explicit authorization; this prevents Butter Knife/crit/reflect/summon loops.

Status effect system separates **application attempt**, immunity/resistance, stack update, ticking and expiration. Damage application should be side-effect-safe when a boss is currently invulnerable. Use projectile pooling where appropriate. Use state machines for AI, attack patterns and boss phases; do not place all 168 enemy species into a single switch statement. Shared enemy controller + attack-behavior resources + biome-specific mechanics are the scalable approach.

### Procedural generation fallback

If no suitable room layout fits a generated door graph, retry a bounded number of times, then select an authored guaranteed-valid room with same door signature. Record seed and reason in development log. Never generate a blocked mandatory route, unreachable loot choice or unsafe attack spawn, even under high Endless floor counts.

### Save transaction lifecycle

Save after deterministic reward generation is committed, after purchases/choices, room transitions and pausing. Use temporary-file write, verify JSON parse/checksum, then atomic replacement where supported by platform; preserve last known good save. Record schema migration version and explicit migrated fields. Pause during file-dialog state and handle Android background interruptions. In the event of mid-combat app kill, resume from the most recent consistent combat checkpoint according to documented anti-exploit policy; never reroll a chest or give free death escape by force closing. Distinguish `pause` from `retire` and `permadeath` clearly.

### Configuration, localization and auditability

Keep tuning data external to code. Provide a developer-only diagnostics overlay with seed, biome/floor, room ID, object count, FPS, active enemy roles, mutation rules, random streams and error log. Bundle English and Bahasa Indonesia translations with fallback, validate every key, and prohibit build-time dependence on fetching an online translation. Art and sounds must be redistributable in the private app and attribution preserved locally if required.

## 48. Android export, reliability and quality verification

### Android product expectations

- Native installable APK, touchscreen portrait design, no runtime internet required or requested.
- App package uses a reasonable unique application ID under an owner-controlled namespace; no accidental overwrite of other installed apps.
- No sign-in, cloud endpoint, remote model call, asset download, telemetry or advertising SDK.
- All Garden content, fonts, sounds, stages and procedural algorithms bundled on-device.
- Respect Android lifecycle: phone call interruption, lock/unlock, system gestures, notification interruption, low memory, app switch and audio focus.
- Save data lives in Godot user data with a backup strategy and appropriate Android storage access policy. Do not demand broad storage permissions for normal saves.
- Export templates, Java/Android SDK configuration and keystore requirements must match installed Godot version. Debug APK may use debug key; release APK signing requires owner-provided secure keystore, never hardcode secrets.
- Use `godot --headless --path . --quit` or the equivalent exact executable installed in project environment to detect script/scene import issues; verify with actual exit code and logs. Run plugin-free tests using GDScript test runner or custom headless harness.
- If an agent cannot run Android SDK on its host, provide clear reproducible export instructions, do not invent a built APK.

### Performance target matrix

| Scenario | Expectation | Evidence |
|---|---|---|
| Garden hub | Smooth animations, fast menu switching | On-device capture and profiler |
| 20 enemies + 50 projectiles | Responsive movement and readable telegraphs | Frame-time graph |
| Vivianne residue storm | No runaway projectiles or status tick pauses | Stress test logs |
| Nixia heavy combos | Reliable collisions and input buffering | Combat playback |
| Endless floor 1,000 | No integer overflow, no empty/invalid map | Seeded generator test |
| Suspend/resume | Same items, funds, positions and choices after restart | Snapshot comparison |
| Low-power mode | 30 FPS stable input/physics, no odd dodge timing | Battery mode test |
| No network | Every screen and run works from clean install in airplane mode | Manual acceptance recording |
| Font accessibility | Text fully readable and not clipped at high scaling | Multiple viewport screenshots |
| Localization | English and Indonesian strings fit cards | Screenshot diff |

### Test suite categories

- **Data integrity**: IDs unique; referenced effect/attack/asset IDs exist; no missing icons; tags valid; all eligible loot has source and incompatible picks filtered.
- **Generator**: random sample and stable 1,000+ seeds cover all biomes; no disconnected mandatory branch; boss reachable; safe entry; loot not trapped.
- **Combat**: i-frames, parry windows, armor math, damage caps, projectiles, stun immunity, on-hit procs, death credit, enemy collision.
- **Behavior**: each bestiary species starts, attacks, recovers, takes damage and dies; all 40 bosses transition phases without softlock; all events complete correctly.
- **Economy**: purchase transaction cannot duplicate, prices never negative, reroll advances saved RNG, healing cost matches displayed value.
- **Synergies**: all authored 35 activate under correct conditions and do not trigger recursion; unwanted combinations are blocked or normalized.
- **Save**: forced app termination during purchase, selection, combat, boss victory, death and floor transition; restore is consistent.
- **UI**: functional tap targets, gesture safe zones, localization, font scaling, options persistence, no dead-end modal.
- **Platform**: real exported Android build launches offline with audio/resources and no network permission.
- **Regression**: after adding any content pack, run all existing tests and replay stored bug seeds. Never assume a passing editor session proves an Android build.

### Required screenshots / evidence of actual implementation

Capture actual running engine scenes, not illustrations passed off as gameplay: title screen; Garden hub; each heroine moving and attacking; one chest and relic selection; each main biome; two boss fights including transition; death screen; Endless floor; settings; native Android installation and offline start. Show build logs with timestamps/exit codes when claiming compilation succeeded. Keep a reproducible `docs/TEST_REPORT.md` listing executed checks and failures.

## 49. Long-form content expansion mandate for Gemini

**Important: the content counts in this document are mandatory starting coverage, not the total extent of the finished game's world.** Once the entries are integrated and functional, continuously expand the world with new enemy species, attack patterns, biome variants, weapons, relics, charms, consumables, curses, events, bosses, room layouts, social gags, cosmetics and synergies. A huge content spreadsheet with no corresponding working mechanics is not the goal. A smaller functional subset on a given workday is acceptable as **work in progress**, but it is never called complete while listed requirements remain unimplemented.

### Expansion algorithm for authored content

1. **Audit existing gameplay dimensions**: movement type, telegraph shape, terrain usage, attack tempo, resource interaction, status type, risk/reward and player response.
2. **Identify an underexplored dimension**: a new behavior is worth adding only if it creates an interesting decision or new skill to learn.
3. **Author mechanic first**: specify tell, active action, recovery, counterplay, art silhouette, role cost and compatibility. Avoid naming a recolored version and calling it a new monster.
4. **Integrate using existing systems** where possible. Extend reusable attack/effect components rather than copy-pasting AI source 40 times.
5. **Test in a realistic arena** with each affected hero and in at least three encounter compositions.
6. **Add reliable in-game discovery** via codex, loot tables, authored rooms or progressive unlocks. Content is not useful if unreachable.
7. **Measure density and redundancy** with data scripts. Avoid creating 12 near-identical swords, or enemies that are actually the same charge attack with arbitrary HP changes.
8. **Maintain consistency** with Garden art canon and fully offline mobile experience.
9. **Document new entries** in machine-readable content manifests with tests, generated screenshots when practical, and detailed notes in a changelog.
10. **Never quietly stop after meeting catalog counts.** The project is a complete expandable game with a strong content pipeline; the catalog is its opening library, not its final creative ceiling.

### Concrete follow-on content ambitions (extend only after existing content is reliable)

- At least **20 further monster archetypes** with unfamiliar attack grammar and biome-specific art.
- At least **100 further variants** produced from valid elite/biome mutations that materially change gameplay.
- At least **30 further weapon evolutions**, including cross-hero novelty without erasing class identity.
- At least **50 further relic combinations** tied to named discoverable effects.
- At least **20 more minibosses and bosses** distributed across optional routes and Endless milestones.
- At least **60 more dungeon-choice events** with hero-specific responses and strategic outcomes.
- At least **50 more room templates** including challenge puzzles, traps, merchants and boss arenas.
- Seasonal **aesthetic packs** can exist entirely as locally unlocked content; no network-based limited-time events or urgency mechanics.
- A **Garden Museum** hub wing displaying beaten bosses as tiny ironic sculptures, visible locally.
- A **Monster Field Guide** that teaches counters through playful animations, useful when returning after months away.
- Randomized **hero banter pairs** in the hub, preserving five distinct personalities without turning combat into lengthy cutscenes.
- **Seed sharing as text**: optional local seed copy/paste when user initiates it, with matching content-version warning and no online leaderboards.
- **Challenge rule editor** allowing player to assemble compatible modifiers for personalized offline runs, with ordinary reward rules clearly differentiated from competitive presets.

### What expansion must not become

No internet dependence, gacha, limited-time premium currencies, pay-to-win stat boosts, endless asset downloads, fully automatic combat replacing skill, walls of optional exposition that interrupt short sessions, unreadable bullet spam, hundreds of indistinguishable palette-swapped enemies, inflated enemy HP solely for difficulty, or untested interactions that corrupt saves. **Depth means combinations and decisions, not clutter.**

### Session-continuation message for coding agent

> You are developing Garden: Bad Bloom as a complete offline Android action roguelike. Read the entire game bible. Inspect repository and task ledger. Pick the highest-priority incomplete, testable dependencies; implement real GDScript/scene/data/assets; run checks; fix regressions; record completed versus remaining content accurately. Continue through the full documented requirements and expand the content library as systems become stable. Do not stop at a plan, a menu, a single walkable room, or a visually impressive screenshot. When execution cannot continue because the session ends or a dependency is blocked, leave exact tested state, instructions and next steps for continuation. Never assert a finished app or Android APK without verification.

A model cannot magically work after its session has stopped; **design the repository and task ledger for uninterrupted *project continuity across sessions*, not false claims of background autonomy**. The next Gemini session should resume from persisted source, tests, diagnostics and checklist instead of writing a new proposal each time.

## 50. Build acceptance rubric — what the owner must actually experience

**Combat is real** when a thumb moves Angela through a generated room, the swing collider hits an advancing Knife Shroom, the enemy has an obvious knife tell, Angela dodges, parries, counterattacks and causes actual knockback. The door opens on room clear; a chest appears; one weapon/relic choice changes next room's fight. If the player is hit repeatedly, HP reaches zero and the run is truly lost. If the app is killed, the deterministic save resumes correctly. If airplane mode is on, nothing breaks.

**Five heroines are real** when each has unique class resources, buttons, projectiles/attack geometry, talents, visual reaction and gameplay strengths. A different portrait with identical underlying attacks does not count.

**Roguelike generation is real** when two different seeds produce distinct connected routes, compatible enemies, rewards and events, while repeating the same seed produces reproducible data. Multiple biomes have unique hazards and assets rather than recolored walls.

**Buildcraft is real** when the player can equip named weapons and relics, trigger a combo, visibly feel changed combat, intentionally accept a curse and understand its trade-off. A list of unimplemented item names does not count.

**Bosses are real** when each has distinguishable attacks, phases, tells, stagger/recovery rules, rewards and an actual victory state. A giant scaled-up standard enemy with extra HP does not count.

**Endless is real** when floors beyond the core campaign keep generating valid room graphs and interesting compatible mutators, with meaningful progression, escalating tactical complexity and savable personal bests.

**A completed Android release is real** when installation, controls, sound, graphics, save, resume, settings, every hero, campaign, Endless and bundled content are verified on the target phone in airplane mode. No external server or account is required. Keep the source project, data, tests and installation instructions accessible for future expansion.

### Final instruction from the creative owner

Build the whole game. Protect the Garden girls' identities. Make the monsters cute and the combat cruel. Make the dungeons beautiful, procedurally varied and tactically surprising. Make every weapon, relic and curse an actual decision. Add more good content beyond what is written here. Keep the architecture clean, documentation current, and Android export truly offline. **Every continuation should turn concepts into working files, working scenes, verified mechanics and more playable content.**

**We choose the Garden. The Garden chooses violence.**

---

## Appendix A — Example playable moment

**Run:** Zaria, Mushroom Kingdom, floor 8.  
**Build:** `Iris Twin Daggers + Glitter Crime + Painted Exit + Pocket Scarecrow`.  
**Room:** a branching cave with three Knife Shrooms, one spore shooter and a volatile mushroom cluster.

Zaria enters from the south. A Knife Shroom lifts its enormous knife and paints a diagonal threat lane. The player blinks sideways; Zaria leaves a magenta paint trail and a decoy scarecrow. A second Shroom strikes the decoy. The player dashes through the gap and chains backstabs; crits splash paint. The shooter detonates a mushroom; paint ignites briefly and damages a nearby elite. The door opens. The route map offers a **Shop** (safe healing) or a **Curse Altar** (rare weapon evolution). The player chooses the altar. A tiny dialogue box asks, “Have you considered making your situation worse?”

That moment is the product goal: movement, readable danger, hero identity, build synergy, comedy, route agency and genuine consequence.

## Appendix B — Example art review prompt (for an image model)

Create a polished **concept-art lineup**, not a final game screenshot, for an original offline 2D top-down action roguelike named *Garden: Bad Bloom*. Show five fully clothed chibi adult heroines about 2.5–3 heads tall against a neutral reference background. Maintain exactly recognizable canonical traits: Angela — short layered icy light-blue bob, amber-gold eyes, white/blue coat and knight shield/sword; Vivianne — very long platinum hair, sleepy crimson eyes, black oversized sweater-witch with floating book; Nixia — slightly smaller, short silver hair with symmetric twin buns, purple ribbons, magenta eyes, dark cyber-goth outfit and giant boxing gauntlets; Virelia — soft dusty-pink braided hair, golden eyes, freckles, floral cream/pink ranger-maid ensemble with bow; Zaria — asymmetrical teal-blue hair, amber/blue heterochromia, olive top and oversized black jacket with twin paint daggers. Clean bold outlines, flat soft shading, coherent line weight, expressive faces, separate silhouettes, animation-friendly costume forms, non-suggestive. Under each character place a tiny gameplay-scale silhouette. Along the bottom show three enemy ideas: a knife mushroom, haunted teapot, and thorn slug, plus a small top-down room crop with clear hazard telegraph. No photorealism, no accidental character swaps, no extra characters, no watermark; labels legible where possible.

---

