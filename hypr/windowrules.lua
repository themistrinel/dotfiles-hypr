--------------------------
---- WINDOW RULES ----
--------------------------
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

local is_glass = _G.is_glass or false

-- Global transparency: no modo glass permite translucência real
hl.window_rule({
  name    = "global-transparency",
  match   = { class = ".*" },
  opacity = is_glass and "0.88 0.78" or "0.98 0.95",
})

-- Helium Browser — no extra transparency normal, translúcido elegante no glass
hl.window_rule({
  name    = "helium-opacity",
  match   = { class = "^[Hh]elium$" },
  opacity = is_glass and "0.95 0.88" or "1.0 1.0",
})

-- IDEs e Editores de Código — Transparência acrílica balanceada mantendo nitidez e brilho de texto
hl.window_rule({
  name    = "antigravity-opacity",
  match   = { class = "^([Aa]ntigravity.*)$" },
  opacity = is_glass and "0.96 override 0.90 override" or "0.98 0.95",
})
hl.window_rule({
  name    = "code-opacity",
  match   = { class = "^(code|Code|VSCodium|vscodium|cursor)$" },
  opacity = is_glass and "0.96 override 0.90 override" or "0.98 0.95",
})

-- Disable blur for XWayland windows
hl.window_rule({
  name     = "no-blur-xwayland",
  match    = { xwayland = true },
  no_blur  = true,
})

-- Suppress maximize events for all windows
hl.window_rule({
  name           = "suppress-maximize",
  match          = { class = ".*" },
  suppress_event = "maximize",
})

-- Fix XWayland drag issues
hl.window_rule({
  name       = "fix-xwayland-drags",
  match      = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
  no_focus   = true,
})

-- Floating windows
hl.window_rule({ name = "float-blueberry",  match = { class = "^(blueberry%.py)$" },                float = true })
hl.window_rule({ name = "float-guifetch",   match = { class = "^(guifetch)$" },                      float = true })

hl.window_rule({ name = "float-pavucontrol",   match = { class = "^(pavucontrol)$" },                         float = true })
hl.window_rule({ name = "size-pavucontrol",    match = { class = "^(pavucontrol)$" },                         size = "45% 45%" })
hl.window_rule({ name = "center-pavucontrol",  match = { class = "^(pavucontrol)$" },                         center = true })
hl.window_rule({ name = "ws-pavucontrol",      match = { class = "^(pavucontrol)$" },                         workspace = "unset" })

hl.window_rule({ name = "float-pavu2",   match = { class = "^(org%.pulseaudio%.pavucontrol)$" },     float = true })
hl.window_rule({ name = "size-pavu2",    match = { class = "^(org%.pulseaudio%.pavucontrol)$" },     size = "45% 45%" })
hl.window_rule({ name = "center-pavu2", match = { class = "^(org%.pulseaudio%.pavucontrol)$" },     center = true })
hl.window_rule({ name = "ws-pavu2",     match = { class = "^(org%.pulseaudio%.pavucontrol)$" },     workspace = "unset" })

hl.window_rule({ name = "float-nm",   match = { class = "^(nm-connection-editor)$" },               float = true })
hl.window_rule({ name = "size-nm",    match = { class = "^(nm-connection-editor)$" },               size = "45% 45%" })
hl.window_rule({ name = "center-nm", match = { class = "^(nm-connection-editor)$" },               center = true })

-- Tiling
hl.window_rule({ name = "tile-warp", match = { class = "^dev%.warp%.Warp$" }, tile = true })

-- Picture-in-Picture
hl.window_rule({
  name             = "pip",
  match            = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
  float            = true,
  keep_aspect_ratio = true,
  move             = "73% 72%",
  size             = "25% 25%",
  pin              = true,
})

-- Dialog / file picker windows
local dialog_titles = {
  "^(Open File)(.*)",
  "^(Select a File)(.*)",
  "^(Choose wallpaper)(.*)",
  "^(Open Folder)(.*)",
  "^(Save As)(.*)",
  "^(Library)(.*)",
  "^(File Upload)(.*)",
}
for i, t in ipairs(dialog_titles) do
  hl.window_rule({ name = "float-dialog-" .. i, match = { title = t }, float = true })
  hl.window_rule({ name = "center-dialog-" .. i, match = { title = t }, center = true })
end

-- Tearing for Windows executables
hl.window_rule({ name = "tearing-exe", match = { title = ".*%.exe" }, immediate = true })

-- No shadow for tiled windows
hl.window_rule({ name = "no-shadow-tiled", match = { float = false }, no_shadow = true })

-- Waypaper
hl.window_rule({ name = "float-waypaper", match = { class = "^(waypaper)$" }, float = true })
hl.window_rule({ name = "size-pwaypaper", match = { class = "^(pwaypaper)$" }, size = "45% 45%" })

