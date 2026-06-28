# Cursor Setup — i3 (X11) vs Hyprland (Wayland)

Dois cursores diferentes por sessão, sem conflito.

| Sessão    | Cursor            |
|-----------|-------------------|
| i3 (X11)  | Capitaine-Gruvbox |
| Hyprland  | FrierenBLZ        |

---

## Como funciona

### i3 / X11

O X11 resolve o cursor nesta ordem de prioridade:

1. `$XCURSOR_THEME` (variável de ambiente)
2. `~/.Xresources` → `Xcursor.theme`
3. `~/.icons/default/index.theme` → `Inherits=`

Usamos os três para garantir consistência:

**`~/.xprofile`**
```bash
export XCURSOR_THEME=Capitaine-Gruvbox
```

**`~/.Xresources`**
```
Xcursor.theme: Capitaine-Gruvbox
Xcursor.size:  24
```

**`~/.icons/default/index.theme`**
```ini
[Icon Theme]
Name=Default
Inherits=Capitaine-Gruvbox
```

**`~/.config/i3/config`** (para root window e statusbar)
```
exec_always --no-startup-id gsettings set org.gnome.desktop.interface cursor-theme 'Capitaine-Gruvbox'
exec_always --no-startup-id xsetroot -cursor_name left_ptr
```

O tema deve estar instalado em `~/.icons/Capitaine-Gruvbox/cursors/`.

---

### Hyprland / Wayland

O Hyprland ignora `~/.xprofile` e `~/.Xresources`. Ele usa:

**`~/.config/hypr/hyprland.conf`**
```
env = XCURSOR_THEME,FrierenBLZ
env = XCURSOR_SIZE,24
```

**`~/.config/hypr/exec.conf`** — script que lê o GTK settings e aplica via hyprctl:
```
exec-once = ~/.config/hypr/scripts/gtk.sh
```

**`~/.config/gtk-3.0/settings.ini`**
```ini
gtk-cursor-theme-name=FrierenBLZ
gtk-cursor-theme-size=24
```

O `gtk.sh` lê o `settings.ini` e roda `hyprctl setcursor FrierenBLZ 24` no startup.

**`~/.icons/default/index.theme`** deve apontar para `FrierenBLZ` (fallback para apps Wayland/GTK que não respeitam gsettings):
```ini
[Icon Theme]
Name=Default
Inherits=FrierenBLZ
```

> ⚠️ Este arquivo é compartilhado entre sessões. O `install.sh` define conforme a sessão instalada. Se instalar ambas, o Hyprland sobrescreve via `hyprctl setcursor` no startup, prevalecendo sobre o `default/index.theme`.

---

## Instalação do tema Capitaine-Gruvbox

```bash
# Copiar para ~/.icons (disponível apenas para o usuário)
mkdir -p ~/.icons/Capitaine-Gruvbox
cp -r "/path/to/Capitaine Cursors (Gruvbox)/cursors/" ~/.icons/Capitaine-Gruvbox/
```

Ou via `install.sh` que copia de `$DOTFILES/cursors/Capitaine-Gruvbox/`.

---

## Troubleshooting

**Cursor errado no desktop (root window) no i3:**
```bash
xsetroot -cursor_name left_ptr
```

**Cursor errado em apps GTK no i3:**
```bash
gsettings set org.gnome.desktop.interface cursor-theme 'Capitaine-Gruvbox'
```

**Cursor errado no Hyprland:**
```bash
hyprctl setcursor FrierenBLZ 24
```

**Verificar qual cursor está ativo:**
```bash
gsettings get org.gnome.desktop.interface cursor-theme
echo $XCURSOR_THEME
cat ~/.icons/default/index.theme
```
