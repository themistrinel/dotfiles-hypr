#include "ipc.h"
#include "app.h"
#include <string>

// Minimal key extractor (same approach as task_store)
static std::string jget(const std::string& j, const std::string& key) {
    auto pos = j.find("\"" + key + "\"");
    if (pos == std::string::npos) return "";
    pos = j.find(':', pos) + 1;
    while (pos < j.size() && j[pos] == ' ') ++pos;
    if (j[pos] == '"') {
        auto end = j.find('"', pos + 1);
        while (end != std::string::npos && j[end-1] == '\\') end = j.find('"', end+1);
        return j.substr(pos + 1, end - pos - 1);
    }
    auto end = j.find_first_of(",}\n]", pos);
    auto val = j.substr(pos, end - pos);
    while (!val.empty() && (val.back() == ' ' || val.back() == '\r')) val.pop_back();
    return val;
}

// Extract a JSON array of strings for a key
static std::vector<std::string> jget_str_array(const std::string& j, const std::string& key) {
    std::vector<std::string> out;
    auto pos = j.find("\"" + key + "\"");
    if (pos == std::string::npos) return out;
    pos = j.find('[', pos);
    if (pos == std::string::npos) return out;
    pos++;
    while (pos < j.size()) {
        while (pos < j.size() && (j[pos] == ' ' || j[pos] == ',')) pos++;
        if (j[pos] == ']') break;
        if (j[pos] == '"') {
            auto end = j.find('"', pos + 1);
            out.push_back(j.substr(pos + 1, end - pos - 1));
            pos = end + 1;
        } else break;
    }
    return out;
}

void ipc_dispatch(const std::string& msg, JSEval /*eval*/) {
    std::string action = jget(msg, "action");
    if (!g_app) return;

    if (action == "init")         { g_app->handle_init(); return; }
    if (action == "start")        { g_app->handle_start(); return; }
    if (action == "pause")        { g_app->handle_pause(); return; }
    if (action == "resume")       { g_app->handle_resume(); return; }
    if (action == "reset")        { g_app->handle_reset(); return; }
    if (action == "skip_session") { g_app->handle_skip_session(); return; }

    if (action == "add_task") {
        auto rc = jget(msg,"recurring"); bool recurring = (rc == "true" || rc == "1");
        auto wd = jget(msg,"weekday");   int weekday = wd.empty() ? -1 : std::stoi(wd);
        auto pe = jget(msg,"pomodoro_estimate"); int pomo = pe.empty() ? 0 : std::stoi(pe);
        g_app->handle_add_task(jget(msg,"title"),
            std::stoi(jget(msg,"estimated_minutes").empty() ? "25" : jget(msg,"estimated_minutes")),
            jget(msg,"date"), recurring, weekday,
            jget(msg,"tag"), jget(msg,"tag_color"), pomo);
        return;
    }
    if (action == "edit_task") {
        auto rc = jget(msg,"recurring"); bool recurring = (rc == "true" || rc == "1");
        auto wd = jget(msg,"weekday");   int weekday = wd.empty() ? -1 : std::stoi(wd);
        auto pe = jget(msg,"pomodoro_estimate"); int pomo = pe.empty() ? 0 : std::stoi(pe);
        g_app->handle_edit_task(jget(msg,"id"), jget(msg,"title"),
            std::stoi(jget(msg,"estimated_minutes").empty() ? "25" : jget(msg,"estimated_minutes")),
            jget(msg,"date"), recurring, weekday,
            jget(msg,"tag"), jget(msg,"tag_color"), pomo);
        return;
    }
    if (action == "reorder_tasks") {
        g_app->handle_reorder_tasks(jget_str_array(msg, "ids"));
        return;
    }
    if (action == "delete_task") { g_app->handle_delete_task(jget(msg,"id")); return; }
    if (action == "select_task") { g_app->handle_select_task(jget(msg,"id")); return; }
    if (action == "toggle_done") { g_app->handle_toggle_done(jget(msg,"id")); return; }
    if (action == "finish_task") { g_app->handle_finish_task(jget(msg,"id")); return; }
    if (action == "save_settings") {
        auto as = jget(msg,"auto_start"); bool auto_start = (as == "true" || as == "1");
        g_app->handle_save_settings(
            std::stoi(jget(msg,"work_minutes").empty()   ? "25" : jget(msg,"work_minutes")),
            std::stoi(jget(msg,"break_minutes").empty()  ? "5"  : jget(msg,"break_minutes")),
            std::stoi(jget(msg,"long_break_min").empty() ? "15" : jget(msg,"long_break_min")),
            auto_start);
        return;
    }
    if (action == "preview_sound") {
        AppState::SoundCfg cfg;
        auto v = jget(msg,"volume"); cfg.volume = v.empty() ? 1.f : std::stof(v);
        auto p = jget(msg,"pitch");  cfg.pitch  = p.empty() ? 1.f : std::stof(p);
        g_app->handle_preview_sound(jget(msg,"sound"), cfg);
        return;
    }
    if (action == "save_sound_config") {
        auto gf = [&](const std::string& k){ auto v=jget(msg,k); return v.empty()?1.f:std::stof(v); };
        g_app->handle_save_sound_config(
            {gf("focus_volume"), gf("focus_pitch")},
            {gf("break_volume"), gf("break_pitch")},
            {gf("done_volume"),  gf("done_pitch")});
        return;
    }
    if (action == "set_theme") { g_app->handle_set_theme(jget(msg,"theme")); return; }
    if (action == "set_sound_pack") { g_app->handle_set_sound_pack(jget(msg,"pack")); return; }
    if (action == "set_typing_config") {
        auto v = jget(msg,"volume");   float vol = v.empty() ? 0.18f : std::stof(v);
        auto e = jget(msg,"enabled");  bool en = (e != "false" && e != "0");
        auto r = jget(msg,"random");   bool rnd = (r != "false" && r != "0");
        g_app->handle_set_typing_config(vol, en, rnd);
        return;
    }
    if (action == "save_preset")   { g_app->handle_save_preset(jget(msg,"name")); return; }
    if (action == "load_preset")   { g_app->handle_load_preset(jget(msg,"name")); return; }
    if (action == "delete_preset") { g_app->handle_delete_preset(jget(msg,"name")); return; }
}
