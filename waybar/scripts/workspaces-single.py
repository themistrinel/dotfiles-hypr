#!/usr/bin/env python3
"""
Waybar custom workspace module — um por workspace.
Uso: workspaces-single.py <id>
"""
import json
import os
import socket
import sys
import signal

HYPRLAND_SIG = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
SOCKET_PATH = f"/run/user/{os.getuid()}/hypr/{HYPRLAND_SIG}/.socket.sock"
SOCKET2_PATH = f"/run/user/{os.getuid()}/hypr/{HYPRLAND_SIG}/.socket2.sock"

ws_id = int(sys.argv[1]) if len(sys.argv) > 1 else 1


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


def emit():
    workspaces, active = get_state()
    if ws_id == active:
        css = "active"
    elif ws_id in workspaces:
        css = "occupied"
    else:
        css = "empty"
    print(json.dumps({"text": str(ws_id), "class": css, "tooltip": f"Workspace {ws_id}"}), flush=True)


def listen():
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
