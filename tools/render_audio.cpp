// Original Garden: Bad Bloom score and sound synthesis.
// Build with: g++ -std=c++17 -O2 tools/render_audio.cpp -l:libsndfile.so.1 -o /tmp/garden-render-audio
// Run the resulting executable with the project root as its working directory.
#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <iostream>
#include <initializer_list>
#include <random>
#include <stdexcept>
#include <string>
#include <vector>

extern "C" {
using sf_count_t = int64_t;
struct SNDFILE_tag;
using SNDFILE = SNDFILE_tag;
struct SF_INFO { sf_count_t frames; int samplerate, channels, format, sections, seekable; };
SNDFILE* sf_open(const char*, int, SF_INFO*);
sf_count_t sf_writef_float(SNDFILE*, const float*, sf_count_t);
int sf_close(SNDFILE*);
}
constexpr int rate = 32000;
constexpr double tau = 6.283185307179586;
constexpr int ogg_vorbis = 0x200000 | 0x0060;
constexpr int wav_pcm = 0x010000 | 0x0002;
enum Instrument { Felt, Celeste, Harp, Pizz, Viola, Flute, Reed, Drum, Brush, Cello, Horn, Timpani, Woodblock };

double hz(int note) { return 440.0 * std::pow(2.0, (note - 69) / 12.0); }
double wave(double phase) { return std::sin(tau * phase); }
double smooth(double x) {
    x = std::clamp(x, 0.0, 1.0);
    return x * x * (3.0 - 2.0 * x);
}

struct Mix {
    int frames;
    bool looping;
    std::vector<float> samples;
    uint32_t rng = 71431;
    explicit Mix(double seconds, bool loop) : frames(int(seconds * rate)), looping(loop), samples(frames * 2) {}
    double white() {
        rng ^= rng << 13; rng ^= rng >> 17; rng ^= rng << 5;
        return double(int32_t(rng)) / 2147483648.0;
    }
    void put(int frame, double datum, double left, double right) {
        if (looping) frame = (frame % frames + frames) % frames;
        if (frame >= 0 && frame < frames) {
            samples[frame * 2] += float(datum * left);
            samples[frame * 2 + 1] += float(datum * right);
        }
    }
    void note(Instrument instrument, int pitch, double at, double duration, double gain, double pan) {
        const double f = hz(pitch);
        const int start = int(at * rate);
        const bool sustained = instrument == Viola || instrument == Flute || instrument == Reed
            || instrument == Cello || instrument == Horn;
        const double tail = sustained ? 0.24 : (instrument == Celeste ? 0.78 : 0.35);
        const double left = std::sqrt((1.0 - pan) * 0.5);
        const double right = std::sqrt((1.0 + pan) * 0.5);
        double noise_low = 0.0;
        for (int frame = 0; frame < int((duration + tail) * rate); ++frame) {
            const double t = (double)frame / rate;
            const double p = t * f + (sustained ? 0.035 * wave(t * (instrument == Viola ? 5.2 : 4.5)) : 0.0);
            double sound = 0.0;
            const double attack = instrument == Horn ? 0.037 : (sustained ? 0.085 : 0.006);
            double env = smooth(t / attack);
            if (t > duration) env *= std::exp(-(t - duration) * (sustained ? 19.0 : 6.8));
            switch (instrument) {
                case Felt:
                    sound = 0.76 * wave(p) * std::exp(-1.75 * t)
                        + 0.24 * wave(2.003 * p) * std::exp(-3.6 * t)
                        + 0.12 * wave(3.012 * p) * std::exp(-7.5 * t)
                        + 0.055 * wave(5.036 * p) * std::exp(-12.3 * t)
                        + 0.029 * white() * std::exp(-58.0 * t);
                    break;
                case Celeste:
                    sound = 0.76 * wave(p) * std::exp(-2.2 * t)
                        + 0.18 * wave(2.004 * p) * std::exp(-3.7 * t)
                        + 0.13 * wave(3.023 * p) * std::exp(-4.9 * t)
                        + 0.079 * wave(4.118 * p) * std::exp(-9.0 * t)
                        + 0.038 * wave(6.19 * p) * std::exp(-14.1 * t);
                    break;
                case Harp:
                    sound = 0.66 * wave(p + 0.043 * wave(2 * p) * std::exp(-6.3 * t)) * std::exp(-2.0 * t)
                        + 0.24 * wave(2.001 * p) * std::exp(-4.7 * t)
                        + 0.10 * wave(3.003 * p) * std::exp(-6.5 * t)
                        + 0.04 * wave(4.011 * p) * std::exp(-9.4 * t);
                    break;
                case Pizz:
                    sound = (0.70 * wave(p) + 0.28 * wave(p * 2) + 0.13 * wave(p * 3) * std::exp(-5.1 * t)
                        + 0.06 * wave(p * 5)) * std::exp(-4.25 * t);
                    break;
                case Viola:
                    sound = (0.57 * wave(p) + 0.21 * wave(p * 2) + 0.12 * wave(p * 3)
                        + 0.045 * wave(p * 4) + 0.025 * wave(p * 7)) * (0.91 + 0.09 * wave(t * 1.15));
                    env *= 0.62 + 0.38 * smooth(t / 0.31);
                    break;
                case Flute:
                    noise_low = 0.83 * noise_low + 0.17 * white();
                    sound = 0.83 * wave(p) + 0.11 * wave(2 * p) + 0.04 * wave(3 * p)
                        + noise_low * (0.04 + 0.08 * std::exp(-10 * t));
                    break;
                case Reed:
                    sound = 0.71 * wave(p) + 0.25 * wave(3 * p) + 0.095 * wave(5 * p)
                        + 0.04 * wave(7 * p) * std::exp(-4.1 * t);
                    break;
                case Drum:
                    sound = (0.79 * wave(t * 54 + 0.9 * (1 - std::exp(-t * 20)))
                        + 0.21 * wave(t * 93)) * std::exp(-16 * t);
                    break;
                case Brush:
                    noise_low = 0.87 * noise_low + 0.13 * white();
                    sound = (white() - noise_low) * std::exp(-37.0 * t) * 0.34;
                    break;
                case Cello: {
                    const double bow = 0.46 + 0.54 * smooth(t / 0.18);
                    const double vibration = wave(p * 1.003 + 0.14) * 0.11;
                    sound = (0.53 * wave(p) + 0.24 * wave(2 * p) + 0.12 * wave(3 * p)
                        + 0.052 * wave(5 * p) + 0.033 * wave(7 * p) + vibration)
                        * bow * (0.94 + 0.06 * wave(t * 2.15));
                    break;
                }
                case Horn: {
                    const double bright = 0.24 + 0.76 * smooth(t / 0.10) * std::exp(-0.46 * t);
                    const double brass = wave(p + bright * 0.092 * wave(2 * p)) * 0.66
                        + 0.23 * wave(2 * p) + 0.14 * bright * wave(3 * p);
                    sound = brass + bright * (0.07 * wave(4 * p) + 0.045 * wave(6 * p));
                    break;
                }
                case Timpani:
                    sound = (0.71 * wave(p + 0.33 * (1 - std::exp(-t * 32)))
                        + 0.21 * wave(1.51 * p) + 0.08 * wave(2.14 * p) * std::exp(-8.0 * t))
                        * std::exp(-8.5 * t) + 0.035 * white() * std::exp(-105.0 * t);
                    break;
                case Woodblock: {
                    const double wood = 0.57 * wave(p) + 0.24 * wave(1.58 * p) + 0.12 * wave(2.71 * p);
                    sound = wood * std::exp(-44.0 * t) + 0.09 * white() * std::exp(-100.0 * t);
                    break;
                }
            }
            put(start + frame, sound * env * gain, left, right);
        }
    }
    void texture(double at, double duration, double from, double to, double gain, double noise,
            double decay, double pan = 0.0) {
        const int start = int(at * rate);
        double phase = 0.0, slow = 0.0;
        for (int i = 0; i < int(duration * rate); ++i) {
            const double t = double(i) / rate;
            const double ratio = t / duration;
            phase += (from + (to - from) * smooth(ratio)) / rate;
            slow = 0.895 * slow + 0.105 * white();
            const double envelope = smooth(t / 0.009) * std::exp(-decay * t)
                * smooth((duration - t) / 0.022);
            const double pitched = 0.73 * wave(phase) + 0.19 * wave(phase * 2.03) + 0.08 * wave(phase * 3.04);
            put(start + i, envelope * gain * (pitched * (1.0 - noise) + (white() - slow) * noise),
                std::sqrt((1 - pan) * 0.5), std::sqrt((1 + pan) * 0.5));
        }
    }
    void mix_room(double wet) {
        const auto dry = samples;
        constexpr std::array<int, 6> offsets = {727, 1253, 2173, 3293, 5381, 7799};
        constexpr std::array<double, 6> gains = {.30, .25, .22, .13, .09, .055};
        for (int frame = 0; frame < frames; ++frame) {
            for (int i = 0; i < int(offsets.size()); ++i) {
                int delay = frame - offsets[i];
                if (looping) delay = (delay + frames) % frames;
                if (delay >= 0) {
                    samples[frame * 2] += float(wet * dry[delay * 2 + (i % 2)] * gains[i]);
                    samples[frame * 2 + 1] += float(wet * dry[delay * 2 + ((i + 1) % 2)] * gains[i]);
                }
            }
        }
    }
    void soften_loop_seam() {
        constexpr int splice = rate * 6 / 1000;
        for (int channel = 0; channel < 2; ++channel) {
            const float join = (samples[channel] + samples[(frames - 1) * 2 + channel]) * .5f;
            for (int i = 0; i < splice; ++i) {
                const float keep = float(smooth(double(i) / splice));
                auto& head = samples[i * 2 + channel];
                auto& tail = samples[(frames - i - 1) * 2 + channel];
                head = join + (head - join) * keep;
                tail = join + (tail - join) * keep;
            }
        }
    }
    void save(const std::string &path, int format, double peak) {
        if (!looping) {
            const int fade = int(rate * 0.035);
            for (int i = 0; i < fade; ++i) {
                const float amount = float(smooth(double(i) / fade));
                const int frame = frames - 1 - i;
                samples[frame * 2] *= amount;
                samples[frame * 2 + 1] *= amount;
            }
        }
        double high = 0.0;
        for (auto value : samples) high = std::max(high, std::abs(double(value)));
        if (high < 1e-6) throw std::runtime_error("Silent mix: " + path);
        for (auto &value : samples) value *= float(peak / high);
        SF_INFO info{0, rate, 2, format, 0, 0};
        SNDFILE* file = sf_open(path.c_str(), 0x20, &info);
        if (!file) throw std::runtime_error("Could not open: " + path);
        const auto count = sf_writef_float(file, samples.data(), frames);
        if (sf_close(file) != 0 || count != frames) throw std::runtime_error("Could not write: " + path);
    }
};

