#!/bin/sh
# ~/.dotfiles/scripts/make-iso.sh
# Gera uma ISO live do Void Linux com seus dotfiles embutidos.
# Requer: void-mklive (sudo xbps-install void-mklive)

set -e

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
WORKDIR="/tmp/void-iso-build"
INCLUDES="$WORKDIR/includes"
# Resolve OUTPUT como caminho absoluto a partir do diretório de quem chamou o sudo
_CALLER_DIR="${SUDO_PWD:-$(pwd)}"
OUTPUT="$(cd "$_CALLER_DIR" && realpath -m "${1:-$HOME/void-custom.iso}")"

# Arquitetura (x86_64 ou x86_64-musl)
ARCH="x86_64"

PACKAGES="
    base-system

    i3 i3status-rust rofi alacritty foot fish-shell
    picom neovim git fastfetch starship htop

    xorg-minimal xorg-input-drivers xorg-video-drivers
    xinit xrandr xsetroot xauth setxkbmap xclip xdotool xdg-utils
    xcursor-themes xcursor-vanilla-dmz

    lightdm lightdm-gtk-greeter
    network-manager-applet gnome-keyring

    alsa-pipewire pipewire pulseaudio
    firefox mpv imv nsxiv feh flameshot

    bat eza inxi

    udisks2 gvfs-afc gvfs-mtp gvfs-smb
    lxappearance gnome-themes-standard papirus-icon-theme

    dejavu-fonts-ttf font-misc-misc terminus-font
    noto-fonts-ttf noto-fonts-emoji font-awesome6

    scrot curl wget unzip nano xz

    lvm2 cryptsetup mdadm

    mesa-vulkan-radeon

    xfce4 xfce4-pulseaudio-plugin
"

info()  { printf '\033[0;34m[info]\033[0m  %s\n' "$*"; }
ok()    { printf '\033[0;32m[ ok ]\033[0m  %s\n' "$*"; }
die()   { printf '\033[0;31m[erro]\033[0m  %s\n' "$*" >&2; exit 1; }

# ── Verificações ──────────────────────────────────────────────
[ "$(id -u)" -eq 0 ] || die "Execute como root: sudo $0 $*"
command -v git >/dev/null 2>&1 || die "git não encontrado."

MKLIVE_DIR="/opt/void-mklive"
if [ ! -f "$MKLIVE_DIR/mklive.sh" ]; then
    info "Clonando void-mklive..."
    git clone --depth=1 https://github.com/void-linux/void-mklive "$MKLIVE_DIR"
fi
MKLIVE="$MKLIVE_DIR/mklive.sh"

# ── Preparar includes (skel = home padrão do novo usuário) ────
info "Preparando includes..."
rm -rf "$WORKDIR"
mkdir -p "$INCLUDES/etc/skel"

# Copiar dotfiles para o skel (excluindo secrets e wallpapers pesados)
mkdir -p "$INCLUDES/etc/skel/.config" "$INCLUDES/etc/skel/.local/bin"
cp -r "$DOTFILES/i3"           "$INCLUDES/etc/skel/.config/i3"
cp -r "$DOTFILES/i3status-rust" "$INCLUDES/etc/skel/.config/i3status-rust"
cp -r "$DOTFILES/alacritty"    "$INCLUDES/etc/skel/.config/alacritty"
cp -r "$DOTFILES/foot"         "$INCLUDES/etc/skel/.config/foot"
cp -r "$DOTFILES/rofi"         "$INCLUDES/etc/skel/.config/rofi"
cp -r "$DOTFILES/picom"        "$INCLUDES/etc/skel/.config/picom"
cp -r "$DOTFILES/fish"         "$INCLUDES/etc/skel/.config/fish"
cp -r "$DOTFILES/gtk"          "$INCLUDES/etc/skel/.config/gtk-3.0"
cp -r "$DOTFILES/nvim"         "$INCLUDES/etc/skel/.config/nvim"
cp -r "$DOTFILES/fastfetch"   "$INCLUDES/etc/skel/.config/fastfetch"
cp    "$DOTFILES/x11/Xresources" "$INCLUDES/etc/skel/.Xresources"
cp    "$DOTFILES/x11/xprofile"   "$INCLUDES/etc/skel/.xprofile"
cp    "$DOTFILES/x11/xinitrc"    "$INCLUDES/etc/skel/.xinitrc"

# Remover secrets.fish se existir no skel
rm -f "$INCLUDES/etc/skel/.config/fish/secrets.fish"

# Cursor padrão (mãozinha clássica no Chrome/Firefox)
mkdir -p "$INCLUDES/etc/skel/.icons/default"
printf '[Icon Theme]\nName=Default\nInherits=Bibata-Modern-Classic\n' \
    > "$INCLUDES/etc/skel/.icons/default/index.theme"

# Ícones e cursor globais (afeta todos os usuários e o greeter)
mkdir -p "$INCLUDES/usr/share/icons/default"
printf '[Icon Theme]\nName=Default\nInherits=Bibata-Modern-Classic\n' \
    > "$INCLUDES/usr/share/icons/default/index.theme"

mkdir -p "$INCLUDES/etc/gtk-3.0"
cat > "$INCLUDES/etc/gtk-3.0/settings.ini" <<'EOF'
[Settings]
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
EOF

mkdir -p "$INCLUDES/etc/gtk-2.0"
cat > "$INCLUDES/etc/gtk-2.0/gtkrc" <<'EOF'
gtk-icon-theme-name="Papirus-Dark"
gtk-cursor-theme-name="Bibata-Modern-Classic"
gtk-cursor-theme-size=24
EOF

# Wallpapers
mkdir -p "$INCLUDES/etc/skel/.dotfiles"
cp -r "$DOTFILES/wallpaper" "$INCLUDES/etc/skel/.dotfiles/wallpaper"

