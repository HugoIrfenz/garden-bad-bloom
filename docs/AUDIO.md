# Original audio

Garden: Bad Bloom contains 32 instrumental loops, five short prologue scores, and 51 sound effects. The original score in [the renderer](../tools/render_audio.cpp) synthesizes every cue locally. The shipped music is stereo 32 kHz Ogg Vorbis. Effects are stereo 32 kHz PCM WAV.

All 37 score cues are available as individual VHS tapes for the Garden Jukebox. The collection covers menus, chapters, bosses, the prologue, and the five Garden Games.

## Score

- The title, Garden, roster, preparation, settings, archive, shop, rest, event, curse, reward, victory, and defeat each have their own loop.
- Every campaign biome has an exploration loop and a separately composed boss cue. The boss score has its own themes, harmonies, rhythms, and instrumentation.
- The seven exploration loops use separately written 16-bar arrangements. Forgotten Garden has a flute reel, Mushroom Kingdom a 6/8 reed tune, Clockwork a 2+2+3 tick, Bloodbloom a slow 5/4 string procession, Hollow a felt-piano waltz, Astral sustained bell phrases, and Bloomheart a horn hook over a driving bass line. The Three Caps game has its own pizzicato two-step.
- The music retains its room tails across loop boundaries. The game crossfades between tracks and keeps music below action cues. The effects mix has a dedicated limiter.

| Boss | Score |
| --- | --- |
| The Gardener That Forgot | A 5/4 chase led by low cello, with clipped pizzicato and shearing woodblock rhythms |
| His Moldy Majesty | A 6/8 reed-and-horn gallop with pitched drums and a plucked bass |
| The Late Bell | A 7/8 mechanical pulse with ticking percussion and a celeste answer |
| The Weeping Orchard | A string lament over a low ritual drumbeat |
| Duchess of the Last Tea | A minor-key felt piano minuet with a porcelain-bright celeste |
| The Starbound Florist | A celeste spiral and flute response above a repeating low orbit |
| The Bloomheart, Unraveled | Layered horns, viola, and pitched drums, with the title melody's contour returning in the final section |

The action mix adds separate enemy release sounds for blades, spores, clockwork, magic and heavy attacks. Boss defeats use a break, a material-specific landing sound, and a fanfare with brief music ducking. Three Caps has move, win, and loss cues. App backgrounding pauses playback.

Petal Prix has a quick reed score with separate pedal, puddle, and boost effects. Clockwork Encore uses a quieter harp track and four pitched keys. Bramble Snake plays a flute jig, and Teacup Catch uses a felt-piano waltz. Shared pickup and miss sounds mark catches and collisions.

## Storybook prologue

The title's opening melody returns in five one-shot arrangements. Each scene has its own short sound accent and can crossfade to the next score when the page advances.

| Scene | Score cue | Arrangement | Sound cue |
| --- | --- | --- | --- |
| The Creator | `prologue_creator` · 5.90 s | Open felt piano, cello pedal, and a quiet flute answer | `prologue_water` · a pour and individual drops |
| Bloom | `prologue_bloom` · 7.24 s | Rolling harp, celeste melody, and a rising viola line | `prologue_sprout` · leaves stirring under a rising harp figure |
| Happiness | `prologue_happiness` · 6.96 s | A flute waltz with plucked strings and a reed answer | `prologue_laughter` · picnic breeze, birds, and a cup clink |
| Corruption | `prologue_corruption` · 7.40 s | The melody darkens over low cello and suspended viola | `prologue_thorns` · close twigs and low, spreading vines |
| Adventure | `prologue_adventure` · 8.72 s | Horn and flute reprise with harp motion and a cadence into the title | `prologue_draw` · cloth, a short draw, and a metal shimmer |

## Rebuild

From the project root, with a C++17 compiler and libsndfile installed on Linux, run:

```sh
g++ -std=c++17 -O2 tools/render_audio.cpp -l:libsndfile.so.1 -o /tmp/garden-render-audio
/tmp/garden-render-audio
```

Run `/tmp/garden-render-audio --boss-only` to replace the seven boss cues, `--sfx-only` to replace the effects, or `--feedback` to replace the seven exploration tracks, Three Caps loop, and 15 combat and board effects. Run `/tmp/garden-render-audio --prologue-only` to replace the ten prologue assets. Godot imports the rendered files on the next asset scan.

Run `/tmp/garden-render-audio --upgrade-only` to rebuild the chest upgrade chime and Petal Aegis impact sound.

Run `/tmp/garden-render-audio --arcade-only` to rebuild the four new game tracks and nine effects.

## Verification

The [Soundstage test](../tests/soundstage.gd) covers the original audio imports, campaign boss entrances, scene selection, crossfades, action routing, and the effects limiter.

All ten prologue assets decoded as stereo 32 kHz audio. The largest decoded music peak was 0.5834 and the largest effect peak was 0.4000. All ten clips fade to near silence at the end. The prologue-only render preserved the SHA-256 hashes of all 63 preexisting audio files.

The eight 0.1.7 tracks decode at 13.33–52.75 seconds. The largest peak is 0.634 and the largest adjacent-sample jump at the loop boundary is 0.0073. The title track retained its SHA-256 checksum. Listening and in-game mix checks remain part of the owner's device playtest.

The 12-bar boss cues decode to 15.88–27.17 seconds. The largest peak is 0.6428 and the largest adjacent-sample jump across a loop boundary is 0.00891. SHA-256 checks confirmed that the boss-only rebuild preserved every exploration loop, menu loop, and effect byte for byte.

An earlier desktop PulseAudio capture included 33,792 output frames and measured a peak of 0.6083 with music and eight simultaneous effects. Normal window-close shutdown completed without a resource warning.

Godot's Dummy audio driver supports silent tests of routing. Real desktop playback uses the installed audio driver. On normal quit, the game stops audio and gives Godot's mixer time to retire streams. [Godot playback shutdown issue](https://github.com/godotengine/godot/issues/76745)