using Harmony = std::array<std::array<int, 4>, 4>;
using Phrase = std::array<std::array<int, 4>, 4>;
struct Score {
    const char* name;
    int bpm, meter, flavor;
    Instrument melody, backing;
    Harmony harmony;
    Phrase phrase;
};
const Harmony home = {{{48, 55, 64, 67}, {45, 52, 60, 64}, {41, 48, 57, 60}, {43, 50, 59, 62}}};
const Harmony petals = {{{50, 57, 65, 69}, {46, 53, 62, 65}, {43, 50, 58, 62}, {45, 52, 61, 64}}};
const Harmony blood = {{{45, 52, 60, 64}, {41, 48, 57, 60}, {46, 53, 62, 65}, {40, 47, 56, 59}}};
const Harmony palace = {{{55, 62, 71, 74}, {52, 59, 67, 71}, {48, 55, 64, 67}, {50, 57, 66, 69}}};
const Harmony astral = {{{50, 57, 64, 69}, {46, 53, 60, 65}, {43, 50, 57, 62}, {45, 52, 59, 64}}};
const Phrase home_motif = {{{72, 76, 74, 0}, {69, 72, 76, 79}, {77, 76, 72, 0}, {71, 74, 72, 67}}};
const Phrase petal_motif = {{{69, 74, 77, 76}, {74, 72, 70, 0}, {67, 70, 74, 0}, {73, 72, 69, 64}}};
const Phrase garden_motif = {{{76, 79, 81, 0}, {81, 76, 77, 74}, {72, 76, 79, 0}, {74, 71, 67, 0}}};
const Phrase red_motif = {{{72, 76, 71, 69}, {65, 69, 72, 0}, {77, 74, 70, 0}, {71, 68, 64, 0}}};
const Phrase palace_motif = {{{74, 79, 83, 81}, {79, 76, 71, 0}, {72, 76, 79, 84}, {81, 78, 74, 0}}};
const Phrase astral_motif = {{{76, 81, 83, 0}, {77, 82, 84, 81}, {79, 74, 69, 0}, {71, 76, 74, 0}}};
const Score menus[] = {
    {"title", 84, 3, 0, Felt, Harp, home, home_motif},
    {"garden", 88, 3, 1, Flute, Harp, palace, palace_motif},
    {"roster", 78, 4, 0, Celeste, Felt, home, garden_motif},
    {"preparation", 94, 4, 2, Harp, Pizz, petals, petal_motif},
    {"shop", 106, 3, 3, Reed, Pizz, palace, palace_motif},
    {"rest", 67, 3, 0, Flute, Felt, home, home_motif},
    {"curse", 73, 4, 4, Celeste, Viola, blood, red_motif},
    {"event", 82, 3, 1, Reed, Harp, petals, petal_motif},
    {"reward", 96, 3, 1, Celeste, Harp, palace, garden_motif},
    {"victory", 88, 4, 1, Flute, Felt, palace, palace_motif},
    {"defeat", 68, 3, 4, Felt, Viola, petals, petal_motif},
    {"archive", 75, 4, 0, Harp, Felt, astral, astral_motif},
    {"settings", 72, 3, 0, Felt, Harp, home, garden_motif},
};
void render_score(const Score& score) {
    const double beat = 60.0 / score.bpm;
    const double bar = beat * score.meter;
    Mix mix(8 * bar, true);
    mix.rng += uint32_t(score.bpm * 100 + score.meter * 13);
    const std::array<double, 4> starts = score.meter == 3
        ? std::array<double, 4>{0.0, 0.74, 1.48, 2.35}
        : std::array<double, 4>{0.0, 0.89, 1.88, 3.02};
    for (int index = 0; index < 8; ++index) {
        const auto& chord = score.harmony[index % 4];
        const auto& phrase = score.phrase[index % 4];
        const double start = index * bar;
        const double timing = mix.white() * 0.018;
        const double energy = (index % 4 == 0 ? 1.0 : 0.86) + 0.045 * mix.white();
        mix.note(score.flavor == 4 ? Viola : Pizz, chord[0], start + timing, beat * 1.36, .32 * energy, -.18);
        if (score.flavor >= 2 || index % 2 == 1)
            mix.note(Pizz, chord[1] - (chord[1] > 55 ? 12 : 0), start + bar - .73 * beat, beat * .57, .19 * energy, -.14);
        for (int step = 0; step < score.meter * 2; ++step) {
            int member = std::array<int, 8>{1, 3, 2, 1, 3, 2, 1, 2}[step];
            double offset = .5 * step * beat + timing * ((step % 3) - 1) + .024 * (step % 2);
            double pressure = step % 2 == 0 ? .20 : .133;
            if ((score.flavor == 0 || score.flavor == 4) && step % 4 == 3) continue;
            mix.note(score.backing == Viola ? Harp : score.backing, chord[member] + (step % 7 == 3 ? 12 : 0),
                start + offset, .49 * beat, pressure * energy, step % 2 == 0 ? -.27 : .27);
        }
        for (int n = 0; n < 4; ++n) {
            if (phrase[n] == 0) continue;
            const bool reprise = index >= 4;
            int pitch = phrase[n];
            double offset = starts[n] * beat + timing * (n - 1) + (reprise && n == 3 ? -.15 * beat : 0);
            double duration = beat * (n == 3 || phrase[n + 1] == 0 ? 1.01 : .71);
            mix.note(score.melody, pitch, start + offset, duration, (.35 - n * .042) * energy, -.06);
            if (reprise && (n == 0 || (n == 2 && index % 2 == 0))) {
                mix.note(score.melody == Celeste ? Flute : Celeste, pitch,
                    start + offset + .25 * beat, .63 * beat, .086, .46);
            }
        }
        if (score.flavor != 3) {
            mix.note(Viola, chord[2] - 12, start + .12 * beat, bar - .35 * beat, .095, -.40);
            mix.note(Viola, chord[3] - 12, start + .29 * beat, bar - .52 * beat, .061, .44);
        }
        if (score.flavor >= 2) {
            mix.note(Drum, 38, start + .024, .19, .103, 0);
            const double second = (score.meter == 3 ? 1 : 2) * beat;
            mix.note(Brush, 36, start + second + .016, .086, .20, .22);
            if (score.flavor == 3) {
                mix.note(Brush, 36, start + second - .5 * beat, .056, .17, -.25);
                mix.note(Brush, 36, start + bar - .48 * beat, .053, .13, .24);
            }
        }
    }
    mix.mix_room(score.flavor >= 3 ? .26 : .34);
    mix.save(std::string("assets/audio/music/") + score.name + ".ogg", ogg_vorbis, .66);
}

struct TrailScore {
    const char* name;
    int bpm;
    double meter;
    Instrument lead, response, bass, chord, percussion;
    Harmony harmony;
    std::array<std::array<int, 6>, 4> call, answer;
    std::array<double, 6> rhythm;
    std::vector<double> bass_beats, chord_beats, drum_beats;
    double note_length, pulse, room;
};

