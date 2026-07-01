#!/usr/bin/env python3
import gi, subprocess, os

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw, Gio, GLib

DOTFILES = os.path.expanduser("~/.dotfiles")

KEYBINDS = [
    ("Window Management", [
        ("Super + Q", "Close active window"),
        ("Super + W", "Toggle floating"),
        ("Super + J", "Toggle split (dwindle)"),
        ("Super + Shift + Arrows", "Move window"),
        ("Super + M", "Exit Hyprland"),
    ]),
    ("Applications", [
        ("Super + Return", "Terminal (foot)"),
        ("Super + E", "File Manager (Thunar)"),
        ("Super + Space", "Launcher (Rofi drun)"),
        ("Super + Tab", "Window Switcher (Rofi)"),
        ("Super + V", "Clipboard Manager"),
        ("Super + B", "Browser (Zen)"),
        ("Super + C", "VS Code"),
        ("Super + P", "Color Picker (hyprpicker)"),
    ]),
    ("System", [
        ("Super + Ctrl + W", "Wallpaper Selector (Waypaper)"),
        ("Super + Shift + W", "Reload Configurations"),
        ("Super + Escape", "Zen Mode / Toggle Waybar"),
        ("Super + Ctrl + T", "Toggle Waybar Theme"),
        ("Super + Ctrl + G", "Apply GTK Theme"),
        ("Super + Shift + S", "Screenshot (area)"),
        ("Super + R", "Screen Record"),
        ("Super + Ctrl + R", "Audio Record"),
        ("Super + Shift + O", "OCR"),
    ]),
    ("Workspaces", [
        ("Super + 1-0", "Switch workspace"),
        ("Super + Shift + 1-0", "Move window to workspace"),
        ("Super + S", "Toggle Special Workspace"),
        ("Super + Alt + S", "Move to Special Workspace"),
        ("Super + Scroll", "Navigate workspaces"),
    ]),
    ("Zellij", [
        ("Alt + h/j/k/l", "Move focus between panes"),
        ("Alt + n", "New pane"),
        ("Alt + f", "Toggle floating panes"),
        ("Ctrl + q", "Quit Zellij"),
        ("Ctrl + p → d/r", "Split down / right"),
        ("Ctrl + t → n", "New tab"),
        ("Ctrl + s → s", "Search scrollback"),
    ]),
]

CONFIGS = [
    ("Waybar", f"{DOTFILES}/waybar/style.css", "css"),
    ("Waybar Config", f"{DOTFILES}/waybar/config.jsonc", "json"),
    ("Hyprland", f"{DOTFILES}/hypr/hyprland.conf", "conf"),
    ("Keybinds", f"{DOTFILES}/hypr/keybinds.conf", "conf"),
    ("Window Rules", f"{DOTFILES}/hypr/windowsrules.conf", "conf"),
    ("Exec Autostart", f"{DOTFILES}/hypr/exec.conf", "conf"),
    ("Monitors", f"{DOTFILES}/hypr/monitors.conf", "conf"),
    ("Kitty", f"{DOTFILES}/kitty/kitty.conf", "conf"),
    ("Fish", f"{DOTFILES}/fish/config.fish", "fish"),
    ("Dunst", f"{DOTFILES}/dunst/dunstrc", "conf"),
    ("Fastfetch", f"{DOTFILES}/fastfetch/config.jsonc", "json"),
    ("Zellij", f"{DOTFILES}/zellij/config.kdl", "kdl"),
    ("Rofi", f"{DOTFILES}/rofi/config.rasi", "rasi"),
    ("Wezterm", f"{DOTFILES}/wezterm/wezterm.lua", "lua"),
]

THEME_CONF = f"{DOTFILES}/hypr/scripts/theme-schedule.conf"
WALLPAPER_DIR = os.path.expanduser("~/Pictures/Wallpapers")
WAL_PRESETS = ["dark", "soft", "light", "earthy", "muted", "colorz"]

