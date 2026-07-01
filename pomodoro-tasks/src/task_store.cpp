#include "task_store.h"
#include <fstream>
#include <sstream>
#include <chrono>
#include <filesystem>
#include <cstdio>

// ── tiny JSON helpers ────────────────────────────────────────────────────────
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

static std::string read_file(const std::string& path) {
    std::ifstream f(path);
    if (!f) return "";
    return {std::istreambuf_iterator<char>(f), {}};
}

// ── minimal JSON value extractor ─────────────────────────────────────────────
static std::string jget(const std::string& json, const std::string& key) {
    auto pos = json.find("\"" + key + "\"");
    if (pos == std::string::npos) return "";
    pos = json.find(':', pos) + 1;
    while (pos < json.size() && json[pos] == ' ') ++pos;
    if (json[pos] == '"') {
        auto end = json.find('"', pos + 1);
        while (end != std::string::npos && json[end-1] == '\\') end = json.find('"', end+1);
        return json.substr(pos + 1, end - pos - 1);
    }
    auto end = json.find_first_of(",}\n]", pos);
    auto val = json.substr(pos, end - pos);
    // trim
    while (!val.empty() && (val.back() == ' ' || val.back() == '\r')) val.pop_back();
    return val;
}

static std::vector<std::string> jarray_objects(const std::string& json, const std::string& key) {
    std::vector<std::string> out;
    auto pos = json.find("\"" + key + "\"");
    if (pos == std::string::npos) return out;
    pos = json.find('[', pos);
    if (pos == std::string::npos) return out;
    int depth = 0; std::string cur;
    for (size_t i = pos + 1; i < json.size(); ++i) {
        char c = json[i];
        if (c == '{') { depth++; cur += c; }
        else if (c == '}') { cur += c; if (--depth == 0) { out.push_back(cur); cur.clear(); } }
        else if (depth > 0) cur += c;
        else if (c == ']') break;
    }
    return out;
}

// ── public API ───────────────────────────────────────────────────────────────
static std::string data_file() {
    const char* xdg = std::getenv("XDG_DATA_HOME");
    std::string base = xdg ? xdg : (std::string(std::getenv("HOME") ?: "") + "/.local/share");
    return base + "/pomodoro-tasks/tasks.json";
}

AppState TaskStore::load() {
    AppState s;
    auto path = data_file();
    std::filesystem::create_directories(std::filesystem::path(path).parent_path());
    std::string raw = read_file(path);
    if (raw.empty()) return s;

    s.active_task_id = jget(raw, "active_task_id");
    auto wm = jget(raw, "work_minutes");   if (!wm.empty()) s.work_minutes   = std::stoi(wm);
    auto bm = jget(raw, "break_minutes");  if (!bm.empty()) s.break_minutes  = std::stoi(bm);
    auto lm = jget(raw, "long_break_min"); if (!lm.empty()) s.long_break_min = std::stoi(lm);

    auto lf = [&](const std::string& k){ auto v = jget(raw,k); return v.empty() ? 1.0f : std::stof(v); };
    s.snd_focus.volume = lf("snd_focus_vol"); s.snd_focus.pitch = lf("snd_focus_pitch");
    s.snd_break.volume = lf("snd_break_vol"); s.snd_break.pitch = lf("snd_break_pitch");
    s.snd_done.volume  = lf("snd_done_vol");  s.snd_done.pitch  = lf("snd_done_pitch");
    auto th = jget(raw, "theme"); if (!th.empty()) s.theme = th;
    auto sp = jget(raw, "sound_pack"); if (!sp.empty()) s.sound_pack = sp;
    auto lr = jget(raw, "last_reset_date"); if (!lr.empty()) s.last_reset_date = lr;
    auto as = jget(raw, "auto_start"); s.auto_start = (as == "true" || as == "1");
    auto dc = jget(raw, "daily_sessions_count"); if (!dc.empty()) s.daily_sessions_count = std::stoi(dc);
    auto dd = jget(raw, "daily_stats_date"); if (!dd.empty()) s.daily_stats_date = dd;
    auto ci = jget(raw, "concurso_index"); if (!ci.empty()) s.concurso_index = std::stoi(ci);
    auto lc = jget(raw, "last_concurso_task_id"); if (!lc.empty()) s.last_concurso_task_id = lc;
    // concurso_queue: simple string array
    {
        auto pos = raw.find("\"concurso_queue\"");
        if (pos != std::string::npos) {
            pos = raw.find('[', pos);
            if (pos != std::string::npos) {
                pos++;
                while (pos < raw.size()) {
                    while (pos < raw.size() && (raw[pos]==' '||raw[pos]==','||raw[pos]=='\n')) pos++;
                    if (raw[pos] == ']') break;
                    if (raw[pos] == '"') {
                        auto end = raw.find('"', pos+1);
                        s.concurso_queue.push_back(raw.substr(pos+1, end-pos-1));
                        pos = end+1;
                    } else break;
                }
            }
        }
    }

    for (auto& obj : jarray_objects(raw, "tasks")) {
        Task t;
        t.id                 = jget(obj, "id");
        t.title              = jget(obj, "title");
        t.date               = jget(obj, "date");
        auto em = jget(obj, "estimated_minutes"); t.estimated_minutes = em.empty() ? 25 : std::stoi(em);
        auto cs = jget(obj, "completed_sessions"); t.completed_sessions = cs.empty() ? 0 : std::stoi(cs);
        auto dn = jget(obj, "done"); t.done = (dn == "true" || dn == "1");
        auto rc = jget(obj, "recurring"); t.recurring = (rc == "true" || rc == "1");
        auto wd = jget(obj, "weekday"); t.weekday = wd.empty() ? -1 : std::stoi(wd);
        t.tag       = jget(obj, "tag");
        t.tag_color = jget(obj, "tag_color");
        auto pe = jget(obj, "pomodoro_estimate"); t.pomodoro_estimate = pe.empty() ? 0 : std::stoi(pe);
        if (!t.id.empty()) s.tasks.push_back(t);
    }

    // Load presets: array of {name, tasks:[...]}
    for (auto& pobj : jarray_objects(raw, "presets")) {
        WeekPreset p;
        p.name = jget(pobj, "name");
        if (p.name.empty()) continue;
        for (auto& tobj : jarray_objects(pobj, "tasks")) {
            Task t;
            t.id    = jget(tobj, "id");    t.title = jget(tobj, "title");
            t.recurring = true;
            auto em = jget(tobj, "estimated_minutes"); t.estimated_minutes = em.empty() ? 25 : std::stoi(em);
            auto wd = jget(tobj, "weekday"); t.weekday = wd.empty() ? -1 : std::stoi(wd);
            if (!t.id.empty()) p.tasks.push_back(t);
        }
        s.presets.push_back(p);
    }
    return s;
}

