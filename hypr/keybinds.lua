---------------------
---- KEYBINDINGS ----
---------------------
-- See https://wiki.hypr.land/Configuring/Basics/Binds/

local HOME      = os.getenv("HOME")
local mainMod   = "SUPER"

-- Programs
local terminal  = "foot"
-- local terminal = "kitty"
local wezterm   = "wezterm"
local browser   = "firefox"
local fileManager = "thunar"

-- Applications
hl.bind(mainMod .. " + Return",   hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q",        hl.dsp.window.close())
hl.bind(mainMod .. " + M",        hl.dsp.exit())
hl.bind(mainMod .. " + E",        hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + W",        hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + space",    hl.dsp.exec_cmd("rofi -show drun"))
hl.bind(mainMod .. " + CTRL + W", hl.dsp.exec_cmd("waypaper"))
hl.bind(mainMod .. " + P",        hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind(mainMod .. " + N",        hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/toggle-hyprsunset.sh"))
hl.bind(mainMod .. " + J",        hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + F",        hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + C",        hl.dsp.exec_cmd("code"))
hl.bind(mainMod .. " + B",        hl.dsp.exec_cmd(browser))

-- Screenshots
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(
  "mkdir -p " .. HOME .. "/Pictures/Screenshots && grim -g \"$(slurp)\" - | tee " ..
  HOME .. "/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png | wl-copy"
))
hl.bind("CTRL + SHIFT + S", hl.dsp.exec_cmd("flameshot gui"))

-- OCR
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/ocr.sh"))

-- Screen recording
hl.bind(mainMod .. " + R",        hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/screen-record.sh"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/screen-record.sh"))
hl.bind(mainMod .. " + CTRL + R", hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/screen-record-area.sh"))

-- Focus movement
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Move windows
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- Workspaces (via script)
for i = 1, 10 do
  local key = i % 10
  hl.bind(mainMod .. " + " .. key,          hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/workspace.sh " .. i))
  hl.bind(mainMod .. " + SHIFT + " .. key,  hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + ALT + S",   hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Multimedia keys
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),         { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),        { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),      { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                    { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                    { locked = true, repeating = true })

-- Playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),        { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),    { locked = true })

-- Waybar / theme
hl.bind(mainMod .. " + CTRL + T",  hl.dsp.exec_cmd(HOME .. "/.dotfiles/hypr/scripts/waybar-theme-toggle.sh toggle"))
hl.bind(mainMod .. " + T",         hl.dsp.exec_cmd(HOME .. "/.dotfiles/hypr/scripts/wal-preset.sh"))
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd(HOME .. "/.dotfiles/hypr/scripts/theme-auto.sh"))

-- Zen Mode / Waybar restart
hl.bind(mainMod .. " + Escape",    hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/zen-mode.sh"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(HOME .. "/.config/hypr/reload.sh"))

-- Glass theme toggle
hl.bind(mainMod .. " + G",        hl.dsp.exec_cmd(HOME .. "/.dotfiles/hypr/scripts/glass-theme.sh toggle"))

-- GTK theme
hl.bind(mainMod .. " + CTRL + G",  hl.dsp.exec_cmd(HOME .. "/.config/hypr/scripts/apply-gtk-theme.sh"))

-- Rofi
hl.bind(mainMod .. " + V",   hl.dsp.exec_cmd(HOME .. "/.dotfiles/rofi/clipboard.sh"))
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("rofi -show window"))

-- Dotfiles Manager
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("python3 " .. HOME .. "/.dotfiles/dotfiles-manager/main.py"))