THEME_KEYS = {
    "LIGHT_WALLPAPER": (r'LIGHT_WALLPAPER="([^"]*)"', 'LIGHT_WALLPAPER="{}"'),
    "DARK_WALLPAPER":  (r'DARK_WALLPAPER="([^"]*)"',  'DARK_WALLPAPER="{}"'),
    "LIGHT_PRESET":    (r'LIGHT_PRESET="([^"]*)"',    'LIGHT_PRESET="{}"'),
    "DARK_PRESET":     (r'DARK_PRESET="([^"]*)"',     'DARK_PRESET="{}"'),
    "LIGHT_START":     (r'LIGHT_START="([^"]*)"',     'LIGHT_START="{}"'),
    "DARK_START":      (r'DARK_START="([^"]*)"',      'DARK_START="{}"'),
}


def read_theme_conf():
    import re
    result = {}
    try:
        with open(THEME_CONF) as f:
            content = f.read()
        for key, (pattern, _) in THEME_KEYS.items():
            m = re.search(pattern, content)
            result[key] = m.group(1) if m else ""
    except Exception:
        pass
    return result


def write_theme_conf(key, value):
    import re
    _, fmt = THEME_KEYS[key]
    pattern, _ = THEME_KEYS[key]
    try:
        with open(THEME_CONF) as f:
            content = f.read()
        new_content = re.sub(pattern, fmt.format(value), content)
        with open(THEME_CONF, "w") as f:
            f.write(new_content)
    except Exception as e:
        print(f"Error writing theme conf: {e}")


def pick_wallpaper_dialog(parent, callback):
    dialog = Gtk.FileDialog()
    f = Gio.File.new_for_path(WALLPAPER_DIR)
    dialog.set_initial_folder(f)
    filter_ = Gtk.FileFilter()
    filter_.set_name("Images")
    for pat in ["*.jpg", "*.jpeg", "*.png", "*.gif", "*.webp", "*.mp4", "*.mkv"]:
        filter_.add_pattern(pat)
    store = Gio.ListStore.new(Gtk.FileFilter)
    store.append(filter_)
    dialog.set_filters(store)
    dialog.open(parent, None, lambda d, r: _on_file_picked(d, r, callback))


def _on_file_picked(dialog, result, callback):
    try:
        f = dialog.open_finish(result)
        if f:
            callback(f.get_path())
    except Exception:
        pass


def make_preview(path):
    """Returns a Gtk.Picture loaded from path, or a placeholder label."""
    picture = Gtk.Picture()
    picture.set_size_request(320, 180)
    picture.set_content_fit(Gtk.ContentFit.COVER)
    picture.set_can_shrink(True)
    if path and os.path.isfile(path):
        picture.set_filename(path)
    else:
        picture.set_filename(None)
    return picture


def build_wallpaper_section(win_ref, title, wall_key, preset_key, time_key, conf):
    """Builds a group + preview card for one theme (light or dark)."""
    outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)

    # Preview card
    wall_path = os.path.join(WALLPAPER_DIR, conf.get(wall_key, ""))
    picture = make_preview(wall_path)
    frame = Gtk.Frame(css_classes=["card"])
    frame.set_child(picture)
    outer.append(frame)

    group = Adw.PreferencesGroup(title=title)

    # Wallpaper row
    wall_row = Adw.ActionRow(title="Wallpaper", subtitle=conf.get(wall_key, ""))
    browse_btn = Gtk.Button(label="Browse…", valign=Gtk.Align.CENTER, css_classes=["flat"])
    def on_browse(_, row=wall_row, pic=picture, wk=wall_key):
        def cb(path):
            name = os.path.basename(path)
            write_theme_conf(wk, name)
            row.set_subtitle(name)
            pic.set_filename(path)
        pick_wallpaper_dialog(win_ref[0], cb)
    browse_btn.connect("clicked", on_browse)
    wall_row.add_suffix(browse_btn)
    group.add(wall_row)

    # Preset row
    preset_row = Adw.ComboRow(title="Pywal Preset")
    preset_row.set_model(Gtk.StringList.new(WAL_PRESETS))
    cur = conf.get(preset_key, "dark")
    preset_row.set_selected(WAL_PRESETS.index(cur) if cur in WAL_PRESETS else 0)
    preset_row.connect("notify::selected", lambda r, _, pk=preset_key:
        write_theme_conf(pk, WAL_PRESETS[r.get_selected()]))
    group.add(preset_row)

    # Time row
    time_row = Adw.EntryRow(title="Start time (HH:MM)", show_apply_button=True)
    time_row.set_text(conf.get(time_key, ""))
    time_row.connect("apply", lambda r, tk=time_key: write_theme_conf(tk, r.get_text().strip()))
    group.add(time_row)

    outer.append(group)
    return outer