-- Kitty transparency - removida, usando background_opacity do kitty.conf
-- hl.window_rule({
--   name    = "kitty-opacity",
--   match   = { class = "^(kitty)$" },
--   opacity = "0.8 0.8",
-- })

--------------------------
---- WORKSPACE RULES ----
--------------------------
-- See https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Smart gaps / no border when only one window - REMOVIDO para ter bordas sempre
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({ match = { float = false, workspace = "w[tv1]" }, border_size = 0 })
-- hl.window_rule({ match = { float = false, workspace = "w[tv1]" }, rounding = 0 })
-- hl.window_rule({ match = { float = false, workspace = "f[1]" },   border_size = 0 })
-- hl.window_rule({ match = { float = false, workspace = "f[1]" },   rounding = 0 })

-- Named workspaces
hl.workspace_rule({ workspace = "1", default_name = "一" })
hl.workspace_rule({ workspace = "2", default_name = "二" })
hl.workspace_rule({ workspace = "3", default_name = "三" })
hl.workspace_rule({ workspace = "4", default_name = "四" })
hl.workspace_rule({ workspace = "5", default_name = "五" })

-- Special workspace gaps
hl.workspace_rule({ workspace = "special:special", gaps_out = 30 })

--------------------------
---- LAYER RULES ----
--------------------------

-- Desativa xray global para que o blur mostre as janelas reais atrás das camadas glass
-- hl.layer_rule({ name = "xray-all",        match = { namespace = ".*" },             xray = true })
hl.layer_rule({ name = "no-anim-walker",  match = { namespace = "walker" },         no_anim = true })
hl.layer_rule({ name = "no-anim-sel",     match = { namespace = "selection" },      no_anim = true })
hl.layer_rule({ name = "no-anim-over",    match = { namespace = "overview" },       no_anim = true })
hl.layer_rule({ name = "no-anim-anyrun",  match = { namespace = "anyrun" },         no_anim = true })
hl.layer_rule({ name = "no-anim-ind",     match = { namespace = "indicator.*" },    no_anim = true })
hl.layer_rule({ name = "no-anim-osk",     match = { namespace = "osk" },            no_anim = true })
hl.layer_rule({ name = "no-anim-picker",  match = { namespace = "hyprpicker" },     no_anim = true })
hl.layer_rule({ name = "no-anim-noanim",  match = { namespace = "noanim" },         no_anim = true })

hl.layer_rule({ name = "blur-waybar",     match = { namespace = "waybar" },         blur = true, ignore_alpha = 0.2, xray = false })
hl.layer_rule({ name = "blur-rofi",       match = { namespace = "rofi" },           blur = true, ignore_alpha = 0.1, xray = false })
hl.layer_rule({ name = "blur-gtk",        match = { namespace = "gtk-layer-shell" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ name = "blur-launcher",   match = { namespace = "launcher" },        blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ name = "blur-notif",      match = { namespace = "notifications" },   blur = true, ignore_alpha = 0.69 })
hl.layer_rule({ name = "blur-wlogout",    match = { namespace = "logout_dialog" },   blur = true })

-- AGS layer rules
hl.layer_rule({ name = "slide-left",      match = { namespace = "sideleft.*" },      animation = "slide left" })
hl.layer_rule({ name = "slide-right",     match = { namespace = "sideright.*" },     animation = "slide right" })
hl.layer_rule({ name = "blur-session",    match = { namespace = "session[0-9]*" },   blur = true })
hl.layer_rule({ name = "blur-bar",        match = { namespace = "bar[0-9]*" },       blur = true, ignore_alpha = 0.6 })
hl.layer_rule({ name = "blur-barcorner",  match = { namespace = "barcorner.*" },     blur = true, ignore_alpha = 0.6 })
hl.layer_rule({ name = "blur-dock",       match = { namespace = "dock[0-9]*" },      blur = true, ignore_alpha = 0.6 })
hl.layer_rule({ name = "blur-ind2",       match = { namespace = "indicator.*" },     blur = true, ignore_alpha = 0.6 })
hl.layer_rule({ name = "blur-overview",   match = { namespace = "overview[0-9]*" },  blur = true, ignore_alpha = 0.6 })
hl.layer_rule({ name = "blur-cheatsheet", match = { namespace = "cheatsheet[0-9]*" },blur = true, ignore_alpha = 0.6 })
hl.layer_rule({ name = "blur-sideright",  match = { namespace = "sideright[0-9]*" }, blur = true, ignore_alpha = 0.6 })
hl.layer_rule({ name = "blur-sideleft",   match = { namespace = "sideleft[0-9]*" },  blur = true, ignore_alpha = 0.6 })
hl.layer_rule({ name = "blur-osk",        match = { namespace = "osk[0-9]*" },       blur = true, ignore_alpha = 0.6 })
