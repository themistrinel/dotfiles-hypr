#!/usr/bin/env python3
"""
Waybar custom workspaces module para Hyprland com Lua dispatcher.
Emite JSON com os workspaces ativos, atualizando via socket IPC.
"""
import json
import os
import socket
import subprocess
import sys
import threading

HYPRLAND_SIG = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
SOCKET_PATH = f"/run/user/{os.getuid()}/hypr/{HYPRLAND_SIG}/.socket.sock"
SOCKET2_PATH = f"/run/user/{os.getuid()}/hypr/{HYPRLAND_SIG}/.socket2.sock"

NAMES = {1: "一", 2: "二", 3: "三", 4: "四", 5: "五", 6: "六", 7: "七", 8: "八", 9: "九", 10: "十"}
TOTAL = 5  # número de workspaces persistentes


def hyprctl(cmd):
    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.connect(SOCKET_PATH)
        s.sendall(cmd.encode())
        data = b""
        while True:
            chunk = s.recv(4096)
            if not chunk:
                break
            data += chunk
        s.close()
        return data.decode()
    except Exception:
        return ""


def get_state():
    raw = hyprctl("j/workspaces")
    try:
        workspaces = {w["id"] for w in json.loads(raw)}
    except Exception:
        workspaces = set()

    raw2 = hyprctl("j/activeworkspace")
    try:
        active = json.loads(raw2)["id"]
    except Exception:
        active = -1

    return workspaces, active


def render(workspaces, active):
    parts = []
    for i in range(1, TOTAL + 1):
        name = NAMES.get(i, str(i))
        if i == active:
            parts.append(f'<span color="#0D1113"><b>{name}</b></span>')
        elif i in workspaces:
            parts.append(f'<span color="#4cb2d2">{name}</span>')
        else:
            parts.append(f'<span color="#737b7f">{name}</span>')
    return "  ".join(parts)


def emit():
    workspaces, active = get_state()
    text = render(workspaces, active)
    tooltip = f"Workspace ativa: {active}"
    print(json.dumps({"text": text, "tooltip": tooltip}), flush=True)


def listen():
    """Ouve o socket2 do Hyprland e emite sempre que workspace mudar."""
    while True:
        try:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.connect(SOCKET2_PATH)
            buf = b""
            while True:
                chunk = s.recv(4096)
                if not chunk:
                    break
                buf += chunk
                while b"\n" in buf:
                    line, buf = buf.split(b"\n", 1)
                    event = line.decode().strip()
                    if any(e in event for e in ("workspace>>", "focusedmon>>", "openwindow>>", "closewindow>>", "movewindow>>")):
                        emit()
        except Exception:
            import time
            time.sleep(1)


emit()
listen()