const TrailScore trails[] = {
    // Forgotten Garden. A flute reel with a four-note rising refrain and a plucked response.
    {"forgotten", 112, 4.0, Flute, Harp, Pizz, Harp, Brush,
        {{{45, 52, 60, 64}, {43, 50, 59, 62}, {41, 48, 57, 60}, {40, 47, 56, 62}}},
        {{{69, 72, 74, 76, 74, 72}, {67, 71, 74, 76, 74, 71}, {69, 72, 77, 76, 72, 69}, {68, 71, 74, 71, 68, 0}}},
        {{{76, 81, 79, 76, 72, 0}, {74, 79, 77, 74, 71, 0}, {72, 77, 76, 72, 69, 67}, {68, 71, 76, 74, 71, 0}}},
        {0, .5, 1, 1.75, 2.6, 3.35}, {0, 2.0, 3.5}, {.625, 1.5, 2.625, 3.5}, {0, 1.75, 2.5, 3.25}, .61, .55, .28},
    // Mushroom Kingdom. Skipping 6/8, linked reed phrases and knocking woodblocks.
    {"mushroom", 124, 3.0, Reed, Celeste, Pizz, Felt, Woodblock,
        {{{43, 50, 58, 62}, {48, 55, 63, 67}, {41, 48, 56, 60}, {38, 45, 54, 60}}},
        {{{67, 67, 70, 74, 72, 70}, {67, 72, 75, 72, 67, 0}, {68, 68, 72, 77, 75, 72}, {69, 66, 72, 74, 69, 66}}},
        {{{79, 74, 70, 74, 79, 77}, {75, 72, 67, 70, 72, 0}, {72, 77, 80, 77, 72, 0}, {74, 72, 69, 66, 69, 74}}},
        {0, .5, .91, 1.5, 2.0, 2.52}, {0, 1.5, 2.5}, {.5, 1.0, 2.0, 2.5}, {.5, 1.5, 2.25}, .38, .90, .19},
    // Clockwork Conservatory. Staggered 2+2+3, with a ticking block on the off-beats.
    {"clockwork", 142, 3.5, Celeste, Felt, Felt, Pizz, Woodblock,
        {{{42, 49, 57, 61}, {38, 45, 54, 57}, {47, 54, 62, 66}, {44, 51, 56, 62}}},
        {{{78, 73, 69, 73, 78, 81}, {78, 74, 69, 78, 74, 69}, {83, 78, 74, 78, 83, 85}, {80, 75, 74, 68, 74, 75}}},
        {{{69, 73, 0, 81, 78, 73}, {74, 78, 0, 81, 78, 74}, {74, 78, 0, 86, 83, 78}, {75, 80, 0, 84, 80, 75}}},
        {0, .44, 1.0, 2.0, 2.5, 3.0}, {0, 1.0, 2.0, 3.0}, {.25, 1.25, 2.5, 3.0}, {.5, 1.5, 2.25, 2.75, 3.25}, .34, .82, .19},
    // Bloodbloom Forest. Bowed call over a low, sparse 5/4 procession.
    {"bloodbloom", 91, 5.0, Viola, Cello, Cello, Harp, Timpani,
        {{{40, 47, 55, 59}, {41, 48, 57, 60}, {38, 45, 53, 57}, {47, 54, 63, 66}}},
        {{{64, 0, 67, 66, 0, 59}, {65, 0, 69, 68, 0, 60}, {64, 0, 65, 62, 0, 57}, {59, 0, 63, 66, 0, 63}}},
        {{{71, 0, 67, 64, 0, 62}, {72, 0, 69, 65, 0, 63}, {74, 0, 69, 65, 0, 64}, {75, 0, 74, 71, 0, 66}}},
        {0, .75, 1.7, 2.45, 3.2, 4.1}, {0, 2.55}, {1.25, 3.35, 4.45}, {0, 2.5, 4.0}, 1.42, .78, .41},
    // Hollow Palace. Felt-piano waltz and a flute that takes over the middle section.
    {"hollow", 98, 3.0, Felt, Flute, Pizz, Felt, Brush,
        {{{48, 55, 63, 67}, {44, 51, 60, 63}, {41, 48, 56, 60}, {43, 50, 59, 62}}},
        {{{79, 0, 75, 72, 75, 77}, {80, 0, 75, 72, 68, 72}, {77, 0, 72, 68, 72, 75}, {74, 0, 71, 74, 77, 0}}},
        {{{72, 75, 79, 75, 0, 72}, {72, 75, 80, 75, 0, 72}, {68, 72, 77, 72, 0, 68}, {71, 74, 77, 74, 0, 71}}},
        {0, .5, 1.0, 1.45, 2.0, 2.52}, {0}, {1.0, 2.0}, {1.0, 2.0}, .68, .14, .37},
    // Astral Greenhouse. Long high glass notes, answer in a different register.
    {"astral", 80, 4.0, Celeste, Flute, Cello, Harp, Brush,
        {{{45, 52, 59, 64}, {42, 49, 57, 61}, {41, 48, 55, 60}, {40, 47, 56, 62}}},
        {{{88, 0, 83, 0, 81, 0}, {85, 0, 81, 0, 80, 0}, {84, 0, 79, 0, 76, 0}, {86, 0, 80, 0, 76, 0}}},
        {{{76, 81, 0, 83, 0, 88}, {73, 78, 0, 81, 0, 85}, {72, 77, 0, 79, 0, 84}, {71, 76, 0, 80, 0, 83}}},
        {.125, .75, 1.5, 2.35, 2.85, 3.45}, {0}, {.6, 1.9, 3.33}, {}, 1.4, .0, .51},
    // Bloomheart Core. Pumping bass, strong backbeat, and a low horn counterline.
    {"bloomheart", 126, 4.0, Horn, Cello, Pizz, Viola, Drum,
        {{{38, 45, 53, 57}, {34, 41, 50, 53}, {42, 49, 57, 61}, {45, 52, 58, 61}}},
        {{{62, 65, 69, 0, 65, 62}, {65, 70, 74, 0, 70, 65}, {66, 69, 73, 0, 69, 66}, {69, 73, 76, 0, 73, 67}}},
        {{{74, 69, 65, 0, 64, 62}, {77, 74, 70, 0, 69, 65}, {78, 73, 69, 0, 68, 66}, {76, 73, 69, 0, 64, 61}}},
        {0, .625, 1.4, 2.1, 2.6, 3.5}, {0, .75, 1.5, 2.5, 3.25}, {.5, 1.25, 2.25, 3.0}, {0, 1.625, 2.5, 3.5}, .85, 1.17, .25},
    // Three Caps. A nimble two-step with little answers on the woodblock and harp.
    {"board", 144, 2.0, Pizz, Harp, Pizz, Celeste, Woodblock,
        {{{48, 55, 64, 67}, {50, 57, 65, 69}, {41, 48, 57, 60}, {43, 50, 59, 65}}},
        {{{72, 0, 76, 79, 76, 0}, {74, 0, 77, 81, 77, 74}, {77, 0, 76, 72, 69, 0}, {71, 0, 74, 77, 74, 71}}},
        {{{84, 79, 76, 72, 0, 0}, {86, 81, 77, 74, 0, 0}, {84, 81, 77, 72, 0, 0}, {83, 79, 77, 74, 71, 0}}},
        {0, .25, .5, .89, 1.35, 1.65}, {0, 1.1}, {.33, 1.37}, {.5, 1.25, 1.75}, .34, .59, .17},
};

