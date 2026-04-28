#include "app.h"
#include "task_store.h"
#include "waybar.h"
#include "wal_theme.h"
#include "ipc.h"
#include "audio.h"
#include <webkit2/webkit2.h>
#include <glib-unix.h>
#include <fstream>
#include <sstream>
#include <algorithm>
#include <cstring>
#include <ctime>
#include <chrono>
#include <unistd.h>
#include <filesystem>

App* g_app = nullptr;

// ── helpers ──────────────────────────────────────────────────────────────────
static std::string jstr(const std::string& s) {
    std::string o = "\"";
    for (char c : s) {
        if (c == '"')  o += "\\\"";
        else if (c == '\\') o += "\\\\";
        else if (c == '\n') o += "\\n";
        else o += c;
    }
    return o + "\"";
}

static std::string state_to_json(const AppState& s) {
    std::ostringstream o;
    o << "{\"work_minutes\":" << s.work_minutes
      << ",\"break_minutes\":" << s.break_minutes
      << ",\"long_break_min\":" << s.long_break_min
      << ",\"active_task_id\":" << jstr(s.active_task_id)
      << ",\"theme\":" << jstr(s.theme)
      << ",\"sound_pack\":" << jstr(s.sound_pack)
      << ",\"auto_start\":" << (s.auto_start ? "true" : "false")
      << ",\"daily_sessions_count\":" << s.daily_sessions_count
      << ",\"tasks\":[";
    for (size_t i = 0; i < s.tasks.size(); ++i) {
        const auto& t = s.tasks[i];
        int sessions = t.pomodoro_estimate > 0 ? t.pomodoro_estimate
                     : (t.estimated_minutes + s.work_minutes - 1) / s.work_minutes;
        if (sessions < 1) sessions = 1;
        o << "{\"id\":" << jstr(t.id)
          << ",\"title\":" << jstr(t.title)
          << ",\"date\":" << jstr(t.date)
          << ",\"estimated_minutes\":" << t.estimated_minutes
          << ",\"completed_sessions\":" << t.completed_sessions
          << ",\"total_sessions\":" << sessions
          << ",\"done\":" << (t.done ? "true" : "false")
          << ",\"recurring\":" << (t.recurring ? "true" : "false")
          << ",\"weekday\":" << t.weekday
          << ",\"tag\":" << jstr(t.tag)
          << ",\"tag_color\":" << jstr(t.tag_color)
          << ",\"pomodoro_estimate\":" << t.pomodoro_estimate << "}";
        if (i + 1 < s.tasks.size()) o << ",";
    }
    o << "],\"presets\":[";
    for (size_t pi = 0; pi < s.presets.size(); ++pi) {
        const auto& p = s.presets[pi];
        o << "{\"name\":" << jstr(p.name) << "}";
        if (pi + 1 < s.presets.size()) o << ",";
    }
    o << "]}";
    return o.str();
}

static std::string timer_state_name(TimerState ts) {
    switch (ts) {
        case TimerState::Work:      return "Work";
        case TimerState::Break:     return "Break";
        case TimerState::LongBreak: return "LongBreak";
        case TimerState::Paused:    return "Paused";
        default:                    return "Idle";
    }
}

static std::string timer_status_json(const TimerStatus& s) {
    std::ostringstream o;
    o << "{\"state\":\"" << timer_state_name(s.state) << "\""
      << ",\"seconds_left\":" << s.seconds_left
      << ",\"current_session\":" << s.current_session
      << ",\"total_sessions\":" << s.total_sessions
      << ",\"task_title\":" << jstr(s.task_title) << "}";
    return o.str();
}

// ── WebView IPC glue ─────────────────────────────────────────────────────────
static void on_script_message(WebKitUserContentManager*, WebKitJavascriptResult* result, gpointer) {
    JSCValue* val = webkit_javascript_result_get_js_value(result);
    char* str = jsc_value_to_string(val);
    if (str) { ipc_dispatch(str, [](auto){}); g_free(str); }
}

