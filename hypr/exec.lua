---------------------
---- AUTOSTART ----
---------------------
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

hl.on("hyprland.start", function()
  hl.exec_cmd("waybar")
  hl.exec_cmd("bash -c 'if command -v awww-daemon >/dev/null 2>&1; then exec awww-daemon; elif command -v swww-daemon >/dev/null 2>&1; then exec swww-daemon; fi'")
  hl.exec_cmd("waypaper --restore")
  -- hl.exec_cmd("discord")
  -- hl.exec_cmd("spotify")
  hl.exec_cmd("/usr/lib/xdg-desktop-portal-hyprland")
  hl.exec_cmd("/usr/lib/xdg-desktop-portal")
  hl.exec_cmd("dunst")
  hl.exec_cmd("nm-applet --indicator")
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
  hl.exec_cmd("udiskie")
  hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
  hl.exec_cmd("gnome-keyring-daemon --start --components=secrets,ssh")
  hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/gtk.sh")
  hl.exec_cmd(os.getenv("HOME") .. "/.dotfiles/hypr/scripts/theme-auto.sh --daemon")
  hl.exec_cmd("/usr/bin/node /home/abyssal/.npm-global/lib/node_modules/9router/cli.js --tray --skip-update")
end)