void render_trail(const TrailScore& score) {
    const double beat = 60.0 / score.bpm;
    const double bar = beat * score.meter;
    Mix mix(16 * bar, true);
    for (int index = 0; index < 16; ++index) {
        const int section = index / 4;
        const int phase = index % 4;
        const auto& chord = score.harmony[phase];
        const auto& phrase = (section == 1 || section == 2 ? score.answer : score.call)[phase];
        const double start = index * bar;
        const auto note = [&](Instrument voice, int pitch, double offset, double length, double gain, double pan) {
            mix.note(voice, pitch, start + offset * beat, length * beat, gain, pan);
        };
        for (size_t i = 0; i < score.bass_beats.size(); ++i) {
            if (section == 2 && i % 2 == 1) continue;
            const double at = score.bass_beats[i];
            const double duration = score.bass == Cello ? std::min(2.25, score.meter - at) : .46;
            note(score.bass, chord[i % 2], at, duration, i == 0 ? .37 : .24, -.10);
        }
        for (size_t i = 0; i < score.chord_beats.size(); ++i) {
            const double at = score.chord_beats[i];
            const double side = i % 2 == 0 ? -.43 : .43;
            const int octave = section == 1 && i == 0 ? 12 : 0;
            note(score.chord, chord[2 + i % 2] + octave, at, .48, .19, side);
            if (score.chord == Felt || score.chord == Viola)
                note(score.chord, chord[3 - i % 2], at + .020, .54, .125, -side);
        }
        for (size_t i = 0; i < phrase.size(); ++i) {
            if (phrase[i] == 0) continue;
            const double offset = score.rhythm[i];
            double next = score.meter;
            for (size_t upcoming = i + 1; upcoming < phrase.size(); ++upcoming) {
                if (phrase[upcoming] == 0) continue;
                next = score.rhythm[upcoming];
                break;
            }
            const double length = std::min(score.note_length, next - offset + .06);
            const int pitch = phrase[i] - (section == 2 && score.response == Cello ? 12 : 0);
            note(section == 2 ? score.response : score.lead, pitch, offset, length, i == 0 ? .42 : .32, -.04);
            if (section == 3 && (i == 0 || i == 3)) {
                note(score.response, pitch - 12, offset + .045, length, .16, .35);
            }
        }
        for (size_t i = 0; i < score.drum_beats.size(); ++i) {
            if (section == 2 && i != 0) continue;
            const double at = score.drum_beats[i];
            const int pitch = score.percussion == Woodblock ? 79 - (i % 2) * 7 : chord[0];
            note(score.percussion, pitch, at, .17, (i == 0 ? .25 : .17) * score.pulse,
                score.percussion == Woodblock ? (i % 2 == 0 ? -.32 : .32) : 0.0);
            if (score.percussion == Drum && i % 2 == 1) note(Brush, 43, at + .04, .07, .28, .27);
        }
    }
    mix.mix_room(score.room);
    mix.soften_loop_seam();
    mix.save(std::string("assets/audio/music/") + score.name + ".ogg", ogg_vorbis, .63);
}

const TrailScore arcade_tracks[] = {
    {"arcade_prix", 154, 4.0, Reed, Celeste, Pizz, Felt, Drum,
        {{{45, 52, 61, 64}, {47, 54, 62, 66}, {50, 57, 62, 69}, {40, 47, 56, 62}}},
        {{{69, 73, 76, 78, 76, 73}, {74, 78, 81, 78, 74, 71}, {74, 76, 78, 81, 78, 76}, {68, 71, 74, 76, 71, 68}}},
        {{{81, 83, 85, 0, 83, 76}, {78, 81, 83, 0, 76, 74}, {74, 78, 81, 0, 78, 76}, {80, 76, 74, 0, 71, 68}}},
        {0, .38, .8, 1.5, 2.42, 3.18}, {0, .75, 1.75, 2.5, 3.25}, {.5, 1.25, 2.25, 3.5},
        {0, 1.0, 2.0, 3.15}, .64, 1.06, .19},
    {"arcade_encore", 98, 2.5, Harp, Felt, Pizz, Celeste, Woodblock,
        {{{47, 54, 59, 62}, {42, 49, 57, 61}, {43, 50, 55, 62}, {45, 52, 57, 61}}},
        {{{71, 0, 74, 0, 78, 0}, {73, 0, 78, 0, 73, 0}, {74, 0, 67, 0, 71, 0}, {73, 0, 69, 0, 76, 0}}},
        {{{66, 0, 71, 0, 74, 0}, {69, 0, 73, 0, 78, 0}, {67, 0, 71, 0, 74, 0}, {69, 0, 76, 0, 73, 0}}},
        {0, .33, .76, 1.19, 1.63, 2.1}, {0, 1.64}, {.4, 1.33, 2.03}, {.5, 1.5, 2.20}, .37, .43, .31},
    {"arcade_snake", 135, 3.5, Flute, Harp, Pizz, Harp, Brush,
        {{{43, 50, 58, 62}, {39, 46, 55, 58}, {41, 48, 56, 63}, {38, 45, 54, 62}}},
        {{{67, 70, 74, 72, 70, 67}, {67, 70, 75, 74, 70, 67}, {68, 72, 77, 75, 72, 68}, {69, 66, 74, 72, 69, 66}}},
        {{{79, 74, 70, 67, 70, 0}, {82, 79, 75, 70, 75, 0}, {80, 77, 72, 68, 72, 0}, {81, 78, 74, 69, 72, 0}}},
        {0, .5, 1.13, 1.72, 2.45, 3.0}, {0, 1.20, 2.22}, {.4, 1.5, 2.75},
        {.5, 1.35, 2.25, 3.25}, .47, .72, .18},
    {"arcade_tea", 129, 3.0, Felt, Reed, Pizz, Felt, Brush,
        {{{48, 55, 63, 67}, {41, 48, 57, 60}, {46, 53, 62, 65}, {43, 50, 59, 62}}},
        {{{75, 79, 84, 82, 79, 75}, {77, 81, 84, 87, 84, 81}, {77, 82, 86, 84, 82, 77}, {74, 77, 79, 77, 74, 71}}},
        {{{84, 79, 75, 79, 82, 0}, {81, 77, 72, 77, 81, 0}, {82, 77, 74, 77, 84, 0}, {83, 79, 74, 79, 71, 0}}},
        {0, .41, .91, 1.48, 2.06, 2.59}, {0, 1.55}, {.9, 1.85, 2.7}, {.93, 1.96}, .5, .52, .32},
};

struct BossScore {
    const char* name;
    int bpm;
    double meter;
    Instrument melody, answer, pulse, bass, rim;
    std::array<std::array<int, 4>, 8> harmony;
    std::array<std::array<int, 4>, 8> theme;
    std::array<double, 4> melody_beats;
    std::vector<double> bass_beats, pulse_beats, drum_beats, rim_beats;
    double hold, percussion, room;
    bool title_echo = false;
};

