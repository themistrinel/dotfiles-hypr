#pragma once
#include <string>
#include <vector>
#include <cstdint>

struct Task {
    std::string id;
    std::string title;
    std::string date;        // YYYY-MM-DD (empty if recurring)
    int estimated_minutes = 25;
    int completed_sessions = 0;
    bool done = false;

    // Weekly recurrence
    bool recurring = false;
    int  weekday   = -1;     // 0=Sun..6=Sat; -1 = not recurring

    // Tag/category
    std::string tag;         // e.g. "work", "study", "personal"
    std::string tag_color;   // hex color e.g. "#4a9eff"

    // Pomodoro estimate (explicit, overrides auto-calc if > 0)
    int pomodoro_estimate = 0;

    int total_sessions() const {
        return (estimated_minutes + 24) / 25;
    }
};

struct WeekPreset {
    std::string name;
    std::vector<Task> tasks;  // only recurring tasks
};

struct AppState {
    std::vector<Task> tasks;
    std::vector<WeekPreset> presets;
    std::string active_task_id;
    int work_minutes   = 25;
    int break_minutes  = 5;
    int long_break_min = 15;

    // Sound config (volume 0.0–1.0, pitch multiplier 0.5–2.0)
    struct SoundCfg { float volume = 1.0f; float pitch = 1.0f; };
    SoundCfg snd_focus, snd_break, snd_done;

    // Sound pack: "minimal" | "ambient" | "crystal"
    std::string sound_pack = "minimal";

    // Theme: "pywal" or a preset name
    std::string theme = "pywal";
    std::string last_reset_date; // YYYY-MM-DD, for daily recurring reset

    // Auto-start next session after break ends
    bool auto_start = false;

    // Daily stats
    int daily_sessions_count = 0;
    std::string daily_stats_date; // YYYY-MM-DD
};
