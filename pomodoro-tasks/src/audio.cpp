#include "audio.h"
#include <pulse/simple.h>
#include <pulse/error.h>
#include <cmath>
#include <algorithm>
#include <vector>
#include <thread>
#include <atomic>

static constexpr int   RATE = 44100;
static constexpr float PI2  = 2.0f * M_PI;

// ── DSP primitives ────────────────────────────────────────────────────────────

// Sine with smooth exponential release (no hard cutoff)
// attack_s: linear ramp up; body_s: sustain; release_s: exponential decay tail
static std::vector<float> sine_tone(float freq, float attack_s, float body_s,
                                     float release_s, float peak_vol) {
    int total = (int)((attack_s + body_s + release_s) * RATE);
    std::vector<float> buf(total);
    for (int i = 0; i < total; ++i) {
        float t = (float)i / RATE;
        float env;
        if (t < attack_s) {
            // smooth S-curve attack (sine ease-in)
            float x = t / attack_s;
            env = 0.5f - 0.5f * std::cos(x * M_PI);
        } else if (t < attack_s + body_s) {
            env = 1.0f;
        } else {
            // exponential decay tail — no hard stop
            float tr = t - attack_s - body_s;
            env = std::exp(-4.5f * tr / release_s);
        }
        buf[i] = std::sin(PI2 * freq * t) * env * peak_vol;
    }
    return buf;
}

// Mix two float buffers (pads shorter with zeros)
static std::vector<float> fmix(const std::vector<float>& a,
                                const std::vector<float>& b, float gain_b = 1.0f) {
    size_t n = std::max(a.size(), b.size());
    std::vector<float> out(n, 0.f);
    for (size_t i = 0; i < a.size(); ++i) out[i] += a[i];
    for (size_t i = 0; i < b.size(); ++i) out[i] += b[i] * gain_b;
    return out;
}

// Offset a buffer by delay_s seconds (prepend silence)
static std::vector<float> delay(const std::vector<float>& src, float delay_s) {
    int d = (int)(delay_s * RATE);
    std::vector<float> out(d, 0.f);
    out.insert(out.end(), src.begin(), src.end());
    return out;
}

// Schroeder allpass filter — adds diffuse reverb tail without coloring pitch
static void allpass_inplace(std::vector<float>& buf, int delay_smp, float gain) {
    std::vector<float> dline(delay_smp, 0.f);
    int pos = 0;
    for (auto& s : buf) {
        float d = dline[pos];
        float w = s + gain * d;
        dline[pos] = w;
        s = d - gain * w;
        if (++pos >= delay_smp) pos = 0;
    }
}

// Lightweight reverb: 2 allpass stages tuned for short, airy tail
static void add_reverb(std::vector<float>& buf, float wet = 0.18f) {
    std::vector<float> rev = buf;
    allpass_inplace(rev, (int)(0.0297f * RATE), 0.7f);
    allpass_inplace(rev, (int)(0.0071f * RATE), 0.7f);
    for (size_t i = 0; i < buf.size() && i < rev.size(); ++i)
        buf[i] = buf[i] * (1.f - wet) + rev[i] * wet;
}

// Convert float buffer to int16 with soft clip
static std::vector<int16_t> to_pcm(const std::vector<float>& buf) {
    std::vector<int16_t> out(buf.size());
    for (size_t i = 0; i < buf.size(); ++i) {
        float s = buf[i];
        // soft clip via tanh
        s = std::tanh(s * 1.2f) / 1.2f;
        out[i] = (int16_t)(std::clamp(s, -1.f, 1.f) * 32767.f);
    }
    return out;
}

static void play_pcm(std::vector<int16_t> buf) {
    pa_sample_spec ss{ PA_SAMPLE_S16LE, (uint32_t)RATE, 1 };
    // Small buffer to avoid blocking on drain; latency ~100ms is fine for notifications
    pa_buffer_attr attr{};
    attr.maxlength = (uint32_t)-1;
    attr.tlength   = pa_usec_to_bytes(100000, &ss); // 100ms
    attr.prebuf    = (uint32_t)-1;
    attr.minreq    = (uint32_t)-1;
    attr.fragsize  = (uint32_t)-1;
    int err = 0;
    pa_simple* s = pa_simple_new(nullptr, "pomodoro-tasks", PA_STREAM_PLAYBACK,
                                  nullptr, "sound", &ss, nullptr, &attr, &err);
    if (!s) return;
    pa_simple_write(s, buf.data(), buf.size() * sizeof(int16_t), &err);
    pa_simple_drain(s, &err);
    pa_simple_free(s);
}

static void play_async(std::vector<float> fbuf, float wet = 0.18f) {
    add_reverb(fbuf, wet);
    auto pcm = to_pcm(fbuf);
    std::thread([b = std::move(pcm)]() mutable { play_pcm(std::move(b)); }).detach();
}

// ── Focus start — 3 variants round-robin ─────────────────────────────────────

static std::atomic<int> focus_variant{0};

// Pack definitions: { fundamental_hz, octave_mul, sub_mul, fifth_mul, body_s, reverb_wet }
struct PackDef {
    float fund;       // fundamental frequency
    float rev_wet;    // reverb wetness
    float body_s;     // base body duration
};

static PackDef current_pack = { 220.f, 0.18f, 0.60f };  // minimal default

