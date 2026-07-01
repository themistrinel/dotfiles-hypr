#!/usr/bin/env bash
# theme-switch.sh — troca o tema do sistema inteiro
# Uso: theme-switch.sh [catppuccin|gruvbox]

set -euo pipefail

DOTFILES="$HOME/.dotfiles"
THEME="${1:-}"

if [[ -z "$THEME" ]]; then
    echo "Temas disponíveis: catppuccin, gruvbox"
    read -rp "Escolha: " THEME
fi

case "$THEME" in
    catppuccin)
        # ── Cores ────────────────────────────────────────────
        BG="#1e1e2e";  BG_PLAIN="1e1e2e"
        FG="#cdd6f4";  FG_PLAIN="cdd6f4"
        SEL_BG="#313244"
        SEL_FG="#89b4fa"
        BORDER="#4c7899"
        CURSOR="#cdd6f4"; CURSOR_PLAIN="CDD6F4"
        # normal
        C0="45475a"; C1="f38ba8"; C2="a6e3a1"; C3="f9e2af"
        C4="89b4fa"; C5="f5c2e7"; C6="94e2d5"; C7="bac2de"
        # bright
        C8="585b70"; C9="f38ba8"; C10="a6e3a1"; C11="f9e2af"
        C12="89b4fa"; C13="f5c2e7"; C14="94e2d5"; C15="a6adc8"
        # i3 / bar extras
        I3_INACTIVE_BG="#1a1a2e"; I3_INACTIVE_FG="#888888"
        I3_UNFOCUSED="#555555"
        BAR_SEP="#313244"
        # gtk
        GTK_THEME="Adwaita-dark"
        NVIM_SCHEME="tokyonight"
        # i3status-rust
        BAR_GOOD_FG="#a6e3a1"; BAR_WARN_FG="#fab387"; BAR_CRIT_FG="#f38ba8"
        ;;
    gruvbox)
        BG="#282828";  BG_PLAIN="282828"
        FG="#ebdbb2";  FG_PLAIN="ebdbb2"
        SEL_BG="#3c3836"
        SEL_FG="#83a598"
        BORDER="#458588"
        CURSOR="#ebdbb2"; CURSOR_PLAIN="EBDBB2"
        C0="282828"; C1="cc241d"; C2="98971a"; C3="d79921"
        C4="458588"; C5="b16286"; C6="689d6a"; C7="a89984"
        C8="928374"; C9="fb4934"; C10="b8bb26"; C11="fabd2f"
        C12="83a598"; C13="d3869b"; C14="8ec07c"; C15="ebdbb2"
        I3_INACTIVE_BG="#1d2021"; I3_INACTIVE_FG="#928374"
        I3_UNFOCUSED="#665c54"
        BAR_SEP="#3c3836"
        GTK_THEME="Adwaita-dark"
        NVIM_SCHEME="gruvbox"
        BAR_GOOD_FG="#b8bb26"; BAR_WARN_FG="#fabd2f"; BAR_CRIT_FG="#fb4934"
        ;;
    *)
        echo "Tema desconhecido: $THEME" >&2; exit 1 ;;
esac

# ── Alacritty ────────────────────────────────────────────────
cat > "$DOTFILES/alacritty/alacritty.toml" <<EOF
# alacritty config — ~/.dotfiles/alacritty/alacritty.toml
# $THEME

[font]
normal = { family = "JetBrainsMono Nerd Font", style = "Regular" }
bold   = { family = "JetBrainsMono Nerd Font", style = "Bold" }
italic = { family = "JetBrainsMono Nerd Font", style = "Italic" }
size   = 11.0

[window]
padding             = { x = 8, y = 8 }
decorations         = "none"
opacity             = 1.0
dynamic_title       = true

[scrolling]
history = 10000

[cursor]
style = { shape = "Block", blinking = "Never" }

[colors.primary]
background = "$BG"
foreground = "$FG"

[colors.cursor]
text   = "$BG"
cursor = "$FG"

[colors.normal]
black   = "#$C0"
red     = "#$C1"
green   = "#$C2"
yellow  = "#$C3"
blue    = "#$C4"
magenta = "#$C5"
cyan    = "#$C6"
white   = "#$C7"

[colors.bright]
black   = "#$C8"
red     = "#$C9"
green   = "#$C10"
yellow  = "#$C11"
blue    = "#$C12"
magenta = "#$C13"
cyan    = "#$C14"
white   = "#$C15"
EOF

# ── Foot ─────────────────────────────────────────────────────
cat > "$DOTFILES/foot/foot.ini" <<EOF
# foot config — ~/.dotfiles/foot/foot.ini
# $THEME

[main]
font=JetBrains Mono:size=11
term=xterm-256color

