// typing_sounds_daemon — global typing sounds via libevdev + PulseAudio
// Reads /dev/input/event* (requires input group), plays droplet sounds per key.
// Config file: ~/.config/pomodoro-tasks/typing.conf
// Modes: random (pentatonic) | fixed (key→note mapping)

#include <libevdev/libevdev.h>
#include <pulse/simple.h>
#include <pulse/error.h>
#include <linux/input-event-codes.h>

#include <cmath>
#include <algorithm>
#include <vector>
#include <thread>
#include <atomic>
#include <fstream>
#include <sstream>
#include <filesystem>
#include <dirent.h>
#include <fcntl.h>
#include <unistd.h>
#include <csignal>
#include <cstring>
#include <cstdlib>

// ── Config ────────────────────────────────────────────────────────────────────
struct Config {
    float  volume  = 0.18f;
    bool   random  = true;   // false = fixed note per key
    bool   enabled = true;
};

static Config cfg;
static std::atomic<bool> running{true};

static std::string config_path() {
    const char* h = std::getenv("HOME");
    return std::string(h ?: "") + "/.config/pomodoro-tasks/typing.conf";
}

static void load_config() {
    std::ifstream f(config_path());
    if (!f) return;
    std::string line;
    while (std::getline(f, line)) {
        if (line.rfind("volume=", 0) == 0)  cfg.volume  = std::stof(line.substr(7));
        if (line.rfind("random=", 0) == 0)  cfg.random  = (line.substr(7) == "1");
        if (line.rfind("enabled=", 0) == 0) cfg.enabled = (line.substr(8) == "1");
    }
}

static void save_config() {
    auto path = config_path();
    std::filesystem::create_directories(std::filesystem::path(path).parent_path());
    std::ofstream f(path);
    f << "volume="  << cfg.volume  << "\n"
      << "random="  << (cfg.random  ? "1" : "0") << "\n"
      << "enabled=" << (cfg.enabled ? "1" : "0") << "\n";
}

// ── Audio synthesis ───────────────────────────────────────────────────────────
static constexpr int   RATE = 44100;
static constexpr float PI2  = 2.0f * M_PI;

// A minor pentatonic: A3..G5
static constexpr float SCALE[] = {220.f,261.6f,293.7f,329.6f,392.f,
                                   440.f,523.3f,587.3f,659.3f,784.f};
static constexpr int   SCALE_N = 10;

// Fixed note mapping: key scancode → scale index (0..9)
// Spread across the keyboard so adjacent keys have different pitches
static int fixed_note(int code) {
    // Map key rows to scale indices
    static const int row_q[] = {4,5,6,7,8,9,0,1,2,3,4,5,6,7}; // Q..P
    static const int row_a[] = {2,3,4,5,6,7,8,9,0,1,2};        // A..L
    static const int row_z[] = {6,7,8,9,0,1,2,3,4,5};          // Z..M
    if (code >= KEY_Q && code <= KEY_P) return row_q[code - KEY_Q];
    if (code >= KEY_A && code <= KEY_L) return row_a[code - KEY_A];
    if (code >= KEY_Z && code <= KEY_M) return row_z[code - KEY_Z];
    if (code >= KEY_1 && code <= KEY_0) return (code - KEY_1) % SCALE_N;
    return 4; // default: middle of scale
}

static int last_idx = -1;

static int pick_note(int code) {
    if (!cfg.random) return fixed_note(code);
    // Random, anti-repeat
    int idx;
    do { idx = rand() % SCALE_N; } while (idx == last_idx);
    last_idx = idx;
    return idx;
}

// Generate PCM for a droplet sound
// type: 0=regular, 1=space, 2=enter, 3=backspace
static std::vector<int16_t> make_droplet(float freq, int type) {
    float v = cfg.volume * 0.35f;
    // Pitch jitter ±3%
    freq *= 1.0f + ((rand() % 60 - 30) / 1000.f);

    float attack, decay, fm_depth;
    switch (type) {
        case 1: freq *= 0.75f; attack=0.006f; decay=0.13f; fm_depth=0.06f; v*=0.7f; break; // space
        case 2: attack=0.003f; decay=0.18f; fm_depth=0.10f; break; // enter
        case 3: attack=0.002f; decay=0.10f; fm_depth=0.04f; v*=0.8f; break; // backspace
        default: attack=0.004f; decay=0.09f; fm_depth=0.08f; break;
    }

    int n = (int)((attack + decay + 0.01f) * RATE);
    std::vector<int16_t> buf(n);

    for (int i = 0; i < n; ++i) {
        float t = (float)i / RATE;
        // FM modulator
        float mod = std::sin(PI2 * freq * 2.f * t) * freq * fm_depth;
        float carrier_freq = freq + mod;
        // Backspace: pitch bend down
        if (type == 3) carrier_freq *= (1.f - 0.15f * std::min(t / decay, 1.f));
        float s = std::sin(PI2 * carrier_freq * t);
        // Envelope
        float env;
        if (t < attack) env = t / attack;
        else            env = std::exp(-5.f * (t - attack) / decay);
        // Soft clip
        float out = std::tanh(s * env * v * 1.2f) / 1.2f;
        buf[i] = (int16_t)(std::clamp(out, -1.f, 1.f) * 32767.f);
    }
    return buf;
}