// ── HTML loader ──────────────────────────────────────────────────────────────
#include "ui_html.h"  // embedded at build time by CMake

// ── App ──────────────────────────────────────────────────────────────────────
App::App() {
    state_ = TaskStore::load();
    Audio::set_pack(state_.sound_pack);
    timer_ = new PomodoroTimer(state_.work_minutes, state_.break_minutes, state_.long_break_min);
    // Signal files for waybar
    std::ofstream("/tmp/pomodoro-active");
    { std::ofstream f("/tmp/pomodoro.pid"); f << getpid(); }
}

App::~App() {
    Waybar::clear();
    std::remove("/tmp/pomodoro-active");
    std::remove("/tmp/pomodoro.pid");
    delete timer_;
}

void App::eval_js(const std::string& js) {
    if (webview_) webkit_web_view_evaluate_javascript(webview_, js.c_str(), -1, nullptr, nullptr, nullptr, nullptr, nullptr);
}

void App::send_state() {
    eval_js("window.onBackendMessage && window.onBackendMessage('{\"type\":\"state\",\"data\":" + state_to_json(state_) + "}')");
}

void App::send_tick(const TimerStatus& s) {
    eval_js("window.onBackendMessage && window.onBackendMessage('{\"type\":\"tick\",\"data\":" + timer_status_json(s) + "}')");
}

void App::send_theme(const std::string& colors_json) {
    eval_js("window.onBackendMessage && window.onBackendMessage('{\"type\":\"theme\",\"data\":" + colors_json + "}')");
}

void App::setup_webview() {
    auto* mgr = webkit_user_content_manager_new();
    webkit_user_content_manager_register_script_message_handler(mgr, "ipc");
    g_signal_connect(mgr, "script-message-received::ipc", G_CALLBACK(on_script_message), nullptr);

    webview_ = WEBKIT_WEB_VIEW(webkit_web_view_new_with_user_content_manager(mgr));

    // Transparent background
    GdkRGBA bg = {0, 0, 0, 0};
    webkit_web_view_set_background_color(webview_, &bg);

    // Disable context menu & inspector in release
    auto* settings = webkit_web_view_get_settings(webview_);
    webkit_settings_set_enable_developer_extras(settings, FALSE);
    webkit_settings_set_javascript_can_open_windows_automatically(settings, FALSE);

    webkit_web_view_load_html(webview_, UI_HTML, "file:///");
}

void App::setup_window() {
    window_ = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title(GTK_WINDOW(window_), "Pomodoro");
    gtk_window_set_default_size(GTK_WINDOW(window_), 360, 580);
    gtk_window_set_resizable(GTK_WINDOW(window_), TRUE);

    // Remove decorations for a cleaner look (optional, user can toggle)
    // gtk_window_set_decorated(GTK_WINDOW(window_), FALSE);

    setup_webview();
    gtk_container_add(GTK_CONTAINER(window_), GTK_WIDGET(webview_));
    // Close button hides to tray instead of quitting
    g_signal_connect(window_, "delete-event", G_CALLBACK(+[](GtkWidget* w, GdkEvent*, gpointer) -> gboolean {
        gtk_widget_hide(w);
        return TRUE; // prevent destroy
    }), nullptr);
    gtk_widget_show_all(window_);
}