[scrollback]
lines=10000

[cursor]
blink=no
style=block

[colors-dark]
background=$BG_PLAIN
foreground=$FG_PLAIN
regular0=$C0
regular1=$C1
regular2=$C2
regular3=$C3
regular4=$C4
regular5=$C5
regular6=$C6
regular7=$C7
bright0=$C8
bright1=$C9
bright2=$C10
bright3=$C11
bright4=$C12
bright5=$C13
bright6=$C14
bright7=$C15
EOF

# ── Xresources ───────────────────────────────────────────────
cat > "$DOTFILES/x11/Xresources" <<EOF
! ~/.dotfiles/x11/Xresources — $THEME

URxvt.font:             xft:JetBrains Mono:size=11
URxvt.boldFont:         xft:JetBrains Mono:bold:size=11
URxvt.geometry:         120x34
URxvt.scrollBar:        false
URxvt.saveLines:        10000
URxvt.cursorBlink:      false
URxvt.cursorColor:      #$CURSOR_PLAIN
URxvt.shell:            /bin/fish
URxvt.borderLess:       false
URxvt.internalBorder:   8
URxvt.externalBorder:   0

URxvt.background:       ${BG^^}
URxvt.foreground:       ${FG^^}
URxvt.color0:           #${C0^^}
URxvt.color1:           #${C1^^}
URxvt.color2:           #${C2^^}
URxvt.color3:           #${C3^^}
URxvt.color4:           #${C4^^}
URxvt.color5:           #${C5^^}
URxvt.color6:           #${C6^^}
URxvt.color7:           #${C7^^}
URxvt.color8:           #${C8^^}
URxvt.color9:           #${C9^^}
URxvt.color10:          #${C10^^}
URxvt.color11:          #${C11^^}
URxvt.color12:          #${C12^^}
URxvt.color13:          #${C13^^}
URxvt.color14:          #${C14^^}
URxvt.color15:          #${C15^^}

URxvt.iso14755:         false
URxvt.iso14755_52:      false
URxvt.keysym.Shift-Control-C: eval:selection_to_clipboard
URxvt.keysym.Shift-Control-V: eval:paste_clipboard
EOF

# ── Rofi ─────────────────────────────────────────────────────
cat > "$DOTFILES/rofi/config.rasi" <<EOF
/* rofi config — ~/.dotfiles/rofi/config.rasi */

configuration {
    modi:           "drun,run,window";
    font:           "JetBrains Mono 11";
    show-icons:     false;
    drun-display-format: "{name}";
    display-drun:   " Run";
    display-run:    " Exec";
    display-window: " Win";
}

* {
    bg:      $BG;
    fg:      $FG;
    sel-bg:  $SEL_BG;
    sel-fg:  $SEL_FG;
    border:  $BORDER;

    background-color: transparent;
    text-color:       @fg;
}

window {
    background-color: @bg;
    border:           2px solid;
    border-color:     @border;
    width:            480px;
    border-radius:    4px;
}

mainbox   { padding: 8px; }
inputbar  { children: [prompt, entry]; padding: 6px 0; }

prompt {
    text-color: @sel-fg;
    padding:    0 8px 0 0;
}

entry {
    placeholder:       "Search...";
    placeholder-color: #${C8};
}

listview {
    lines:   8;
    padding: 4px 0 0 0;
    border:  1px 0 0 0;
    border-color: $SEL_BG;
}

element         { padding: 6px 8px; border-radius: 2px; }
element normal.normal { background-color: transparent; }
element selected.normal { background-color: @sel-bg; text-color: @sel-fg; }
element alternate.normal { background-color: transparent; }
EOF

# ── i3 colors (sed in-place nas linhas de cores) ─────────────
I3="$DOTFILES/i3/config"
sed -i "s|client.focused .*|client.focused          $BORDER $BG $FG $BORDER   $BORDER|" "$I3"
sed -i "s|client.focused_inactive .*|client.focused_inactive #333333 $I3_INACTIVE_BG $I3_INACTIVE_FG #333333   #333333|" "$I3"
sed -i "s|client.unfocused .*|client.unfocused        $BG $BG #$I3_UNFOCUSED $BG   $BG|" "$I3"
sed -i "s|exec        --no-startup-id xsetroot.*|exec        --no-startup-id xsetroot -solid \"$BG\"|" "$I3"
# bar colors
sed -i "s|background #[0-9a-fA-F]*$|background $BG|" "$I3"
sed -i "s|statusline #[0-9a-fA-F]*$|statusline $FG|" "$I3"
sed -i "s|separator  #[0-9a-fA-F]*$|separator  $BAR_SEP|" "$I3"
sed -i "s|focused_workspace .*|focused_workspace   $BORDER $BG $FG|" "$I3"
sed -i "s|inactive_workspace .*|inactive_workspace  $BG $BG #$I3_UNFOCUSED|" "$I3"