// Enter: two-note chord
static std::vector<int16_t> make_enter(float freq) {
    auto n1 = make_droplet(freq,        2);
    auto n2 = make_droplet(freq * 1.26f, 2);
    size_t sz = std::max(n1.size(), n2.size());
    n1.resize(sz, 0); n2.resize(sz, 0);
    for (size_t i = 0; i < sz; ++i)
        n1[i] = (int16_t)std::clamp((float)n1[i] + n2[i] * 0.5f, -32767.f, 32767.f);
    return n1;
}

static void play_async(std::vector<int16_t> buf) {
    std::thread([b = std::move(buf)]() mutable {
        pa_sample_spec ss{ PA_SAMPLE_S16LE, (uint32_t)RATE, 1 };
        int err = 0;
        pa_simple* s = pa_simple_new(nullptr, "typing-sounds", PA_STREAM_PLAYBACK,
                                      nullptr, "key", &ss, nullptr, nullptr, &err);
        if (!s) return;
        pa_simple_write(s, b.data(), b.size() * sizeof(int16_t), &err);
        pa_simple_drain(s, &err);
        pa_simple_free(s);
    }).detach();
}

static void on_key(int code) {
    if (!cfg.enabled) return;
    int type = 0;
    if (code == KEY_SPACE)     type = 1;
    else if (code == KEY_ENTER || code == KEY_KPENTER) type = 2;
    else if (code == KEY_BACKSPACE) type = 3;

    int idx = pick_note(code);
    float freq = SCALE[idx];

    if (type == 2) play_async(make_enter(freq));
    else           play_async(make_droplet(freq, type));
}

// ── Device discovery ──────────────────────────────────────────────────────────
// Open all /dev/input/eventN that have EV_KEY but not EV_REL (not mice)
static std::vector<int> open_keyboards() {
    std::vector<int> fds;
    DIR* d = opendir("/dev/input");
    if (!d) return fds;
    struct dirent* e;
    while ((e = readdir(d))) {
        if (strncmp(e->d_name, "event", 5) != 0) continue;
        std::string path = "/dev/input/" + std::string(e->d_name);
        int fd = open(path.c_str(), O_RDONLY | O_NONBLOCK);
        if (fd < 0) continue;
        libevdev* dev = nullptr;
        if (libevdev_new_from_fd(fd, &dev) < 0) { close(fd); continue; }
        bool has_key = libevdev_has_event_type(dev, EV_KEY);
        bool has_rel = libevdev_has_event_type(dev, EV_REL);
        bool has_alpha = libevdev_has_event_code(dev, EV_KEY, KEY_A);
        libevdev_free(dev);
        if (has_key && has_alpha && !has_rel) {
            // Re-open blocking for the reader thread
            close(fd);
            fd = open(path.c_str(), O_RDONLY);
            if (fd >= 0) fds.push_back(fd);
        } else {
            close(fd);
        }
    }
    closedir(d);
    return fds;
}

// ── Reader thread per device ──────────────────────────────────────────────────
static void read_device(int fd) {
    libevdev* dev = nullptr;
    libevdev_new_from_fd(fd, &dev);
    if (!dev) { close(fd); return; }

    while (running) {
        input_event ev;
        int rc = libevdev_next_event(dev, LIBEVDEV_READ_FLAG_NORMAL | LIBEVDEV_READ_FLAG_BLOCKING, &ev);
        if (rc == LIBEVDEV_READ_STATUS_SUCCESS) {
            if (ev.type == EV_KEY && ev.value == 1)  // key down only
                on_key(ev.code);
        } else if (rc == -EAGAIN) {
            usleep(1000);
        } else {
            break;
        }
    }
    libevdev_free(dev);
    close(fd);
}

// ── Signal / IPC ──────────────────────────────────────────────────────────────
// SIGUSR1 = toggle enabled, SIGUSR2 = reload config
static void sig_handler(int sig) {
    if (sig == SIGUSR1) { cfg.enabled = !cfg.enabled; save_config(); }
    if (sig == SIGUSR2) { load_config(); }
    if (sig == SIGTERM || sig == SIGINT) { running = false; }
}

int main() {
    srand(time(nullptr));
    load_config();

    signal(SIGUSR1, sig_handler);
    signal(SIGUSR2, sig_handler);
    signal(SIGTERM, sig_handler);
    signal(SIGINT,  sig_handler);

    // Write PID file
    const char* h = std::getenv("HOME");
    std::string pid_file = std::string(h ?: "") + "/.cache/typing-sounds.pid";
    { std::ofstream f(pid_file); f << getpid(); }

    auto fds = open_keyboards();
    if (fds.empty()) {
        fprintf(stderr, "typing-sounds: no keyboard devices found (add user to 'input' group)\n");
        return 1;
    }

    std::vector<std::thread> threads;
    for (int fd : fds)
        threads.emplace_back(read_device, fd);

    for (auto& t : threads) t.join();

    std::remove(pid_file.c_str());
    return 0;
}