def build_wallpaper_page(win_ref):
    scroll = Gtk.ScrolledWindow(vexpand=True)
    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16,
                  margin_top=16, margin_bottom=16, margin_start=16, margin_end=16)
    scroll.set_child(box)

    conf = read_theme_conf()

    box.append(build_wallpaper_section(win_ref, "☀️ Light Theme",
        "LIGHT_WALLPAPER", "LIGHT_PRESET", "LIGHT_START", conf))
    box.append(build_wallpaper_section(win_ref, "🌙 Dark Theme",
        "DARK_WALLPAPER", "DARK_PRESET", "DARK_START", conf))

    # --- Apply now ---
    apply_group = Adw.PreferencesGroup(title="Apply")
    for label, cmd in [
        ("Apply Light Theme Now",    ["bash", "-c", f"echo light > ~/.cache/wal/.theme-override && {DOTFILES}/hypr/scripts/theme-auto.sh"]),
        ("Apply Dark Theme Now",     ["bash", "-c", f"echo dark  > ~/.cache/wal/.theme-override && {DOTFILES}/hypr/scripts/theme-auto.sh"]),
        ("Apply Auto (by schedule)", ["bash", "-c", f"rm -f ~/.cache/wal/.theme-override && {DOTFILES}/hypr/scripts/theme-auto.sh"]),
    ]:
        row = Adw.ActionRow(title=label)
        btn = Gtk.Button(label="Run", valign=Gtk.Align.CENTER, css_classes=["suggested-action"])
        btn.connect("clicked", lambda _, c=cmd: subprocess.Popen(c))
        row.add_suffix(btn)
        apply_group.add(row)
    box.append(apply_group)

    return scroll


SETTINGS = [
    ("Waybar Font", f"{DOTFILES}/waybar/style.css", r"font-family:\s*([^;]+);"),
    ("Waybar Font Size", f"{DOTFILES}/waybar/style.css", r"font-size:\s*([^;]+);"),
    ("Hyprland gaps_in", f"{DOTFILES}/hypr/hyprland.conf", r"gaps_in\s*=\s*(\d+)"),
    ("Hyprland gaps_out", f"{DOTFILES}/hypr/hyprland.conf", r"gaps_out\s*=\s*(\d+)"),
    ("Hyprland border_size", f"{DOTFILES}/hypr/hyprland.conf", r"border_size\s*=\s*(\d+)"),
    ("GTK Theme", f"{DOTFILES}/hypr/hyprland.conf", r"GTK_THEME,(.+)"),
    ("Cursor Size", f"{DOTFILES}/hypr/hyprland.conf", r"XCURSOR_SIZE,(\d+)"),
    ("Terminal", f"{DOTFILES}/hypr/keybinds.conf", r"\$terminal\s*=\s*(.+)"),
    ("Browser", f"{DOTFILES}/hypr/keybinds.conf", r"\$browser\s*=\s*(.+)"),
]


def read_setting(filepath, pattern):
    import re
    try:
        with open(filepath) as f:
            for line in f:
                m = re.search(pattern, line)
                if m:
                    return m.group(1).strip()
    except Exception:
        pass
    return ""


def write_setting(filepath, pattern, new_value):
    import re
    try:
        with open(filepath) as f:
            content = f.read()
        new_content = re.sub(pattern, lambda m: m.group(0).replace(m.group(1), new_value), content, count=1)
        with open(filepath, "w") as f:
            f.write(new_content)
        return True
    except Exception as e:
        print(f"Error writing setting: {e}")
        return False


def build_keybinds_page():
    scroll = Gtk.ScrolledWindow(vexpand=True)
    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12, margin_top=16, margin_bottom=16, margin_start=16, margin_end=16)
    scroll.set_child(box)

    for section, binds in KEYBINDS:
        group = Adw.PreferencesGroup(title=section)
        for key, action in binds:
            row = Adw.ActionRow(title=action)
            label = Gtk.Label(label=key, css_classes=["monospace", "dim-label"])
            row.add_suffix(label)
            group.add(row)
        box.append(group)

    return scroll