const BossScore bosses[] = {
    // The Gardener That Forgot. A lopsided 5/4 chase with shearing pizzicato.
    {"forgotten", 138, 5.0, Cello, Horn, Pizz, Cello, Woodblock,
        {{{38, 45, 53, 57}, {39, 46, 55, 58}, {38, 45, 53, 60}, {45, 52, 61, 67},
          {34, 41, 50, 53}, {36, 43, 51, 55}, {39, 46, 55, 61}, {45, 52, 61, 64}}},
        {{{62, 65, 61, 57}, {63, 67, 66, 58}, {62, 65, 69, 72}, {73, 67, 64, 61},
          {70, 65, 62, 60}, {67, 63, 66, 60}, {75, 73, 70, 67}, {69, 67, 64, 61}}},
        {0.0, 1.25, 2.75, 4.25}, {0.0, 2.0, 3.5}, {0.0, .75, 1.75, 2.5, 3.25, 4.5},
        {0.0, 2.5, 4.5}, {1.0, 1.75, 3.25, 4.5}, .72, .83, .27},

    // His Moldy Majesty. A crooked royal gallop in two groups of three eighths.
    {"mushroom", 136, 3.0, Reed, Horn, Harp, Pizz, Woodblock,
        {{{36, 43, 51, 55}, {41, 48, 56, 60}, {38, 45, 53, 56}, {43, 50, 59, 62},
          {39, 46, 55, 58}, {37, 44, 53, 56}, {48, 55, 63, 67}, {43, 50, 59, 65}}},
        {{{67, 60, 63, 70}, {72, 68, 65, 60}, {65, 62, 68, 65}, {71, 74, 77, 74},
          {75, 70, 67, 79}, {77, 73, 68, 65}, {79, 75, 72, 67}, {71, 68, 67, 62}}},
        {0.0, .5, 1.5, 2.5}, {0.0, .75, 1.5, 2.25}, {.5, 1.0, 1.5, 2.0, 2.5},
        {0.0, 1.5}, {.5, 1.0, 2.0, 2.5}, .56, .77, .32},

    // The Late Bell. A 2+2+3 clock escapement with a discordant bell answer.
    {"clockwork", 139, 3.5, Horn, Celeste, Felt, Pizz, Woodblock,
        {{{35, 42, 50, 54}, {40, 47, 55, 59}, {36, 43, 51, 55}, {42, 49, 58, 61},
          {38, 45, 54, 57}, {41, 48, 57, 60}, {36, 43, 52, 55}, {42, 49, 58, 64}}},
        {{{66, 62, 59, 61}, {67, 64, 71, 0}, {63, 67, 72, 70}, {70, 66, 64, 61},
          {74, 69, 66, 0}, {77, 72, 69, 66}, {72, 64, 67, 0}, {70, 67, 66, 61}}},
        {0.0, 1.0, 2.0, 3.0}, {0.0, 1.0, 2.0}, {.5, 1.5, 2.5, 3.0},
        {0.0, 2.0}, {.5, 1.5, 2.25, 2.75, 3.25}, .52, .92, .23},

    // The Weeping Orchard. Long lamenting strings against a low ritual tread.
    {"bloodbloom", 106, 4.0, Viola, Cello, Pizz, Cello, Brush,
        {{{40, 47, 55, 59}, {41, 48, 57, 60}, {36, 43, 52, 55}, {47, 54, 63, 69},
          {33, 40, 48, 52}, {42, 48, 57, 62}, {43, 50, 58, 62}, {47, 54, 63, 66}}},
        {{{64, 67, 66, 59}, {65, 69, 68, 65}, {64, 60, 55, 0}, {63, 66, 69, 63},
          {72, 69, 76, 0}, {74, 69, 66, 65}, {70, 67, 62, 65}, {66, 65, 63, 59}}},
        {0.0, 1.0, 2.25, 3.5}, {0.0, 2.5}, {0.25, 1.5, 2.25, 3.25},
        {0.0, 2.5}, {1.75, 3.75}, 1.13, .75, .38},

    // Duchess of the Last Tea. An ornate minuet with a brittle porcelain edge.
    {"hollow", 116, 3.0, Felt, Celeste, Pizz, Pizz, Woodblock,
        {{{41, 48, 56, 60}, {37, 44, 53, 56}, {46, 53, 61, 65}, {48, 55, 64, 67},
          {44, 51, 60, 63}, {43, 50, 58, 61}, {37, 44, 53, 60}, {48, 55, 64, 70}}},
        {{{77, 72, 68, 65}, {73, 68, 72, 77}, {82, 77, 73, 70}, {76, 79, 82, 76},
          {84, 80, 75, 72}, {79, 73, 70, 67}, {77, 73, 72, 68}, {79, 78, 76, 72}}},
        {0.0, .75, 1.5, 2.5}, {0.0, 1.5}, {1.0, 1.75, 2.0, 2.75},
        {0.0, 2.0}, {.75, 1.5, 2.5}, .47, .61, .34},

    // The Starbound Florist. Synthesized glass tones spiral through a 5/4 orbit.
    {"astral", 146, 5.0, Celeste, Flute, Celeste, Cello, Brush,
        {{{45, 52, 59, 64}, {42, 49, 57, 61}, {44, 51, 57, 63}, {40, 47, 56, 62},
          {41, 48, 55, 60}, {43, 50, 57, 61}, {38, 45, 53, 57}, {40, 47, 56, 59}}},
        {{{81, 83, 88, 86}, {85, 81, 78, 80}, {87, 81, 83, 0}, {86, 83, 80, 76},
          {84, 79, 88, 89}, {85, 81, 79, 0}, {86, 81, 77, 72}, {83, 86, 80, 76}}},
        {0.0, 1.5, 3.0, 4.25}, {0.0, 1.5, 3.0}, {.5, 1.0, 2.0, 2.5, 3.5, 4.0, 4.5},
        {0.0, 3.0}, {1.0, 2.5, 4.5}, .69, .64, .48},

    // The Bloomheart, Unraveled. Driving strings, horns and a displaced title echo.
    {"bloomheart", 143, 4.0, Horn, Cello, Viola, Cello, Woodblock,
        {{{38, 45, 53, 57}, {34, 41, 50, 53}, {43, 50, 53, 62}, {45, 52, 61, 67},
          {41, 48, 57, 60}, {37, 44, 53, 56}, {43, 50, 59, 65}, {45, 52, 61, 67}}},
        {{{62, 69, 65, 60}, {65, 70, 62, 65}, {67, 74, 70, 65}, {73, 76, 67, 61},
          {77, 81, 72, 69}, {73, 77, 80, 84}, {79, 74, 83, 77}, {76, 73, 70, 69}}},
        {0.0, .75, 2.0, 3.25}, {0.0, 1.5, 2.0, 3.5}, {0.0, .5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5},
        {0.0, 1.5, 2.0, 3.5}, {1.0, 2.75, 3.75}, .8, 1.05, .36, true},
};

void render_boss(const BossScore& score) {
    constexpr int bars = 12;
    const double beat = 60.0 / score.bpm;
    const double bar = score.meter * beat;
    Mix mix(bars * bar, true);
    mix.rng += uint32_t(score.bpm * 181);
    for (int index = 0; index < bars; ++index) {
        const auto& chord = score.harmony[index % score.harmony.size()];
        const auto& theme = score.theme[index % score.theme.size()];
        const bool response = index >= 4 && index < 8;
        const bool reprise = index >= 8;
        const double start = index * bar;
        const double weight = response ? .85 : (reprise ? 1.04 : 1.0);
        const auto note = [&](Instrument voice, int pitch, double offset, double beats, double gain, double pan) {
            mix.note(voice, pitch, start + offset * beat, beats * beat, gain * weight, pan);
        };

        for (size_t step = 0; step < score.bass_beats.size(); ++step) {
            const int pitch = step % 2 == 0 ? chord[0] : chord[1];
            note(score.bass, pitch, score.bass_beats[step], step == 0 ? .82 : .51, step == 0 ? .28 : .18, -.06);
        }
        for (size_t step = 0; step < score.pulse_beats.size(); ++step) {
            constexpr std::array<int, 4> contour{1, 2, 3, 2};
            const double spread = step % 2 == 0 ? -.39 : .39;
            const int pitch = chord[contour[step % contour.size()]] + (reprise && step % 3 == 0 ? 12 : 0);
            note(score.pulse, pitch, score.pulse_beats[step], .34, step % 2 == 0 ? .17 : .113, spread);
        }
        for (size_t step = 0; step < theme.size(); ++step) {
            if (theme[step] == 0) continue;
            const double offset = score.melody_beats[step];
            const double next = step + 1 < theme.size() ? score.melody_beats[step + 1] : score.meter;
            const double length = std::min(next - offset + .08, score.hold);
            note(score.melody, theme[step], offset, length, step == 0 ? .36 : .29, -.12);
            if ((reprise && step % 2 == 0) || (response && step == 2)) {
                note(score.answer, theme[step] - 12, offset + .04, length, .15, .32);
            }
        }
        for (size_t step = 0; step < score.drum_beats.size(); ++step) {
            if (response && step > 0 && index % 2 == 0) continue;
            note(Timpani, step % 2 == 0 ? chord[0] : chord[1], score.drum_beats[step], .38,
                (step == 0 ? .31 : .21) * score.percussion, 0.0);
        }
        for (size_t step = 0; step < score.rim_beats.size(); ++step) {
            note(score.rim, step % 2 == 0 ? 79 : 74, score.rim_beats[step], .09,
                (step % 2 == 0 ? .15 : .11) * score.percussion, step % 2 == 0 ? .26 : -.26);
        }
        if (response) {
            note(score.answer, chord[2] + 12, .43, score.meter - .74, .14, .32);
            note(Cello, chord[3] - 12, .59, score.meter - 1.02, .15, -.38);
        }
        if (score.title_echo && reprise) {
            // The title's opening contour returns as a high answer against the boss ostinato.
            constexpr std::array<std::array<int, 3>, 4> echo{{{81, 86, 84}, {82, 86, 84}, {79, 83, 81}, {81, 85, 79}}};
            note(Celeste, echo[index - 8][0], .25, .44, .21, .42);
            note(Celeste, echo[index - 8][1], 1.35, .48, .20, .43);
            note(Celeste, echo[index - 8][2], 2.66, .59, .17, .44);
        }
    }
    mix.mix_room(score.room);
    mix.soften_loop_seam();
    mix.save(std::string("assets/audio/music/") + score.name + "_boss.ogg", ogg_vorbis, .62);
}

using PrologueLine = std::array<int, 8>;
using PrologueTimes = std::array<double, 8>;

// The title's opening question and its rising answer carry through the prologue.
constexpr PrologueLine prologue_motif{72, 76, 74, 69, 72, 76, 79, 76};
constexpr PrologueLine prologue_shadow{72, 75, 74, 68, 72, 75, 78, 75};

void prologue_phrase(Mix& mix, Instrument instrument, const PrologueTimes& onsets, double gain,
        double pan, double legato, int octave = 0, const PrologueLine& notes = prologue_motif) {
    constexpr std::array<double, 8> accents{1.0, .78, .85, .72, .95, .77, .92, .63};
    for (int i = 0; i < int(notes.size()); ++i) {
        double interval = i < int(notes.size()) - 1 ? onsets[i + 1] - onsets[i] : .80;
        mix.note(instrument, notes[i] + octave, onsets[i], std::clamp(interval * legato, .12, 1.16),
            gain * accents[i], pan);
    }
}

void prologue_chord(Mix& mix, Instrument instrument, std::initializer_list<int> notes, double start,
        double hold, double spread, double gain) {
    int index = 0;
    for (int pitch : notes) {
        mix.note(instrument, pitch, start + index * spread, hold, gain * (index == 0 ? 1.0 : .76),
            (index - 1) * .22);
        ++index;
    }
}

void save_prologue(Mix& mix, const std::string& scene, double room) {
    mix.mix_room(room);
    mix.save("assets/audio/music/prologue_" + scene + ".ogg", ogg_vorbis, .58);
}

