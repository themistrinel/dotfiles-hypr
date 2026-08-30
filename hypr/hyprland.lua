-- Hyprland config — migrated to Lua (0.55+)
-- https://wiki.hypr.land/Configuring/Start/

-- Load pywal colors (gerado automaticamente pelo pywal)
local ok, colors = pcall(require, "colors-hyprland")
if not ok then
  -- Fallback se o pywal ainda não rodou
  colors = {
    active_border_col_1 = "rgba(33ccffee)",
    active_border_col_2 = "rgba(00ff99ee)",
    inactive_border_col = "rgba(595959aa)",
  }
end

-- Sub-configs
require("monitors")
require("exec")
require("windowrules")
require("keybinds")

------------------------------
---- ENVIRONMENT VARIABLES ----
------------------------------
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("WLR_NO_HARDWARE_CURSORS",  "1")
hl.env("XCURSOR_SIZE",             "24")
hl.env("HYPRCURSOR_THEME",         "Adwaita")
hl.env("HYPRCURSOR_SIZE",          "24")
hl.env("XCURSOR_THEME",            "FrierenBLZ")
hl.env("QT_QPA_PLATFORMTHEME",     "qt5ct")
hl.env("QT_QPA_PLATFORM",          "wayland;xcb")
hl.env("GDK_BACKEND",              "wayland,x11")
hl.env("XDG_CURRENT_DESKTOP",      "Hyprland")
hl.env("XDG_SESSION_TYPE",         "wayland")
hl.env("XDG_SESSION_DESKTOP",      "Hyprland")
hl.env("GTK_THEME",                "Adwaita")
hl.env("GTK2_RC_FILES",            os.getenv("HOME") .. "/.config/gtk-2.0/gtkrc")
hl.env("FREETYPE_PROPERTIES",      "truetype:interpreter-version=40")

-----------------------
----- PERMISSIONS -----
-----------------------
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- hl.config({ ecosystem = { enforce_permissions = true } })
-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
  general = {
    gaps_in      = 5,
    gaps_out     = 5,
    border_size  = 2,
    col = {
      active_border   = { colors = { colors.active_border_col_1, colors.active_border_col_2 }, angle = 45 },
      inactive_border = colors.inactive_border_col,
    },
    resize_on_border = false,
    allow_tearing    = false,
    layout           = "dwindle",
  },
})

hl.config({
  cursor = {
    sync_gsettings_theme = false,
    no_hardware_cursors  = true,
  },
})

hl.config({
  decoration = {
    rounding       = 10,
    rounding_power = 2,
    active_opacity   = 1.0,
    inactive_opacity = 1.0,
    shadow = {
      enabled      = true,
      range        = 4,
      render_power = 3,
      color        = 0xee1a1a1a,
    },
    blur = {
      enabled   = true,
      size      = 3,
      passes    = 1,
      vibrancy  = 0.1696,
    },
  },
})

-- Animations
-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.config({ animations = { enabled = true } })

hl.curve("linear",         { type = "bezier", points = { {0, 0},        {1, 1} } })
hl.curve("md3_standard",   { type = "bezier", points = { {0.2, 0},      {0, 1} } })
hl.curve("md3_decel",      { type = "bezier", points = { {0.05, 0.7},   {0.1, 1} } })
hl.curve("md3_accel",      { type = "bezier", points = { {0.3, 0},      {0.8, 0.15} } })
hl.curve("overshot",       { type = "bezier", points = { {0.05, 0.9},   {0.1, 1.1} } })
hl.curve("menu_decel",     { type = "bezier", points = { {0.1, 1},      {0, 1} } })
hl.curve("menu_accel",     { type = "bezier", points = { {0.38, 0.04},  {1, 0.07} } })
hl.curve("easeOutCirc",    { type = "bezier", points = { {0, 0.55},     {0.45, 1} } })
hl.curve("easeOutExpo",    { type = "bezier", points = { {0.16, 1},     {0.3, 1} } })
hl.curve("softAcDecel",    { type = "bezier", points = { {0.26, 0.26},  {0.15, 1} } })

hl.animation({ leaf = "windows",         enabled = true, speed = 3,   bezier = "md3_decel",  style = "popin 60%" })
hl.animation({ leaf = "windowsIn",       enabled = true, speed = 3,   bezier = "md3_decel",  style = "popin 60%" })
hl.animation({ leaf = "windowsOut",      enabled = true, speed = 3,   bezier = "md3_accel",  style = "popin 60%" })
hl.animation({ leaf = "border",          enabled = true, speed = 10,  bezier = "default" })
hl.animation({ leaf = "fade",            enabled = true, speed = 3,   bezier = "md3_decel" })
hl.animation({ leaf = "layersIn",        enabled = true, speed = 3,   bezier = "menu_decel", style = "slide" })
hl.animation({ leaf = "layersOut",       enabled = true, speed = 1.6, bezier = "menu_accel" })
hl.animation({ leaf = "fadeLayersIn",    enabled = true, speed = 2,   bezier = "menu_decel" })
hl.animation({ leaf = "fadeLayersOut",   enabled = true, speed = 0.5, bezier = "menu_accel" })
hl.animation({ leaf = "workspaces",      enabled = true, speed = 7,   bezier = "menu_decel", style = "slide" })
hl.animation({ leaf = "specialWorkspace",enabled = true, speed = 3,   bezier = "md3_decel",  style = "slidevert" })

-- Layouts
hl.config({
  dwindle = { preserve_split = true },
  master  = { new_status = "master" },
})

-- Misc
hl.config({
  misc = {
    disable_autoreload       = false,
    force_default_wallpaper  = -1,
    disable_hyprland_logo    = false,
  },
})

---------------
---- INPUT ----
---------------

hl.config({
  input = {
    kb_layout  = "us",
    kb_variant = "intl",
    kb_options = "compose:ralt",
    follow_mouse   = 1,
    sensitivity    = 0,
    scroll_factor  = 1.0,
    repeat_rate    = 70,
    repeat_delay   = 200,
    accel_profile  = "flat",
    touchpad = {
      natural_scroll = false,
    },
  },
})

hl.device({
  name        = "epic-mouse-v1",
  sensitivity = -0.5,
})
