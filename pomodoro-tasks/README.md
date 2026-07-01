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

## Concurso Queue

Fila circular de matérias para estudo de concurso. A fila só avança quando a tarefa correta for concluída — nunca por tarefas antigas ou fora de ordem.

### Como usar

1. Clique em **📋** na barra de tarefas para abrir o painel
2. A fila já vem pré-configurada com 21 matérias — edite se necessário e clique **Salvar fila**
3. Clique em **📚** (ou **+ Nova tarefa** no painel) para criar a tarefa da matéria atual
4. Conclua a tarefa normalmente (timer, ✓ ou ⏹) → a fila avança automaticamente
5. Na próxima sessão, **📚** já aponta para a próxima matéria

### Painel

| Elemento | Descrição |
|---|---|
| Barra de progresso | Posição atual na fila (ex: `5 / 21`) |
| **AGORA** | Matéria que será criada no próximo clique |
| **PRÓXIMA** | Preview da matéria seguinte |
| `+ Nova tarefa` | Cria a tarefa (desabilitado se já há uma ativa) |
| `⏭ Pular` | Avança a fila sem concluir a tarefa atual |
| `↺ Reset` | Volta ao início da fila |

### Indicadores visuais nas tarefas

- 🎯 — tarefa controladora da fila (a que precisa ser concluída para avançar)
- ⚠ — tarefa de concurso fora do fluxo (não avança a fila ao ser concluída)

### Estado persistido (`tasks.json`)

```json
"concurso_queue": ["Português", "Informática", ...],
"concurso_index": 2,
"last_concurso_task_id": "18a91c9620574ac9"
```

A fila só avança quando `task.id == last_concurso_task_id && task.tag == "concurso" && task.done == true`.
