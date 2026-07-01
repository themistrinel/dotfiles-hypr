#!/bin/sh
LOGOUT="  Logout"
REBOOT="  Reiniciar"
POWEROFF="  Desligar"

choice=$(printf "%s\n%s\n%s" "$LOGOUT" "$REBOOT" "$POWEROFF" \
    | rofi -dmenu -p "Power" -theme ~/.config/rofi/config.rasi)

case "$choice" in
    "$LOGOUT")   i3-msg exit ;;
    "$REBOOT")   sudo reboot ;;
    "$POWEROFF") sudo poweroff ;;
esac
