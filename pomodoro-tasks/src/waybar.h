#pragma once
#include <string>

// Writes /tmp/pomodoro-waybar.json and sends SIGRTMIN+8 to waybar.
// Waybar custom module polls the file every second.
namespace Waybar {
    void update(const std::string& text, const std::string& tooltip = "", const std::string& css_class = "");
    void clear();
}