void render_prologue_music() {
    {
        // The Creator. Bare felt keys, a hovering flute response and wide, open harmony.
        Mix mix(5.90, false);
        prologue_chord(mix, Felt, {48, 55, 62, 67}, .05, .86, .094, .15);
        prologue_chord(mix, Harp, {53, 57, 64}, 2.25, .68, .11, .087);
        mix.note(Cello, 48, .26, 1.58, .052, -.27);
        mix.note(Cello, 41, 2.26, 1.17, .053, -.27);
        prologue_phrase(mix, Felt, {.60, 1.04, 1.53, 2.30, 2.81, 3.24, 3.79, 4.45}, .25, -.13, .85);
        mix.note(Flute, 79, 3.90, .42, .063, .28);
        mix.note(Flute, 76, 4.46, .57, .052, .24);
        prologue_chord(mix, Felt, {48, 55, 64, 72}, 4.63, .65, .044, .10);
        save_prologue(mix, "creator", .56);
    }
    {
        // Something blooms. Rolling harp triplets, celeste and a rising string thread.
        Mix mix(7.24, false);
        constexpr int beds[4][4]{{48, 60, 64, 67}, {53, 60, 65, 69}, {45, 60, 64, 67}, {43, 59, 62, 67}};
        for (int bar = 0; bar < 4; ++bar) {
            const double start = .08 + 1.52 * bar;
            mix.note(Pizz, beds[bar][0], start, .31, .105, -.24);
            constexpr std::array<int, 6> order{0, 1, 2, 3, 2, 1};
            for (int step = 0; step < int(order.size()); ++step) {
                mix.note(Harp, beds[bar][order[step]], start + .235 * step, .38,
                    .104 - .006 * (step % 3), -.35 + .12 * step);
            }
        }
        prologue_phrase(mix, Celeste, {.71, 1.18, 1.68, 2.81, 3.36, 3.84, 4.36, 5.01}, .19, .22, .75);
        mix.note(Viola, 60, .94, 1.40, .069, -.34);
        mix.note(Viola, 65, 2.38, 1.52, .074, -.34);
        mix.note(Flute, 77, 5.28, .37, .075, .32);
        mix.note(Flute, 76, 5.72, .30, .072, .32);
        mix.note(Flute, 72, 6.06, .46, .072, .32);
        prologue_chord(mix, Harp, {48, 55, 62, 64}, 6.05, .53, .065, .125);
        save_prologue(mix, "bloom", .44);
    }
    {
        // Happiness. The same tune is a picnic waltz led by flute and plucked strings.
        Mix mix(6.96, false);
        constexpr int chords[4][4]{{48, 55, 64, 67}, {45, 52, 60, 64}, {41, 53, 57, 60}, {43, 55, 59, 62}};
        for (int bar = 0; bar < 4; ++bar) {
            const double start = .09 + bar * 1.47;
            mix.note(Pizz, chords[bar][0], start, .29, .16, -.28);
            for (int offbeat = 1; offbeat <= 2; ++offbeat) {
                const double pickup = start + offbeat * .49;
                mix.note(Felt, chords[bar][2], pickup, .23, .10, .15);
                mix.note(Pizz, chords[bar][3], pickup + .018, .211, .073, -.02);
            }
            mix.note(Harp, chords[bar][1], start + .75, .26, .062, .40);
        }
        prologue_phrase(mix, Flute, {.45, .93, 1.45, 2.09, 2.69, 3.11, 3.63, 4.18}, .20, .15, .86);
        mix.note(Reed, 67, 2.21, .24, .069, -.31);
        mix.note(Reed, 72, 2.59, .23, .056, -.30);
        mix.note(Reed, 74, 4.62, .26, .066, -.27);
        mix.note(Flute, 72, 5.39, .80, .135, .15);
        prologue_chord(mix, Felt, {48, 55, 64, 69}, 5.88, .51, .042, .155);
        save_prologue(mix, "happiness", .31);
    }
    {
        // Corruption. The familiar steps darken over a cello pedal and suspended viola.
        Mix mix(7.40, false);
        prologue_chord(mix, Felt, {36, 48, 55, 63}, .04, 1.02, .115, .134);
        mix.note(Cello, 36, .17, 2.12, .11, -.25);
        mix.note(Cello, 44, 2.37, 1.75, .088, -.25);
        mix.note(Cello, 42, 4.20, 1.19, .096, -.23);
        mix.note(Viola, 55, 1.48, 1.18, .070, .30);
        mix.note(Viola, 54, 2.68, 2.61, .083, .34);
        prologue_phrase(mix, Cello, {.72, 1.26, 1.94, 2.66, 3.15, 3.67, 4.25, 5.24}, .17, -.09, 1.12, -12, prologue_shadow);
        mix.note(Celeste, 75, 1.29, .47, .070, .45);
        mix.note(Celeste, 78, 4.26, .50, .092, .38);
        mix.note(Felt, 62, 5.74, .52, .104, .13);
        prologue_chord(mix, Felt, {36, 48, 54, 62}, 6.04, .66, .025, .11);
        save_prologue(mix, "corruption", .66);
    }
    {
        // Adventure. Plucked motion gives way to a small horn-and-flute reprise and a home cadence.
        Mix mix(8.72, false);
        constexpr int routes[4][4]{{45, 52, 60, 64}, {41, 53, 60, 65}, {43, 55, 62, 67}, {48, 55, 64, 67}};
        for (int bar = 0; bar < 4; ++bar) {
            const double start = .12 + bar * 1.68;
            mix.note(Cello, routes[bar][0], start, .68, .16, -.23);
            mix.note(Pizz, routes[bar][1], start + .81, .35, .10, -.29);
            mix.note(Timpani, routes[bar][0], start + .016, .15, .069 + .017 * bar, -.05);
            for (int turn = 0; turn < 4; ++turn) {
                mix.note(Harp, routes[bar][turn], start + .40 * turn, .28, .097, .21);
                mix.note(Viola, routes[bar][2 + turn % 2], start + .08 + .40 * turn, .24, .050, .37);
            }
        }
        prologue_phrase(mix, Horn, {.65, 1.12, 1.67, 2.67, 3.13, 3.61, 4.11, 4.87}, .21, -.09, .88);
        prologue_phrase(mix, Flute, {.68, 1.15, 1.70, 2.71, 3.17, 3.65, 4.15, 4.92}, .076, .31, .83, 12);
        prologue_chord(mix, Harp, {48, 55, 64, 67, 72}, 6.06, .61, .095, .13);
        mix.note(Horn, 67, 5.84, .45, .115, -.10);
        mix.note(Horn, 72, 6.37, .94, .18, -.10);
        mix.note(Flute, 76, 6.47, .81, .11, .30);
        mix.note(Cello, 48, 6.38, 1.16, .15, -.27);
        mix.note(Celeste, 84, 7.46, .43, .10, .18);
        save_prologue(mix, "adventure", .42);
    }
}

void prologue_rustle(Mix& mix, double at, double duration, double intensity, double pan,
        double lowpass, double flutter) {
    const int start = int(at * rate);
    const double left = std::sqrt((1.0 - pan) * .5);
    const double right = std::sqrt((1.0 + pan) * .5);
    double air = 0.0;
    double body = 0.0;
    for (int frame = 0; frame < int(duration * rate); ++frame) {
        const double t = double(frame) / rate;
        air += lowpass * (mix.white() - air);
        body += .012 * (air - body);
        const double breath = smooth(t / .075) * smooth((duration - t) / .21);
        const double motion = .76 + .17 * wave(t * flutter) + .07 * wave(t * 2.3 + .3);
        mix.put(start + frame, intensity * (air - .65 * body) * breath * motion, left, right);
    }
}