void App::on_timer_tick(TimerStatus s) {
    send_tick(s);

    if (s.state == TimerState::Idle) { Waybar::clear(); return; }

    // Play focus sound at the start of each work session (except session 1, handled by handle_start)
    if (s.state == TimerState::Work && s.seconds_left == state_.work_minutes * 60 && s.current_session > 1) {
        Audio::play_focus_start(state_.snd_focus);
        notify_dunst("▶ Back to work!", s.task_title + " · session " +
            std::to_string(s.current_session) + "/" + std::to_string(s.total_sessions));
    }

    int m = s.seconds_left / 60, sec = s.seconds_left % 60;
    char time_buf[16];
    std::snprintf(time_buf, sizeof(time_buf), "%02d:%02d", m, sec);

    std::string icon, label;
    switch (s.state) {
        case TimerState::Work:      icon = "🍅"; label = s.task_title; break;
        case TimerState::Break:     icon = "☕"; label = "Break";       break;
        case TimerState::LongBreak: icon = "☕"; label = "Long break";  break;
        case TimerState::Paused:    icon = "⏸"; label = s.task_title;  break;
        default: break;
    }

    std::string text = icon + " " + label + "  " + time_buf;
    std::string tooltip = s.task_title + " · session " +
        std::to_string(s.current_session) + "/" + std::to_string(s.total_sessions) +
        "\nToday: " + std::to_string(state_.daily_sessions_count) + " 🍅";
    std::string cls = (s.state == TimerState::Paused) ? "paused" :
                      (s.state == TimerState::Work)   ? "work"   : "break";
    Waybar::update(text, tooltip, cls);
}

void App::on_session_end(TimerStatus s) {
    for (auto& t : state_.tasks) {
        if (t.id == state_.active_task_id) {
            t.completed_sessions++;
            break;
        }
    }
    update_daily_stats();
    TaskStore::save(state_);
    send_state();

    // Don't play break sound on the last session — on_all_done will play relax
    bool is_last = (s.current_session > s.total_sessions);
    if (!is_last) {
        Audio::play_break(state_.snd_break);
        std::string task_title;
        for (auto& t : state_.tasks)
            if (t.id == state_.active_task_id) { task_title = t.title; break; }
        notify_dunst("🍅 Pomodoro done!",
            "Session " + std::to_string(s.current_session - 1) + "/" + std::to_string(s.total_sessions) +
            (task_title.empty() ? "" : " · " + task_title) + "\nTime for a break ☕");
    }
}

void App::on_all_done() {
    std::string task_title;
    for (auto& t : state_.tasks) {
        if (t.id == state_.active_task_id) {
            t.done = true;
            task_title = t.title;
            break;
        }
    }
    state_.active_task_id = "";
    TaskStore::save(state_);
    send_state();
    send_tick(timer_->status()); // send Idle tick so frontend unfreezes
    Waybar::clear();
    std::remove("/tmp/pomodoro-running");
    Audio::play_relax(state_.snd_done);
    notify_dunst("✅ Task complete!", task_title.empty() ? "All sessions done!" : task_title + " — relax, you earned it! 🌿");
}

void App::notify_dunst(const std::string& summary, const std::string& body) {
    std::string cmd = "notify-send -a 'Pomodoro' -t 5000 '" + summary + "' '" + body + "' &";
    std::system(cmd.c_str());
}

void App::update_daily_stats() {
    auto now = std::chrono::system_clock::now();
    auto tt  = std::chrono::system_clock::to_time_t(now);
    char today[11]; std::strftime(today, sizeof(today), "%Y-%m-%d", std::localtime(&tt));
    if (state_.daily_stats_date != today) {
        state_.daily_sessions_count = 0;
        state_.daily_stats_date = today;
    }
    state_.daily_sessions_count++;
}