def build_configs_page():
    scroll = Gtk.ScrolledWindow(vexpand=True)
    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12, margin_top=16, margin_bottom=16, margin_start=16, margin_end=16)
    scroll.set_child(box)

    group = Adw.PreferencesGroup(title="Config Files")
    for name, path, _ in CONFIGS:
        row = Adw.ActionRow(title=name, subtitle=path)
        btn = Gtk.Button(icon_name="document-edit-symbolic", valign=Gtk.Align.CENTER, css_classes=["flat"])
        btn.connect("clicked", lambda _, p=path: open_in_editor(p))
        row.add_suffix(btn)
        group.add(row)
    box.append(group)

    return scroll


def open_in_editor(path):
    for editor in ["code", "nvim", "nano"]:
        if subprocess.run(["which", editor], capture_output=True).returncode == 0:
            if editor == "code":
                subprocess.Popen(["code", path])
            else:
                subprocess.Popen(["kitty", "-e", editor, path])
            return


def build_settings_page():
    scroll = Gtk.ScrolledWindow(vexpand=True)
    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12, margin_top=16, margin_bottom=16, margin_start=16, margin_end=16)
    scroll.set_child(box)

    group = Adw.PreferencesGroup(title="Settings")
    for name, filepath, pattern in SETTINGS:
        value = read_setting(filepath, pattern)
        row = Adw.EntryRow(title=name, show_apply_button=True)
        row.set_text(value)

        def on_apply(entry, fp=filepath, pat=pattern):
            new_val = entry.get_text().strip()
            if write_setting(fp, pat, new_val):
                toast = Adw.Toast(title="Saved!", timeout=2)
                toast_overlay.add_toast(toast)

        row.connect("apply", on_apply)
        group.add(row)
    box.append(group)

    # Quick actions
    actions_group = Adw.PreferencesGroup(title="Quick Actions")
    actions = [
        ("Reload Hyprland", ["hyprctl", "reload"]),
        ("Restart Waybar", ["bash", "-c", "pkill waybar; waybar &"]),
        ("Apply Pywal", ["bash", "-c", "wal -i ~/Pictures -n -t -e"]),
    ]
    for label, cmd in actions:
        row = Adw.ActionRow(title=label)
        btn = Gtk.Button(label="Run", valign=Gtk.Align.CENTER, css_classes=["suggested-action"])
        btn.connect("clicked", lambda _, c=cmd: subprocess.Popen(c))
        row.add_suffix(btn)
        actions_group.add(row)
    box.append(actions_group)

    toast_overlay = Adw.ToastOverlay()
    toast_overlay.set_child(scroll)
    return toast_overlay


class DotfilesApp(Adw.Application):
    def __init__(self):
        super().__init__(application_id="com.dotfiles.manager")
        self.connect("activate", self.on_activate)

    def on_activate(self, app):
        win = Adw.ApplicationWindow(application=app, title="Dotfiles Manager", default_width=700, default_height=600)
        win_ref = [win]  # mutable ref for file dialogs

        toolbar = Adw.ToolbarView()
        header = Adw.HeaderBar()
        toolbar.add_top_bar(header)

        view_stack = Adw.ViewStack()
        view_stack.add_titled_with_icon(build_keybinds_page(), "keybinds", "Keybinds", "input-keyboard-symbolic")
        view_stack.add_titled_with_icon(build_configs_page(), "configs", "Configs", "document-edit-symbolic")
        view_stack.add_titled_with_icon(build_settings_page(), "settings", "Settings", "preferences-system-symbolic")
        view_stack.add_titled_with_icon(build_wallpaper_page(win_ref), "wallpaper", "Wallpaper", "image-x-generic-symbolic")

        switcher = Adw.ViewSwitcher(stack=view_stack, policy=Adw.ViewSwitcherPolicy.WIDE)
        header.set_title_widget(switcher)

        toolbar.set_content(view_stack)
        win.set_content(toolbar)
        win.present()


if __name__ == "__main__":
    app = DotfilesApp()
    app.run()