void render_prologue_sfx() {
    {
        Mix mix(1.32, false);
        prologue_rustle(mix, .02, 1.14, .39, -.20, .13, 19.2);
        prologue_rustle(mix, .13, .87, .27, .30, .08, 15.0);
        constexpr std::array<double, 8> drops{.05, .14, .22, .33, .41, .58, .76, .93};
        for (int i = 0; i < int(drops.size()); ++i) {
            double start = drops[i];
            double pitch = 680.0 + 100.0 * (i % 4);
            mix.texture(start, .16 + .01 * (i % 3), pitch, pitch * .56, .15 - .008 * i,
                .43, 22.0, (i % 3 - 1) * .34);
        }
        mix.mix_room(.20);
        mix.save("assets/audio/sfx/prologue_water.wav", wav_pcm, .34);
    }
    {
        Mix mix(.94, false);
        prologue_rustle(mix, .0, .50, .29, -.16, .09, 9.1);
        mix.texture(.02, .15, 80.0, 213.0, .16, .60, 23.0, -.13);
        mix.note(Harp, 69, .108, .14, .29, -.32);
        mix.note(Harp, 72, .202, .17, .32, .03);
        mix.note(Celeste, 79, .303, .22, .36, .28);
        mix.note(Harp, 84, .41, .20, .18, .04);
        mix.mix_room(.31);
        mix.save("assets/audio/sfx/prologue_sprout.wav", wav_pcm, .33);
    }
    {
        // Picnic textures and porcelain, with birds in the distance.
        Mix mix(1.62, false);
        prologue_rustle(mix, .01, 1.48, .32, -.23, .052, 3.6);
        prologue_rustle(mix, .19, 1.24, .16, .35, .076, 5.7);
        mix.note(Celeste, 90, .167, .16, .18, -.22);
        mix.texture(.171, .087, 3100, 2350, .18, .30, 23, -.21);
        mix.note(Celeste, 84, .261, .12, .076, -.16);
        mix.texture(.74, .16, 1710, 2220, .067, .18, 9, .58);
        mix.texture(.97, .10, 2190, 1800, .063, .15, 13, .55);
        mix.texture(1.16, .12, 2030, 2230, .048, .19, 14, .47);
        mix.mix_room(.25);
        mix.save("assets/audio/sfx/prologue_laughter.wav", wav_pcm, .26);
    }
    {
        Mix mix(1.19, false);
        prologue_rustle(mix, .02, 1.01, .38, -.24, .075, 13.0);
        mix.texture(.04, .78, 170.0, 63.0, .20, .28, 3.4, .09);
        constexpr std::array<double, 5> joints{.13, .255, .367, .536, .692};
        for (int i = 0; i < int(joints.size()); ++i) {
            const double at = joints[i];
            const double sided = (i % 2 == 0 ? -.1 : .35);
            mix.note(Woodblock, 61 - i * 3, at, .073, .26 - .028 * i, sided);
            mix.texture(at + .007, .105, 620.0 - i * 62.0, 166.0, .19, .64, 23.0, sided);
        }
        mix.note(Timpani, 34, .48, .25, .135, -.10);
        mix.mix_room(.37);
        mix.save("assets/audio/sfx/prologue_thorns.wav", wav_pcm, .40);
    }
    {
        Mix mix(.81, false);
        mix.texture(.0, .127, 232, 455, .15, .80, 15.0, -.25);
        mix.texture(.095, .25, 2270, 2900, .29, .76, 7.8, -.15);
        mix.texture(.144, .24, 1360, 867, .17, .35, 8.0, .23);
        mix.note(Celeste, 91, .197, .17, .225, .20);
        mix.note(Celeste, 96, .268, .12, .115, .36);
        mix.mix_room(.27);
        mix.save("assets/audio/sfx/prologue_draw.wav", wav_pcm, .37);
    }
}

void render_sfx(const std::string& name) {
    const bool bright = name == "chest" || name == "reward" || name == "clear" || name == "board_win";
    const bool long_cue = name == "boss_enter" || name == "ultimate" || name == "fall" || name == "boss_triumph";
    const double seconds = name == "boss_triumph" ? 1.48 : (long_cue ? 0.99 : (bright ? 0.88 : 0.37));
    Mix mix(seconds, false);
    if (name == "ui") {
        mix.note(Harp, 78, 0.0, 0.042, .53, 0);
        mix.texture(0.0, .05, 490, 390, .14, .81, 30);
    } else if (name == "confirm") {
        mix.note(Celeste, 74, 0.0, .073, .52, -.05);
        mix.note(Harp, 81, .067, .092, .38, .12);
    } else if (name == "cancel") {
        mix.note(Felt, 71, .0, .055, .40, 0);
        mix.note(Felt, 63, .055, .070, .24, -.1);
    } else if (name == "angela") {
        mix.texture(0, .18, 1040, 1785, .37, .73, 7, -.14);
        mix.texture(.028, .21, 2210, 1530, .32, .13, 15, .18);
    } else if (name == "vivianne") {
        mix.note(Celeste, 79, 0, .12, .41, -.26);
        mix.note(Celeste, 86, .066, .129, .29, .26);
        mix.texture(0, .21, 1200, 2100, .15, .64, 6);
    } else if (name == "nixia") {
        mix.texture(0, .145, 210, 126, .65, .32, 21);
        mix.texture(.039, .088, 490, 600, .34, .74, 24, .19);
    } else if (name == "virelia") {
        mix.texture(0, .125, 152, 420, .52, .16, 15, .12);
        mix.texture(.025, .22, 2200, 1420, .25, .83, 9, -.19);
    } else if (name == "zaria") {
        mix.texture(0, .14, 1450, 2220, .42, .66, 9, -.39);
        mix.texture(.045, .14, 2080, 1310, .39, .70, 10, .31);
    } else if (name == "dodge") {
        mix.texture(0, .216, 1290, 380, .46, .85, 7.4);
        mix.texture(.012, .177, 270, 105, .20, .52, 9.0);
    } else if (name == "hit") {
        mix.texture(0, .105, 390, 120, .48, .42, 22);
        mix.texture(.015, .093, 689, 530, .27, .66, 22, .12);
    } else if (name == "hurt") {
        mix.texture(0, .221, 200, 60, .67, .30, 14);
        mix.texture(.017, .12, 414, 249, .28, .64, 14);
    } else if (name == "guard") {
        mix.texture(0, .14, 2245, 1210, .46, .18, 13);
        mix.note(Celeste, 91, .025, .08, .37, .1);
        mix.texture(.046, .091, 167, 105, .17, .40, 18);
    } else if (name == "warning") {
        mix.note(Harp, 82, 0, .085, .39, 0);
        mix.texture(.032, .18, 490, 780, .28, .11, 10);
    } else if (name == "warning_boss") {
        mix.note(Celeste, 69, 0, .13, .39, -.25);
        mix.note(Celeste, 74, .075, .13, .28, .25);
    } else if (name == "chest") {
        mix.texture(0, .13, 373, 119, .27, .66, 18);
        mix.texture(.091, .15, 710, 460, .15, .64, 16);
        mix.note(Celeste, 76, .13, .18, .37, -.15);
        mix.note(Celeste, 81, .23, .17, .30, .2);
        mix.note(Harp, 84, .35, .23, .20, .05);
    } else if (name == "reward" || name == "clear") {
        const int root = name == "clear" ? 72 : 74;
        for (int i = 0; i < 4; ++i)
            mix.note(i == 3 ? Flute : Celeste, root + std::array<int, 4>{0, 4, 7, 12}[i], i * .092, .29, .37 - .045 * i, .12 * (i - 1));
        mix.note(Harp, root - 12, .064, .44, .25, -.25);
    } else if (name == "boss_enter") {
        mix.note(Drum, 38, 0, .19, .58, 0);
        mix.note(Viola, 43, .045, .38, .38, -.29);
        mix.note(Viola, 54, .104, .36, .27, .28);
        mix.note(Celeste, 75, .29, .32, .16, .12);
    } else if (name == "ultimate") {
        mix.texture(0, .52, 270, 1880, .43, .68, 1.2);
        mix.note(Harp, 72, .095, .12, .22, -.30);
        mix.note(Celeste, 79, .205, .21, .37, .30);
        mix.note(Celeste, 84, .305, .32, .38, 0);
        mix.note(Drum, 36, .298, .18, .28, 0);
    } else if (name == "fall") {
        mix.note(Felt, 64, .0, .27, .46, -.06);
        mix.note(Felt, 59, .16, .23, .41, .10);
        mix.note(Viola, 50, .25, .39, .33, 0);
    } else if (name == "enemy_blade") {
        mix.texture(0, .18, 570, 2290, .52, .67, 10, -.21);
        mix.texture(.057, .18, 2410, 714, .47, .36, 12, .18);
        mix.texture(.079, .13, 151, 80, .28, .28, 22);
    } else if (name == "enemy_spore") {
        mix.texture(0, .24, 173, 350, .61, .21, 8);
        mix.texture(.078, .19, 720, 320, .32, .66, 12, .23);
        mix.note(Woodblock, 65, .024, .06, .28, -.35);
    } else if (name == "enemy_gear") {
        mix.texture(0, .20, 1941, 653, .40, .42, 9);
        mix.note(Woodblock, 77, .034, .079, .44, .24);
        mix.note(Woodblock, 69, .092, .063, .26, -.28);
    } else if (name == "enemy_arcane") {
        mix.texture(0, .32, 1160, 508, .43, .34, 7);
        mix.note(Celeste, 82, .018, .087, .25, -.28);
        mix.note(Celeste, 73, .084, .12, .23, .30);
    } else if (name == "enemy_crash") {
        mix.texture(0, .24, 163, 51, .66, .48, 10, -.07);
        mix.note(Timpani, 37, .016, .12, .37, 0);
        mix.texture(.03, .18, 1440, 511, .29, .67, 14, .25);
    } else if (name == "boss_break") {
        mix.texture(0, .29, 112, 49, .64, .27, 9, 0);
        mix.texture(.015, .25, 2250, 1900, .55, .79, 17, -.11);
        mix.note(Drum, 33, .03, .2, .37, .06);
    } else if (name == "boss_bark") {
        mix.note(Timpani, 35, .0, .18, .55, 0);
        mix.texture(.012, .29, 509, 252, .48, .85, 12, .15);
        mix.note(Woodblock, 68, .07, .12, .23, -.35);
    } else if (name == "boss_crown") {
        mix.texture(0, .21, 244, 57, .53, .50, 11, 0);
        mix.note(Celeste, 91, .036, .098, .49, -.28);
        mix.note(Celeste, 84, .143, .105, .28, .28);
        mix.note(Woodblock, 77, .249, .046, .24, .36);
    } else if (name == "boss_gear") {
        for (int i = 0; i < 4; ++i)
            mix.note(Woodblock, 75 - i * 5, i * .059, .07, .51 - .080 * i, i * .22 - .32);
        mix.texture(.016, .30, 1342, 241, .44, .50, 11);
    } else if (name == "boss_porcelain") {
        mix.texture(0, .28, 2996, 870, .58, .89, 11, 0);
        mix.note(Celeste, 89, .013, .12, .39, -.36);
        mix.note(Celeste, 81, .072, .15, .32, .40);
        mix.note(Celeste, 93, .14, .09, .16, .12);
    } else if (name == "boss_star") {
        mix.texture(0, .29, 398, 1699, .41, .34, 5, -.24);
        mix.note(Celeste, 81, .026, .19, .33, -.26);
        mix.note(Celeste, 88, .092, .16, .43, .29);
        mix.note(Harp, 93, .162, .19, .26, .03);
    } else if (name == "boss_triumph") {
        constexpr std::array<int, 5> pitches{65, 69, 72, 76, 77};
        constexpr std::array<double, 5> times{.15, .26, .39, .52, .72};
        for (int i = 0; i < 5; ++i) {
            mix.note(i < 3 ? Harp : Celeste, pitches[i] + 12, times[i], .45, .35, (i - 2) * .17);
            mix.note(Horn, pitches[i], times[i] + .01, .47, .25, .02);
        }
        mix.note(Cello, 41, .146, .51, .32, -.26);
        mix.note(Timpani, 41, .71, .25, .22, 0);
    } else if (name == "board_move") {
        mix.note(Woodblock, 80, .0, .061, .51, -.06);
        mix.note(Harp, 79, .027, .077, .28, .14);
    } else if (name == "board_win") {
        for (int i = 0; i < 4; ++i)
            mix.note(i % 2 == 0 ? Harp : Celeste, std::array<int, 4>{76, 79, 84, 88}[i],
                i * .098, .24, .39 - i * .047, i * .24 - .33);
    } else if (name == "board_loss") {
        mix.note(Pizz, 69, .0, .09, .51, -.12);
        mix.note(Woodblock, 60, .092, .065, .37, .16);
        mix.note(Pizz, 59, .139, .13, .38, -.03);
    }
    mix.mix_room(long_cue || bright ? 0.32 : 0.17);
    mix.save("assets/audio/sfx/" + name + ".wav", wav_pcm, name.rfind("warning", 0) == 0 ? 0.49 : 0.67);
}

