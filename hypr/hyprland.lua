-- Hyprland config — migrated to Lua (0.55+)
-- https://wiki.hypr.land/Configuring/Start/

-- Load pywal colors (gerado automaticamente pelo pywal em ~/.cache/wal/)
local wal_colors_path = os.getenv("HOME") .. "/.cache/wal/colors-hyprland.lua"
local ok, colors = pcall(dofile, wal_colors_path)
if not ok or type(colors) ~= "table" then
  -- Fallback se o pywal ainda não rodou
  colors = {
    active_border_col_1 = "rgba(33ccffee)",
    active_border_col_2 = "rgba(00ff99ee)",
    inactive_border_col = "rgba(595959aa)",
  }
end

-- Helper para converter "rgb(xxxxxx)" para "rgba(xxxxxxyy)"
local function to_rgba(c, alpha_hex)
  if not c then return "rgba(ffffff" .. alpha_hex .. ")" end
  local hex = c:match("rgb%((%x+)%)")
  if hex then
    return "rgba(" .. hex .. alpha_hex .. ")"
  end
  return c
end

-- Verifica se o modo Glass está ativo
local is_glass = false
local glass_file = io.open(os.getenv("HOME") .. "/.cache/.glass-theme", "r")
if glass_file then
  local content = glass_file:read("*all") or ""
  glass_file:close()
  if content:find("on") or content:find("glass") then
    is_glass = true
  end
end
_G.is_glass = is_glass

-- Bordas: no modo glass usam gradiente translúcido com cores do wallpaper
local active_border_1, active_border_2, inactive_border
if is_glass then
  active_border_1 = to_rgba(colors.color4 or colors.active_border_col_1, "dd")
  active_border_2 = to_rgba(colors.color6 or colors.active_border_col_2, "88")
  inactive_border = to_rgba(colors.color1 or colors.inactive_border_col, "33")
else
  active_border_1 = colors.active_border_col_1
  active_border_2 = colors.active_border_col_2
  inactive_border = colors.inactive_border_col
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
hl.env("GTK_THEME",             "Adwaita-dark")
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
    border_size  = is_glass and 2 or 2,
    col = {
      active_border   = { colors = { active_border_1, active_border_2 }, angle = 45 },
      inactive_border = inactive_border,
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
    inactive_opacity = is_glass and 0.90 or 1.0,
    shadow = {
      enabled      = true,
      range        = is_glass and 12 or 4,
      render_power = is_glass and 4 or 3,
      color        = is_glass and 0x55000000 or 0xee1a1a1a,
    },
    blur = {
      enabled           = true,
      size              = is_glass and 10 or 3,
      passes            = is_glass and 4 or 1,
      vibrancy          = is_glass and 0.20 or 0.1696,
      vibrancy_darkness = 0.0,
      noise             = 0.0,
      contrast          = 1.0,
      brightness        = 1.0,
      ignore_opacity    = is_glass and true or false,
      popups            = is_glass and true or false,
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
