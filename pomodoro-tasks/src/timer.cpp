#include "timer.h"
#include <glib.h>
#include <cstring>

struct PomodoroTimer::Impl {
    int work_sec, break_sec, long_break_sec;

    TimerState  state = TimerState::Idle;
    int         seconds_left   = 0;
    int         current_session = 0;
    int         total_sessions  = 0;
    std::string task_id, task_title;
    TimerCallbacks cb;

    guint timeout_id = 0;

    static gboolean tick(gpointer data) {
        auto* self = static_cast<Impl*>(data);
        if (self->state == TimerState::Paused || self->state == TimerState::Idle)
            return G_SOURCE_CONTINUE;

        self->seconds_left--;
        if (self->cb.on_tick) self->cb.on_tick(self->make_status());

        if (self->seconds_left <= 0) self->advance();
        return G_SOURCE_CONTINUE;
    }

    void advance() {
        if (state == TimerState::Work) {
            current_session++;
            if (cb.on_session_end) cb.on_session_end(make_status());
            if (current_session > total_sessions) {
                state = TimerState::Idle;
                if (cb.on_all_done) cb.on_all_done();
                return;
            }
            bool long_break = (current_session % 4 == 1) && current_session > 1;
            state = long_break ? TimerState::LongBreak : TimerState::Break;
            seconds_left = long_break ? long_break_sec : break_sec;
        } else {
            // break ended → next work session
            state = TimerState::Work;
            seconds_left = work_sec;
        }
        if (cb.on_tick) cb.on_tick(make_status());
    }

    TimerStatus make_status() const {
        return {state, seconds_left, current_session, total_sessions, task_title};
    }
};

PomodoroTimer::PomodoroTimer(int wm, int bm, int lbm) : d(new Impl) {
    d->work_sec       = wm  * 60;
    d->break_sec      = bm  * 60;
    d->long_break_sec = lbm * 60;
}

PomodoroTimer::~PomodoroTimer() {
    if (d->timeout_id) g_source_remove(d->timeout_id);
    delete d;
}

void PomodoroTimer::start(const std::string& task_id, const std::string& title,
                          int total, int done, TimerCallbacks cb) {
    reset();
    d->task_id         = task_id;
    d->task_title      = title;
    d->total_sessions  = total;
    d->current_session = done + 1;
    d->cb              = cb;
    d->state           = TimerState::Work;
    d->seconds_left    = d->work_sec;
    if (!d->timeout_id)
        d->timeout_id = g_timeout_add(1000, Impl::tick, d);
    if (d->cb.on_tick) d->cb.on_tick(d->make_status());
}

void PomodoroTimer::pause() {
    if (d->state != TimerState::Idle) d->state = TimerState::Paused;
}

void PomodoroTimer::resume() {
    if (d->state == TimerState::Paused) d->state = TimerState::Work;
}

void PomodoroTimer::reset() {
    if (d->timeout_id) { g_source_remove(d->timeout_id); d->timeout_id = 0; }
    d->state = TimerState::Idle;
    d->seconds_left = d->current_session = d->total_sessions = 0;
}

void PomodoroTimer::skip() {
    if (d->state == TimerState::Idle) return;
    // Treat as if the current phase just ran out
    d->seconds_left = 0;
    d->advance();
}

TimerStatus PomodoroTimer::status() const { return d->make_status(); }
