#pragma once
#include <functional>
#include <string>

enum class TimerState { Idle, Work, Break, LongBreak, Paused };

struct TimerStatus {
    TimerState state;
    int        seconds_left;
    int        current_session;   // 1-based
    int        total_sessions;
    std::string task_title;
};

// Callbacks fired on the GLib main loop (thread-safe via g_idle_add).
struct TimerCallbacks {
    std::function<void(TimerStatus)> on_tick;      // every second
    std::function<void(TimerStatus)> on_session_end;
    std::function<void()>            on_all_done;
};

class PomodoroTimer {
public:
    PomodoroTimer(int work_min, int break_min, int long_break_min);
    ~PomodoroTimer();

    void start(const std::string& task_id, const std::string& task_title,
               int total_sessions, int already_done, TimerCallbacks cb);
    void pause();
    void resume();
    void reset();
    void skip();   // force-advance current phase (work→break or break→work)

    TimerStatus status() const;

private:
    struct Impl;
    Impl* d;
};