# ── GTK ──────────────────────────────────────────────────────
cat > "$DOTFILES/gtk/settings.ini" <<EOF
[Settings]
gtk-theme-name=$GTK_THEME
gtk-icon-theme-name=Adwaita
gtk-font-name=JetBrains Mono 10
gtk-application-prefer-dark-theme=true
EOF
cat > "$DOTFILES/gtk/gtkrc-2.0" <<EOF
gtk-theme-name="$GTK_THEME"
gtk-icon-theme-name="Adwaita"
gtk-font-name="JetBrains Mono 10"
EOF

# ── i3status-rust ────────────────────────────────────────────
cat > "$DOTFILES/i3status-rust/config.toml" <<EOF
# i3status-rust config — ~/.dotfiles/i3status-rust/config.toml

[theme]
theme = "plain"

[theme.overrides]
idle_bg     = "$BG"
idle_fg     = "$FG"
good_bg     = "$BG"
good_fg     = "$BAR_GOOD_FG"
warning_bg  = "$BG"
warning_fg  = "$BAR_WARN_FG"
critical_bg = "$BG"
critical_fg = "$BAR_CRIT_FG"
separator   = "  "

[icons]
icons = "none"

[[block]]
block = "amd_gpu"
format = " GPU \$utilization"
interval = 3

[[block]]
block = "cpu"
format = " CPU \$utilization"
interval = 3

[[block]]
block = "memory"
format = " MEM \$mem_used.eng(w:3,u:B,p:Gi)/\$mem_total.eng(w:3,u:B,p:Gi)"
interval = 5

[[block]]
block = "disk_space"
path = "/"
format = " DISK \$available"
interval = 20
warning = 20.0
alert = 10.0

[[block]]
block = "net"
device = "enp7s0"
format = " ↓\$speed_down.eng(w:4,u:B,p:Mi) ↑\$speed_up.eng(w:4,u:B,p:Mi)"
interval = 1

[[block]]
block = "time"
interval = 60
EOF
[[ -f "$HOME/.config/i3status-rust/config.toml" ]] && \
    cp "$DOTFILES/i3status-rust/config.toml" "$HOME/.config/i3status-rust/config.toml" 2>/dev/null || true

# ── Nvim colorscheme ─────────────────────────────────────────
NVIM_FILE="$DOTFILES/nvim/lua/plugins/colorscheme.lua"
if [[ "$NVIM_SCHEME" == "gruvbox" ]]; then
    cat > "$NVIM_FILE" <<'EOF'
return {
  "ellisonleao/gruvbox.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("gruvbox").setup({ contrast = "hard" })
    vim.o.background = "dark"
    vim.cmd.colorscheme("gruvbox")
  end,
}
EOF
else
    cat > "$NVIM_FILE" <<'EOF'
return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("tokyonight").setup({
      style = "night",
      transparent = false,
      terminal_colors = true,
      styles = { sidebars = "transparent", floats = "transparent" },
    })
    vim.cmd.colorscheme("tokyonight")
  end,
}
EOF
fi

# ── Aplicar symlinks / xrdb ───────────────────────────────────
[[ -f "$HOME/.Xresources" ]] && xrdb -merge "$DOTFILES/x11/Xresources" 2>/dev/null || true
[[ -f "$HOME/.config/alacritty/alacritty.toml" ]] && \
    cp "$DOTFILES/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml" 2>/dev/null || true
[[ -f "$HOME/.config/foot/foot.ini" ]] && \
    cp "$DOTFILES/foot/foot.ini" "$HOME/.config/foot/foot.ini" 2>/dev/null || true
[[ -f "$HOME/.config/rofi/config.rasi" ]] && \
    cp "$DOTFILES/rofi/config.rasi" "$HOME/.config/rofi/config.rasi" 2>/dev/null || true
[[ -f "$HOME/.config/gtk-3.0/settings.ini" ]] && \
    cp "$DOTFILES/gtk/settings.ini" "$HOME/.config/gtk-3.0/settings.ini" 2>/dev/null || true
[[ -f "$HOME/.gtkrc-2.0" ]] && \
    cp "$DOTFILES/gtk/gtkrc-2.0" "$HOME/.gtkrc-2.0" 2>/dev/null || true

# Mata i3status-rs — o i3 relança automaticamente após reload
pkill -x i3status-rs 2>/dev/null || true
sleep 0.3
i3-msg reload 2>/dev/null || true

echo "✓ Tema '$THEME' aplicado."
