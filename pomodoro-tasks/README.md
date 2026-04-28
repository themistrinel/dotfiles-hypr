# pomodoro-tasks

Minimal Pomodoro task manager — C++ + GTK + WebView, pywal-themed, Waybar-integrated.

## Build

```bash
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

## Run

Run from the project root so `data/tasks.json` and `ui/index.html` resolve correctly:

```bash
cd /path/to/pomodoro-tasks
./build/pomodoro-tasks
```

## Waybar integration

Add `"custom/pomodoro"` to your Waybar config (see `waybar-module.jsonc`).

The module reads `/tmp/pomodoro-waybar.json` every second.  
Clicking it sends `SIGUSR1` to the app (pause/resume — wire in app.cpp if desired).

## pywal

Colors are read from `~/.cache/wal/colors.json` on startup and whenever the file changes (live reload on wallpaper change).

## Data

Tasks are persisted to `data/tasks.json` in the working directory.  
The file is plain JSON and can be edited manually.

## Structure

```
src/
  main.cpp        — entry point
  app.h/cpp       — central app, GTK window, WebView setup
  ipc.h/cpp       — JS→C++ message dispatcher
  timer.h/cpp     — Pomodoro timer (GLib timeout)
  task_store.h/cpp— JSON persistence
  wal_theme.h/cpp — pywal color loader + file watcher
  waybar.h/cpp    — Waybar module writer
  models.h        — Task, AppState structs
ui/
  index.html      — full HTML/CSS/JS frontend
data/
  tasks.json      — persisted tasks (auto-created)
```