void render_upgrade_sfx() {
    {
        Mix pick(.72, false);
        pick.note(Harp, 69, .012, .16, .40, -.21);
        pick.note(Harp, 76, .108, .22, .37, .05);
        pick.note(Celeste, 81, .224, .27, .46, .19);
        pick.texture(.02, .17, 530.0, 1960.0, .15, .71, 13.0, -.31);
        pick.mix_room(.27);
        pick.save("assets/audio/sfx/upgrade_pick.wav", wav_pcm, .49);
    }
    {
        Mix guard(.42, false);
        guard.texture(0, .18, 130, 47, .35, .32, 16, 0);
        guard.note(Harp, 71, .035, .075, .52, -.26);
        guard.note(Celeste, 89, .063, .16, .37, .20);
        guard.texture(.067, .24, 1250, 2730, .29, .59, 9, .26);
        guard.mix_room(.18);
        guard.save("assets/audio/sfx/upgrade_guard.wav", wav_pcm, .54);
    }
}

void render_arcade_sfx() {
    {
        Mix cue(.16, false);
        cue.note(Woodblock, 72, 0, .06, .48, -.20);
        cue.texture(.012, .09, 380, 721, .25, .66, 29, .08);
        cue.save("assets/audio/sfx/kart_pedal.wav", wav_pcm, .31);
    }
    {
        Mix cue(.33, false);
        cue.texture(0, .22, 123, 49, .56, .52, 13);
        cue.note(Woodblock, 55, .04, .06, .24, .16);
        cue.texture(.066, .19, 800, 191, .28, .75, 15, -.18);
        cue.save("assets/audio/sfx/kart_bump.wav", wav_pcm, .48);
    }
    {
        Mix cue(.52, false);
        cue.texture(0, .39, 114, 615, .45, .35, 5);
        cue.note(Celeste, 72, .07, .10, .33, -.17);
        cue.note(Celeste, 79, .155, .22, .35, .25);
        cue.save("assets/audio/sfx/kart_boost.wav", wav_pcm, .47);
    }
    {
        Mix cue(.39, false);
        cue.note(Harp, 77, .0, .11, .37, -.23);
        cue.note(Celeste, 84, .079, .19, .53, .22);
        cue.mix_room(.11);
        cue.save("assets/audio/sfx/arcade_collect.wav", wav_pcm, .43);
    }
    {
        Mix cue(.29, false);
        cue.note(Woodblock, 62, .0, .049, .45, -.14);
        cue.note(Pizz, 47, .046, .15, .48, .18);
        cue.save("assets/audio/sfx/arcade_miss.wav", wav_pcm, .45);
    }
    constexpr std::array<int, 4> organ{62, 65, 69, 74};
    for (size_t i = 0; i < organ.size(); ++i) {
        Mix cue(.51, false);
        cue.note(Celeste, organ[i] + 12, .009, .18, .40, 0);
        cue.note(Harp, organ[i], .017, .30, .46, double(i) * .21 - .315);
        cue.mix_room(.18);
        cue.save("assets/audio/sfx/encore_" + std::to_string(i) + ".wav", wav_pcm, .51);
    }
}

int main(int argc, char** argv) {
    const bool sfx_only = argc == 2 && std::string(argv[1]) == "--sfx-only";
    const bool boss_only = argc == 2 && std::string(argv[1]) == "--boss-only";
    const bool feedback = argc == 2 && std::string(argv[1]) == "--feedback";
    const bool prologue_only = argc == 2 && std::string(argv[1]) == "--prologue-only";
    const bool upgrade_only = argc == 2 && std::string(argv[1]) == "--upgrade-only";
    const bool arcade_only = argc == 2 && std::string(argv[1]) == "--arcade-only";
    if (argc > 1 && !sfx_only && !boss_only && !feedback && !prologue_only && !upgrade_only && !arcade_only) {
        std::cerr << "Usage: render_audio [--boss-only | --sfx-only | --feedback | --prologue-only | --upgrade-only | --arcade-only]\n";
        return 1;
    }
    if (arcade_only) {
        for (const auto& score : arcade_tracks) render_trail(score);
        render_arcade_sfx();
        std::cout << "Rendered four game tracks and nine sound effects.\n";
        return 0;
    }
    if (upgrade_only) {
        render_upgrade_sfx();
        std::cout << "Rendered two upgrade sound effects.\n";
        return 0;
    }
    if (prologue_only) {
        render_prologue_music();
        render_prologue_sfx();
        std::cout << "Rendered five prologue score cues and five prologue sound effects.\n";
        return 0;
    }
    if (boss_only) {
        for (const auto& score : bosses) render_boss(score);
            for (const auto& score : arcade_tracks) render_trail(score);
        std::cout << "Rendered seven original boss themes.\n";
        return 0;
    }
    if (!sfx_only) {
        for (const auto& score : trails) render_trail(score);
        if (!feedback) {
            for (const auto& score : menus) render_score(score);
            for (const auto& score : bosses) render_boss(score);
            render_prologue_music();
        }
    }
    if (!feedback) {
        for (const char* sample : {"ui", "confirm", "cancel", "angela", "vivianne", "nixia", "virelia", "zaria",
                "dodge", "hit", "hurt", "guard", "warning", "warning_boss", "chest", "reward", "clear",
                "boss_enter", "ultimate", "fall"}) {
            render_sfx(sample);
        }
    }
    for (const char* sample : {"enemy_blade", "enemy_spore", "enemy_gear", "enemy_arcane", "enemy_crash",
            "boss_break", "boss_bark", "boss_crown", "boss_gear", "boss_porcelain", "boss_star",
            "boss_triumph", "board_move", "board_win", "board_loss"}) {
        render_sfx(sample);
    }
    if (!feedback) {
        render_prologue_sfx();
        render_upgrade_sfx();
        render_arcade_sfx();
    }
    std::cout << "Rendered " << (feedback ? 15 : 51) << " original sound effects";
    if (!sfx_only) std::cout << " and " << (feedback ? 8 : 32) << " instrumental loops";
    if (!sfx_only && !feedback) std::cout << " plus five prologue score cues";
    std::cout << ".\n";
}