void App::run(int argc, char** argv) {
    gtk_init(&argc, &argv);
    setup_window();

    // ── Tray icon (AppIndicator) ──────────────────────────────────────────
    indicator_ = app_indicator_new("pomodoro-tasks", "appointment-soon",
                                    APP_INDICATOR_CATEGORY_APPLICATION_STATUS);
    app_indicator_set_status(indicator_, APP_INDICATOR_STATUS_ACTIVE);

    // Tray menu: Show / Quit
    GtkWidget* menu  = gtk_menu_new();
    GtkWidget* show  = gtk_menu_item_new_with_label("Show");
    GtkWidget* quit  = gtk_menu_item_new_with_label("Quit");
    gtk_menu_shell_append(GTK_MENU_SHELL(menu), show);
    gtk_menu_shell_append(GTK_MENU_SHELL(menu), quit);
    gtk_widget_show_all(menu);
    app_indicator_set_menu(indicator_, GTK_MENU(menu));

    g_signal_connect(show, "activate", G_CALLBACK(+[](GtkMenuItem*, gpointer data){
        gtk_widget_show(GTK_WIDGET(data));
        gtk_window_present(GTK_WINDOW(data));
    }), window_);
    g_signal_connect(quit, "activate", G_CALLBACK(+[](GtkMenuItem*, gpointer){
        gtk_main_quit();
    }), nullptr);

    // SIGUSR1 → pause/resume (triggered by waybar on-click)
    g_unix_signal_add(SIGUSR1, [](gpointer data) -> gboolean {
        auto* app = static_cast<App*>(data);
        auto s = app->timer_->status();
        if (s.state == TimerState::Work)   { app->handle_pause(); }
        else if (s.state == TimerState::Paused) { app->handle_resume(); }
        return G_SOURCE_CONTINUE;
    }, this);

    // Watch pywal theme changes (only applies when theme == "pywal")
    WalTheme::watch([this](std::string colors_json) {
        if (state_.theme == "pywal") send_theme(colors_json);
    });

    gtk_main();
    TaskStore::save(state_);
}

// ── IPC handlers ─────────────────────────────────────────────────────────────
void App::handle_init() {
    // Reset recurring tasks if it's a new day
    auto now = std::chrono::system_clock::now();
    auto tt  = std::chrono::system_clock::to_time_t(now);
    char today[11]; std::strftime(today, sizeof(today), "%Y-%m-%d", std::localtime(&tt));
    if (state_.last_reset_date != today) {
        for (auto& t : state_.tasks) {
            if (t.recurring) { t.completed_sessions = 0; t.done = false; }
        }
        state_.last_reset_date = today;
        TaskStore::save(state_);
    }
    // Reset daily stats on new day
    if (state_.daily_stats_date != today) {
        state_.daily_sessions_count = 0;
        state_.daily_stats_date = today;
        TaskStore::save(state_);
    }
    send_state();
    auto colors = WalTheme::theme_colors_json(state_.theme);
    if (!colors.empty() && colors != "{}") send_theme(colors);
    send_tick(timer_->status());
}

void App::handle_start() {
    // If no task selected, pick first pending task for today
    if (state_.active_task_id.empty()) {
        auto now = std::chrono::system_clock::now();
        auto tt  = std::chrono::system_clock::to_time_t(now);
        char today[11]; std::strftime(today, sizeof(today), "%Y-%m-%d", std::localtime(&tt));
        int todayWd = std::localtime(&tt)->tm_wday;
        for (auto& t : state_.tasks) {
            bool isToday = (!t.recurring && t.date == today) ||
                           (t.recurring && t.weekday == todayWd);
            if (isToday && !t.done) { state_.active_task_id = t.id; break; }
        }
        if (state_.active_task_id.empty()) return;
        send_state();
    }

    Task* task = nullptr;
    for (auto& t : state_.tasks)
        if (t.id == state_.active_task_id) { task = &t; break; }
    if (!task) return;

    int sessions = task->pomodoro_estimate > 0 ? task->pomodoro_estimate
                 : (task->estimated_minutes + state_.work_minutes - 1) / state_.work_minutes;
    if (sessions < 1) sessions = 1;

    int remaining = sessions - task->completed_sessions;
    if (remaining <= 0) {
        task->completed_sessions = 0;
        task->done = false;
        remaining = sessions;
        TaskStore::save(state_);
        send_state();
    }

    timer_->start(task->id, task->title, remaining, 0, {
        [this](TimerStatus s) { on_timer_tick(s); },
        [this](TimerStatus s) { on_session_end(s); },
        [this]()              { on_all_done(); }
    });
    std::ofstream("/tmp/pomodoro-running"); // signal waybar to hide window title
    Audio::play_focus_start(state_.snd_focus);
}