void Audio::set_pack(const std::string& name) {
    if      (name == "ambient")  current_pack = { 98.f,  0.30f, 0.90f };  // G2 — deep, meditative
    else if (name == "crystal")  current_pack = { 293.f, 0.12f, 0.40f };  // D4 — bright, ethereal
    else                         current_pack = { 220.f, 0.18f, 0.60f };  // A3 — minimal (default)
}

struct FocusVariant { float pitch_mul; float body_mul; };
static constexpr FocusVariant FOCUS_VARIANTS[3] = {
    { 1.000f, 1.00f },
    { 1.030f, 0.85f },
    { 0.972f, 1.20f },
};

void Audio::play_focus_start(const AppState::SoundCfg& cfg) {
    int vi = focus_variant.fetch_add(1) % 3;
    const auto& vp = FOCUS_VARIANTS[vi];
    float p   = cfg.pitch * vp.pitch_mul;
    float v   = 0.30f * cfg.volume;
    float bd  = current_pack.body_s * vp.body_mul;
    float f   = current_pack.fund * p;

    auto fund  = sine_tone(f,       0.55f, bd,        1.20f, v);
    auto oct   = delay(sine_tone(f*2.f, 0.40f, bd*0.7f, 1.00f, v*0.45f), 0.08f);
    auto sub   = sine_tone(f*0.5f,  0.70f, bd*0.5f,   0.90f, v*0.22f);
    auto fifth = delay(sine_tone(f*1.5f, 0.35f, bd*0.4f, 0.80f, v*0.18f), 0.12f);

    auto mixed = fmix(fmix(fund, oct), fmix(sub, fifth));
    play_async(std::move(mixed), current_pack.rev_wet);
}

// ── Break / Long Break — calm, slow swell ────────────────────────────────────

void Audio::play_break(const AppState::SoundCfg& cfg) {
    float p = cfg.pitch;
    float v = 0.42f * cfg.volume;  // louder
    float root = current_pack.fund * p * 0.5f;

    auto base  = sine_tone(root,        0.70f, 0.10f, 2.20f, v);
    auto fifth = delay(sine_tone(root * 1.50f, 0.80f, 0.00f, 1.80f, v * 0.55f), 0.35f);
    auto sev   = delay(sine_tone(root * 1.78f, 0.90f, 0.00f, 1.50f, v * 0.35f), 0.65f);

    auto mixed = fmix(fmix(base, fifth), sev);
    play_async(std::move(mixed), 0.50f);
}

// ── Pause — single soft descending two-note sigh ─────────────────────────────

void Audio::play_pause(const AppState::SoundCfg& cfg) {
    float p = cfg.pitch;
    float v = 0.28f * cfg.volume;
    float root = current_pack.fund * p * 2.0f;

    // Two notes descending a minor third — "winding down"
    auto hi = sine_tone(root,        0.02f, 0.05f, 0.55f, v);
    auto lo = delay(sine_tone(root * 0.84f, 0.02f, 0.05f, 0.70f, v * 0.85f), 0.18f);

    auto mixed = fmix(hi, lo);
    play_async(std::move(mixed), 0.25f);
}

// ── Task done ─────────────────────────────────────────────────────────────────

void Audio::play_task_done(const AppState::SoundCfg& cfg) {
    float p = cfg.pitch;
    float v = 0.28f * cfg.volume;
    float root = current_pack.fund * p * 2.4f;

    auto n1  = sine_tone(root,        0.006f, 0.0f, 1.10f, v);
    auto n2  = sine_tone(root*1.26f,  0.006f, 0.0f, 1.00f, v*0.95f);
    auto n3  = sine_tone(root*1.50f,  0.006f, 0.0f, 0.95f, v*0.90f);
    auto n3h = sine_tone(root*2.0f,   0.006f, 0.0f, 0.70f, v*0.25f);

    float gap = 0.160f;
    auto mixed = fmix(
        fmix(n1, delay(n2, gap)),
        fmix(delay(n3, gap*2.f), delay(n3h, gap*2.f))
    );
    play_async(std::move(mixed), current_pack.rev_wet);
}

// ── Task done — bright ascending fanfare, clearly distinct from break ─────────

void Audio::play_relax(const AppState::SoundCfg& cfg) {
    float p = cfg.pitch;
    float v = 0.32f * cfg.volume;
    // Root in a bright register (2× fundamental)
    float r = current_pack.fund * p * 2.0f;

    // Four notes of a major chord ascending with short gaps — "achievement" feel
    // Each note: fast attack, short body, medium release
    auto n1 = sine_tone(r,        0.01f, 0.08f, 0.45f, v);           // root
    auto n2 = delay(sine_tone(r * 1.25f, 0.01f, 0.08f, 0.45f, v),    0.13f); // major 3rd
    auto n3 = delay(sine_tone(r * 1.50f, 0.01f, 0.08f, 0.50f, v),    0.26f); // perfect 5th
    auto n4 = delay(sine_tone(r * 2.00f, 0.01f, 0.12f, 0.70f, v * 1.1f), 0.39f); // octave — rings out

    // Subtle shimmer on top
    auto shim = delay(sine_tone(r * 3.0f, 0.01f, 0.0f, 0.30f, v * 0.18f), 0.42f);

    auto mixed = fmix(fmix(n1, n2), fmix(fmix(n3, n4), shim));
    play_async(std::move(mixed), 0.20f); // light reverb — keep it crisp
}
