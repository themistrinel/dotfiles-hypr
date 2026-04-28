#pragma once
#include <webkit2/webkit2.h>
#include <libappindicator/app-indicator.h>
#include "models.h"
#include "timer.h"
#include <vector>

class App {
public:
    App();
    ~App();

    void run(int argc, char** argv);

    // Called from IPC
    void handle_init();
    void handle_start();
    void handle_pause();
    void handle_resume();
    void handle_reset();
    void handle_skip_session();
    void handle_add_task(const std::string& title, int minutes, const std::string& date,
                         bool recurring, int weekday,
                         const std::string& tag, const std::string& tag_color,
                         int pomodoro_estimate);
    void handle_edit_task(const std::string& id, const std::string& title, int minutes,
                          const std::string& date, bool recurring, int weekday,
                          const std::string& tag, const std::string& tag_color,
                          int pomodoro_estimate);
    void handle_delete_task(const std::string& id);
    void handle_select_task(const std::string& id);
    void handle_toggle_done(const std::string& id);
    void handle_finish_task(const std::string& id);
    void handle_reorder_tasks(const std::vector<std::string>& ids);
    void handle_save_settings(int work, int brk, int lng, bool auto_start);
    void handle_preview_sound(const std::string& which, const AppState::SoundCfg& cfg);
    void handle_save_sound_config(AppState::SoundCfg focus, AppState::SoundCfg brk, AppState::SoundCfg done);
    void handle_set_theme(const std::string& theme);
    void handle_set_sound_pack(const std::string& pack);
    void handle_set_typing_config(float volume, bool enabled, bool random);
    void handle_save_preset(const std::string& name);
    void handle_load_preset(const std::string& name);
    void handle_delete_preset(const std::string& name);

    void eval_js(const std::string& js);

private:
    AppState       state_;
    PomodoroTimer* timer_     = nullptr;
    WebKitWebView* webview_   = nullptr;
    GtkWidget*     window_    = nullptr;
    AppIndicator*  indicator_ = nullptr;

    void send_state();
    void send_tick(const TimerStatus&);
    void send_theme(const std::string& colors_json);
    void setup_window();
    void setup_webview();
    void on_timer_tick(TimerStatus);
    void on_session_end(TimerStatus);
    void on_all_done();
    void notify_dunst(const std::string& summary, const std::string& body);
    void update_daily_stats();
};

extern App* g_app;
