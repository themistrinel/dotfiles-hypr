#include "wal_theme.h"
#include <fstream>
#include <sstream>
#include <cstdlib>
#include <map>
#include <gio/gio.h>

static std::string read_file(const std::string& path) {
    std::ifstream f(path);
    if (!f) return "";
    return {std::istreambuf_iterator<char>(f), {}};
}

static std::string colors_path() {
    const char* h = std::getenv("HOME");
    return std::string(h ? h : "") + "/.cache/wal/colors.json";
}

static std::string flatten(const std::string& raw) {
    if (raw.empty()) return "{}";
    auto extract = [&](const std::string& key) {
        auto pos = raw.find("\"" + key + "\"");
        if (pos == std::string::npos) return std::string{};
        pos = raw.find('"', raw.find(':', pos) + 1);
        if (pos == std::string::npos) return std::string{};
        auto end = raw.find('"', pos + 1);
        return raw.substr(pos + 1, end - pos - 1);
    };
    std::ostringstream o;
    o << "{\"background\":\"" << extract("background")
      << "\",\"foreground\":\"" << extract("foreground") << "\"";
    for (int i = 0; i <= 15; i++) {
        auto v = extract("color" + std::to_string(i));
        if (!v.empty()) o << ",\"color" << i << "\":\"" << v << "\"";
    }
    o << "}";
    return o.str();
}

// ── presets ──────────────────────────────────────────────────────────────────
struct Preset { const char* bg; const char* fg; const char* c1; const char* c2; const char* c8; };

static const std::map<std::string, Preset> PRESETS = {
    {"dark",       {"#1a1a1a", "#e0e0e0", "#c14f30", "#c56431", "#666666"}},
    {"light",      {"#f5f5f5", "#2d2d2d", "#c0392b", "#27ae60", "#999999"}},
    {"catppuccin", {"#1e1e2e", "#cdd6f4", "#cba6f7", "#89b4fa", "#585b70"}},
    {"gruvbox",    {"#282828", "#ebdbb2", "#cc241d", "#98971a", "#928374"}},
    {"nord",       {"#2e3440", "#d8dee9", "#bf616a", "#88c0d0", "#4c566a"}},
    {"dracula",    {"#282a36", "#f8f8f2", "#ff79c6", "#bd93f9", "#6272a4"}},
};

static std::string preset_to_json(const Preset& p) {
    std::ostringstream o;
    o << "{\"background\":\"" << p.bg << "\""
      << ",\"foreground\":\"" << p.fg << "\""
      << ",\"color1\":\""     << p.c1 << "\""
      << ",\"color2\":\""     << p.c2 << "\""
      << ",\"color8\":\""     << p.c8 << "\"}";
    return o.str();
}

std::string WalTheme::load_colors_json() {
    return flatten(read_file(colors_path()));
}

std::string WalTheme::preset_colors_json(const std::string& name) {
    auto it = PRESETS.find(name);
    return it != PRESETS.end() ? preset_to_json(it->second) : "";
}

std::string WalTheme::theme_colors_json(const std::string& theme) {
    if (theme == "pywal") return load_colors_json();
    auto j = preset_colors_json(theme);
    return j.empty() ? load_colors_json() : j;
}

std::string WalTheme::presets_list_json() {
    std::string o = "[\"pywal\"";
    for (auto& [k, _] : PRESETS) o += ",\"" + k + "\"";
    return o + "]";
}

// ── file watcher ─────────────────────────────────────────────────────────────
struct WatchCtx { std::function<void(std::string)> cb; };

static void on_file_changed(GFileMonitor*, GFile*, GFile*, GFileMonitorEvent ev, gpointer data) {
    if (ev != G_FILE_MONITOR_EVENT_CHANGED && ev != G_FILE_MONITOR_EVENT_CREATED) return;
    static_cast<WatchCtx*>(data)->cb(WalTheme::load_colors_json());
}

void WalTheme::watch(std::function<void(std::string)> on_change) {
    GFile* f = g_file_new_for_path(colors_path().c_str());
    GFileMonitor* mon = g_file_monitor_file(f, G_FILE_MONITOR_NONE, nullptr, nullptr);
    g_object_unref(f);
    if (!mon) return;
    g_signal_connect(mon, "changed", G_CALLBACK(on_file_changed), new WatchCtx{on_change});
}
