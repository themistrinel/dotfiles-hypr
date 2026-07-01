# Theme Switching Fix — Dark/Light sem reiniciar apps

## Problema

Apps (Obsidian, GTK, Electron) não mudavam de tema ao trocar de dark → light, mas mudavam ao trocar para dark.

## Causa raiz

O `gsettings` só emite o sinal `SettingChanged` no D-Bus quando o valor **muda**. Se o sistema já estava em `prefer-light` e `theme.sh light` era chamado, nenhuma transição ocorria — nenhum sinal era disparado — e os apps não reagiam.

A troca dark → light funcionava quando feita manualmente no terminal porque havia uma transição real de valores.

## Solução

Adicionar um **bounce** no `color-scheme` antes de aplicar o valor final. Isso força o D-Bus a emitir `SettingChanged` independente do estado atual:

```bash
# apply_light: seta dark primeiro, depois light
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
sleep 0.15
gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'

# apply_dark: seta light primeiro, depois dark
gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
sleep 0.15
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
```

O bounce é feito **antes** do `waypaper` para que os apps recebam o sinal imediatamente, sem concorrência com outros processos.

## Outras correções aplicadas

### settings.ini dessincronizado
O `~/.config/gtk-3.0/settings.ini` estava com `gtk-theme-name=Adwaita-dark` enquanto o gsettings tinha `Arc`. Apps GTK leem o arquivo diretamente e ignoram o gsettings. Corrigido sincronizando o `settings.ini` no `theme.sh` via `update_settings_ini()`.

### xdg-desktop-portal-hyprland em loop de falha
O portal entrou em `start-limit-hit` após um `systemctl restart` acidental. O processo original (iniciado pelo Hyprland via `exec-once`) continuava rodando e segurava o nome D-Bus, impedindo o serviço de subir. Resolvido com `systemctl --user reset-failed xdg-desktop-portal-hyprland`.

## Como verificar

```bash
# Confirma que o portal está retornando o valor correto
gdbus call --session \
  --dest=org.freedesktop.portal.Desktop \
  --object-path=/org/freedesktop/portal/desktop \
  --method=org.freedesktop.portal.Settings.Read \
  "org.freedesktop.appearance" "color-scheme"
# 1 = dark, 2 = light

# Monitora sinais D-Bus em tempo real
dbus-monitor --session "type='signal',interface='org.freedesktop.portal.Settings'"
```
