#pragma once
#include <string>
#include <functional>

namespace WalTheme {
    // Returns flat JSON {background, foreground, color0..15} from pywal cache
    std::string load_colors_json();

    // Returns flat JSON for a named preset, or "" if unknown
    // Presets: "dark" "light" "catppuccin" "gruvbox" "nord" "dracula"
    std::string preset_colors_json(const std::string& name);

    // Returns colors for the given theme name ("pywal" → load_colors_json, else preset)
    std::string theme_colors_json(const std::string& theme);

    // Returns JSON array of available preset names (for the UI selector)
    std::string presets_list_json();

    // Watch pywal colors.json; fires callback only when theme == "pywal"
    void watch(std::function<void(std::string)> on_change);
}