void TaskStore::save(const AppState& s) {
    auto path = data_file();
    std::filesystem::create_directories(std::filesystem::path(path).parent_path());
    std::ostringstream o;
    o << "{\n"
      << "  \"work_minutes\": "   << s.work_minutes   << ",\n"
      << "  \"break_minutes\": "  << s.break_minutes  << ",\n"
      << "  \"long_break_min\": " << s.long_break_min << ",\n"
      << "  \"active_task_id\": " << jstr(s.active_task_id) << ",\n"
      << "  \"theme\": "          << jstr(s.theme) << ",\n"
      << "  \"sound_pack\": "       << jstr(s.sound_pack) << ",\n"
      << "  \"last_reset_date\": "  << jstr(s.last_reset_date) << ",\n"
      << "  \"auto_start\": "       << (s.auto_start ? "true" : "false") << ",\n"
      << "  \"daily_sessions_count\": " << s.daily_sessions_count << ",\n"
      << "  \"daily_stats_date\": " << jstr(s.daily_stats_date) << ",\n"
      << "  \"concurso_index\": " << s.concurso_index << ",\n"
      << "  \"last_concurso_task_id\": " << jstr(s.last_concurso_task_id) << ",\n"
      << "  \"concurso_queue\": [";
    for (size_t i = 0; i < s.concurso_queue.size(); ++i) {
        o << jstr(s.concurso_queue[i]);
        if (i + 1 < s.concurso_queue.size()) o << ",";
    }
    o << "],\n"
      << "  \"snd_focus_vol\": "  << s.snd_focus.volume << ", \"snd_focus_pitch\": " << s.snd_focus.pitch << ",\n"
      << "  \"snd_break_vol\": "  << s.snd_break.volume << ", \"snd_break_pitch\": " << s.snd_break.pitch << ",\n"
      << "  \"snd_done_vol\": "   << s.snd_done.volume  << ", \"snd_done_pitch\": "  << s.snd_done.pitch  << ",\n"
      << "  \"tasks\": [\n";
    for (size_t i = 0; i < s.tasks.size(); ++i) {
        const auto& t = s.tasks[i];
        o << "    {"
          << "\"id\": "                 << jstr(t.id)    << ", "
          << "\"title\": "              << jstr(t.title) << ", "
          << "\"date\": "               << jstr(t.date)  << ", "
          << "\"estimated_minutes\": "  << t.estimated_minutes  << ", "
          << "\"completed_sessions\": " << t.completed_sessions << ", "
          << "\"done\": "               << (t.done ? "true" : "false")
          << ", \"recurring\": "        << (t.recurring ? "true" : "false")
          << ", \"weekday\": "          << t.weekday
          << ", \"tag\": "              << jstr(t.tag)
          << ", \"tag_color\": "        << jstr(t.tag_color)
          << ", \"pomodoro_estimate\": " << t.pomodoro_estimate
          << "}";
        if (i + 1 < s.tasks.size()) o << ",";
        o << "\n";
    }
    o << "  ],\n  \"presets\": [\n";
    for (size_t pi = 0; pi < s.presets.size(); ++pi) {
        const auto& p = s.presets[pi];
        o << "    {\"name\": " << jstr(p.name) << ", \"tasks\": [";
        for (size_t ti = 0; ti < p.tasks.size(); ++ti) {
            const auto& t = p.tasks[ti];
            o << "{\"id\": " << jstr(t.id) << ", \"title\": " << jstr(t.title)
              << ", \"estimated_minutes\": " << t.estimated_minutes
              << ", \"weekday\": " << t.weekday << "}";
            if (ti + 1 < p.tasks.size()) o << ",";
        }
        o << "]}";
        if (pi + 1 < s.presets.size()) o << ",";
        o << "\n";
    }
    o << "  ]\n}\n";
    std::ofstream f(path);
    f << o.str();
}

std::string TaskStore::new_id() {
    auto now = std::chrono::system_clock::now().time_since_epoch().count();
    char buf[32];
    std::snprintf(buf, sizeof(buf), "%llx", (unsigned long long)now);
    return buf;
}