# Copiar scripts utilitários
cp "$DOTFILES/scripts/wallpaper.sh"      "$INCLUDES/etc/skel/.local/bin/"
cp "$DOTFILES/scripts/powermenu.sh"      "$INCLUDES/etc/skel/.local/bin/"
cp "$DOTFILES/scripts/theme-switch.sh"   "$INCLUDES/etc/skel/.local/bin/"
cp "$DOTFILES/scripts/clipboard-menu.sh" "$INCLUDES/etc/skel/.local/bin/"

# Copiar install.sh para o skel (útil após instalar)
cp "$DOTFILES/install.sh" "$INCLUDES/etc/skel/.dotfiles-install.sh"
chmod +x "$INCLUDES/etc/skel/.dotfiles-install.sh"

ok "Includes prontos em $INCLUDES"

# ── JetBrainsMono Nerd Font (usada no alacritty, i3bar, rofi) ─
NERD_FONT_DIR="$INCLUDES/usr/share/fonts/JetBrainsMonoNerd"
if ! ls "$NERD_FONT_DIR"/*.ttf >/dev/null 2>&1; then
    info "Baixando JetBrainsMono Nerd Font..."
    NF_VER="v3.2.1"
    NF_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${NF_VER}/JetBrainsMono.tar.xz"
    TMP_NF=$(mktemp -d)
    curl -fsSL "$NF_URL" -o "$TMP_NF/JetBrainsMono.tar.xz"
    mkdir -p "$NERD_FONT_DIR"
    tar -xf "$TMP_NF/JetBrainsMono.tar.xz" -C "$NERD_FONT_DIR" --wildcards "*.ttf" 2>/dev/null || \
        tar -xf "$TMP_NF/JetBrainsMono.tar.xz" -C "$NERD_FONT_DIR"
    rm -rf "$TMP_NF"
    ok "JetBrainsMono Nerd Font adicionada aos includes"
fi

# ── Bibata-Modern-Classic cursor theme ───────────────────────
BIBATA_DIR="$INCLUDES/usr/share/icons/Bibata-Modern-Classic"
if [ ! -d "$BIBATA_DIR" ]; then
    info "Baixando Bibata-Modern-Classic cursor theme..."
    BIBATA_VER="v2.0.7"
    BIBATA_URL="https://github.com/ful1e5/Bibata_Cursor/releases/download/${BIBATA_VER}/Bibata-Modern-Classic.tar.xz"
    TMP_B=$(mktemp -d)
    curl -fsSL "$BIBATA_URL" -o "$TMP_B/bibata.tar.xz"
    mkdir -p "$INCLUDES/usr/share/icons"
    tar -xf "$TMP_B/bibata.tar.xz" -C "$INCLUDES/usr/share/icons"
    rm -rf "$TMP_B"
    ok "Bibata-Modern-Classic adicionado aos includes"
fi

# ── Boot direto no live (timeout 0) ──────────────────────────
mkdir -p "$INCLUDES/boot/grub"
cat > "$INCLUDES/boot/grub/grub_void.cfg" <<'EOF'
set timeout=0
set default=0
EOF

# ── Autologin no live (LightDM → usuário anon) ───────────────
# O dracut do void-mklive cria o usuário anon no boot via adduser.sh e
# configura o lightdm via display-manager-autologin.sh fazendo sed nas
# linhas comentadas (#autologin-user=). Mantemos as linhas comentadas
# para o dracut funcionar corretamente.
mkdir -p "$INCLUDES/etc/lightdm"
cat > "$INCLUDES/etc/lightdm/lightdm.conf" <<'EOF'
[LightDM]
minimum-vt=1

[Seat:*]
autologin-guest=false
#autologin-user=
#autologin-user-timeout=0
#autologin-session=
greeter-session=lightdm-gtk-greeter
pam-service=lightdm-autologin
#user-session=
EOF

# Arquivo .session lido pelo dracut para preencher autologin-session e user-session
printf 'i3' > "$INCLUDES/etc/lightdm/.session"

# Script de postsetup: cria grupo autologin com anon pré-adicionado no rootfs
# (o adduser.sh do dracut roda depois e faz useradd anon — o grupo já existe)
cat > "$WORKDIR/postsetup.sh" <<'POSTEOF'
#!/bin/sh
ROOTFS="$1"
chroot "$ROOTFS" groupadd -f autologin
# Pré-adiciona anon ao grupo; o adduser.sh do dracut só faz useradd, não remove grupos
sed -i 's/^autologin:x:\([0-9]*\):$/autologin:x:\1:anon/' "$ROOTFS/etc/group"
POSTEOF
chmod +x "$WORKDIR/postsetup.sh"

# DNS no live (resolv.conf com nameservers públicos)
mkdir -p "$INCLUDES/etc"
cat > "$INCLUDES/etc/resolv.conf" <<'EOF'
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF

# ── Gerar ISO ─────────────────────────────────────────────────
info "Gerando ISO (isso pode demorar alguns minutos)..."
mkdir -p "$(dirname "$OUTPUT")"

# shellcheck disable=SC2086
cd "$MKLIVE_DIR" && "$MKLIVE" \
    -a "$ARCH" \
    -p "$(echo $PACKAGES | tr '\n' ' ')" \
    -I "$INCLUDES" \
    -x "$WORKDIR/postsetup.sh" \
    -o "$OUTPUT"

ok "ISO gerada: $OUTPUT"
info "Grave com: dd if=$OUTPUT of=/dev/sdX bs=4M status=progress"

# Limpar caches de build (pacotes xbps e workdir temporário)
rm -rf "$MKLIVE_DIR"/xbps-cachedir-* "$WORKDIR"
ok "Cache de build removido"