void App::handle_pause() {
    timer_->pause();
    auto s = timer_->status();
    send_tick(s);
    // Force waybar update with paused class since ticks stop while paused
    int m = s.seconds_left / 60, sec = s.seconds_left % 60;
    char buf[16]; std::snprintf(buf, sizeof(buf), "%02d:%02d", m, sec);
    Waybar::update("⏸ " + s.task_title + "  " + buf,
        s.task_title + " · session " + std::to_string(s.current_session) + "/" + std::to_string(s.total_sessions) +
        "\nToday: " + std::to_string(state_.daily_sessions_count) + " 🍅",
        "paused");
    Audio::play_pause(state_.snd_break);
}
void App::handle_resume() { timer_->resume(); send_tick(timer_->status()); Audio::play_focus_start(state_.snd_focus); }
void App::handle_reset()  { timer_->reset();  send_tick(timer_->status()); Waybar::clear(); std::remove("/tmp/pomodoro-running"); }

void App::handle_add_task(const std::string& title, int minutes, const std::string& date,
                          bool recurring, int weekday,
                          const std::string& tag, const std::string& tag_color,
                          int pomodoro_estimate) {
    Task t;
    t.id = TaskStore::new_id();
    t.title = title;
    t.estimated_minutes = minutes;
    t.date = recurring ? "" : date;
    t.recurring = recurring;
    t.weekday = recurring ? weekday : -1;
    t.tag = tag;
    t.tag_color = tag_color;
    t.pomodoro_estimate = pomodoro_estimate;
    state_.tasks.push_back(t);
    TaskStore::save(state_);
    send_state();
}

void App::handle_edit_task(const std::string& id, const std::string& title, int minutes,
                            const std::string& date, bool recurring, int weekday,
                            const std::string& tag, const std::string& tag_color,
                            int pomodoro_estimate) {
    for (auto& t : state_.tasks) {
        if (t.id == id) {
            t.title = title; t.estimated_minutes = minutes;
            t.recurring = recurring;
            t.weekday = recurring ? weekday : -1;
            t.date = recurring ? "" : date;
            t.tag = tag;
            t.tag_color = tag_color;
            t.pomodoro_estimate = pomodoro_estimate;
            break;
        }
    }
    TaskStore::save(state_);
    send_state();
}

void App::handle_delete_task(const std::string& id) {
    state_.tasks.erase(std::remove_if(state_.tasks.begin(), state_.tasks.end(),
        [&](const Task& t){ return t.id == id; }), state_.tasks.end());
    if (state_.active_task_id == id) { state_.active_task_id = ""; timer_->reset(); Waybar::clear(); }
    TaskStore::save(state_);
    send_state();
}

void App::handle_select_task(const std::string& id) {
    state_.active_task_id = id;
    timer_->reset();
    TaskStore::save(state_);
    send_state();
    send_tick(timer_->status());
}

void App::handle_toggle_done(const std::string& id) {
    for (auto& t : state_.tasks) {
        if (t.id != id) continue;
        t.done = !t.done;
        if (!t.done) { t.completed_sessions = 0; }  // redo → reset progress
        break;
    }
    TaskStore::save(state_);
    send_state();
}

void App::handle_finish_task(const std::string& id) {
    for (auto& t : state_.tasks) {
        if (t.id != id) continue;
        t.done = true;
        t.completed_sessions = t.total_sessions();
        break;
    }
    if (state_.active_task_id == id) {
        timer_->reset();
        state_.active_task_id = "";
        Waybar::clear();
    }
    TaskStore::save(state_);
    send_state();
    send_tick(timer_->status());
    Audio::play_task_done(state_.snd_done);
}

void App::handle_save_settings(int work, int brk, int lng, bool auto_start) {
    state_.work_minutes   = work;
    state_.break_minutes  = brk;
    state_.long_break_min = lng;
    state_.auto_start     = auto_start;
    delete timer_;
    timer_ = new PomodoroTimer(work, brk, lng);
    TaskStore::save(state_);
    send_state();
}

