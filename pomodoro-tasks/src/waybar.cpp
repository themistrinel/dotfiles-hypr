#include "waybar.h"
#include <fstream>
#include <cstdlib>
#include <cstring>
#include <signal.h>
#include <dirent.h>
#include <sys/types.h>

static const char* WAYBAR_FILE = "/tmp/pomodoro-waybar.json";

static std::string jstr(const std::string& s) {
    std::string o;
    for (char c : s) {
        if (c == '"')  o += "\\\"";
        else if (c == '\\') o += "\\\\";
        else if (c == '\n') o += "\\n";
        else o += c;
    }
    return o;
}

// Find waybar PID by scanning /proc
static pid_t find_waybar_pid() {
    DIR* d = opendir("/proc");
    if (!d) return -1;
    struct dirent* e;
    while ((e = readdir(d))) {
        if (e->d_type != DT_DIR) continue;
        char* end; long pid = strtol(e->d_name, &end, 10);
        if (*end) continue;
        std::string comm = "/proc/" + std::string(e->d_name) + "/comm";
        std::ifstream f(comm);
        std::string name; f >> name;
        if (name == "waybar") { closedir(d); return (pid_t)pid; }
    }
    closedir(d);
    return -1;
}

void Waybar::update(const std::string& text, const std::string& tooltip, const std::string& css_class) {
    std::ofstream f(WAYBAR_FILE);
    f << "{\"text\":\"" << jstr(text) << "\","
      << "\"tooltip\":\"" << jstr(tooltip) << "\","
      << "\"class\":\"" << jstr(css_class) << "\"}";
    f.close();

    pid_t pid = find_waybar_pid();
    if (pid > 0) kill(pid, SIGRTMIN + 8);
}

void Waybar::clear() {
    std::ofstream f(WAYBAR_FILE);
    f << "{\"text\":\"\",\"tooltip\":\"\",\"class\":\"\"}";
    f.close();
    pid_t pid = find_waybar_pid();
    if (pid > 0) kill(pid, SIGRTMIN + 8);
}
