#!/bin/sh
# ~/.dotfiles/scripts/post-install.sh
# Instala pacotes de desenvolvimento removidos da ISO para economizar espaço.
# Execute após instalar o Void Linux no sistema.

set -e

[ "$(id -u)" -eq 0 ] || exec sudo "$0" "$@"

info() { printf '\033[0;34m[info]\033[0m  %s\n' "$*"; }
ok()   { printf '\033[0;32m[ ok ]\033[0m  %s\n' "$*"; }

PACKAGES="
    base-devel
    nodejs python3-pip python3-pipx
    flatpak
    yt-dlp
    mesa-demos
    dmenu rxvt-unicode
    tmux ranger
    xwinwrap
"

info "Atualizando repositórios..."
xbps-install -Su

info "Instalando pacotes de desenvolvimento..."
# shellcheck disable=SC2086
xbps-install -y $PACKAGES

ok "Feito! Pacotes instalados com sucesso."
info "Para habilitar flatpak:"
printf '    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo\n'