void App::handle_skip_session() {
    if (timer_->status().state == TimerState::Idle) return;
    timer_->skip(); // triggers on_session_end / on_all_done / on_tick via advance()
}

void App::handle_reorder_tasks(const std::vector<std::string>& ids) {
    std::vector<Task> reordered;
    reordered.reserve(ids.size());
    for (auto& id : ids)
        for (auto& t : state_.tasks)
            if (t.id == id) { reordered.push_back(t); break; }
    // Append any tasks not in the ids list (safety)
    for (auto& t : state_.tasks) {
        bool found = false;
        for (auto& id : ids) if (t.id == id) { found = true; break; }
        if (!found) reordered.push_back(t);
    }
    state_.tasks = std::move(reordered);
    TaskStore::save(state_);
    send_state();
}

void App::handle_preview_sound(const std::string& which, const AppState::SoundCfg& cfg) {
    if (which == "focus") Audio::play_focus_start(cfg);
    else if (which == "break") Audio::play_break(cfg);
    else if (which == "done")  Audio::play_task_done(cfg);
}

void App::handle_save_sound_config(AppState::SoundCfg focus, AppState::SoundCfg brk, AppState::SoundCfg done) {
    state_.snd_focus = focus;
    state_.snd_break = brk;
    state_.snd_done  = done;
    TaskStore::save(state_);
}

void App::handle_set_theme(const std::string& theme) {
    state_.theme = theme;
    TaskStore::save(state_);
    send_theme(WalTheme::theme_colors_json(theme));
}

void App::handle_set_sound_pack(const std::string& pack) {
    state_.sound_pack = pack;
    Audio::set_pack(pack);
    TaskStore::save(state_);
}

void App::handle_set_typing_config(float volume, bool enabled, bool random) {
    // Write config for the daemon
    const char* h = std::getenv("HOME");
    std::string path = std::string(h ?: "") + "/.config/pomodoro-tasks/typing.conf";
    std::filesystem::create_directories(std::filesystem::path(path).parent_path());
    std::ofstream f(path);
    f << "volume=" << volume << "\n"
      << "random=" << (random ? "1" : "0") << "\n"
      << "enabled=" << (enabled ? "1" : "0") << "\n";
    f.close();
    // Signal daemon to reload config
    std::string pid_file = std::string(h ?: "") + "/.cache/typing-sounds.pid";
    std::ifstream pf(pid_file);
    if (pf) {
        pid_t pid; pf >> pid;
        if (pid > 0) kill(pid, SIGUSR2);
    }
}

void App::handle_save_preset(const std::string& name) {
    if (name.empty()) return;
    // Remove existing preset with same name
    state_.presets.erase(std::remove_if(state_.presets.begin(), state_.presets.end(),
        [&](const WeekPreset& p){ return p.name == name; }), state_.presets.end());
    WeekPreset p;
    p.name = name;
    for (auto& t : state_.tasks)
        if (t.recurring) p.tasks.push_back(t);
    state_.presets.push_back(p);
    TaskStore::save(state_);
    send_state();
}

void App::handle_load_preset(const std::string& name) {
    for (auto& p : state_.presets) {
        if (p.name != name) continue;
        // Remove all current recurring tasks
        state_.tasks.erase(std::remove_if(state_.tasks.begin(), state_.tasks.end(),
            [](const Task& t){ return t.recurring; }), state_.tasks.end());
        // Add preset tasks with new IDs
        for (auto t : p.tasks) {
            t.id = TaskStore::new_id();
            t.completed_sessions = 0; t.done = false;
            state_.tasks.push_back(t);
        }
        break;
    }
    TaskStore::save(state_);
    send_state();
}

void App::handle_delete_preset(const std::string& name) {
    state_.presets.erase(std::remove_if(state_.presets.begin(), state_.presets.end(),
        [&](const WeekPreset& p){ return p.name == name; }), state_.presets.end());
    TaskStore::save(state_);
    send_state();
}
