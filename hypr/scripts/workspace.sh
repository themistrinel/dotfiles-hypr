#!/bin/bash
# Switch to workspace on current monitor (Hyprland 0.55+ Lua syntax)
ws=$1
current_monitor=$(hyprctl activeworkspace -j | jq -r '.monitor')
hyprctl dispatch "hl.dsp.workspace.move({ workspace = $ws, monitor = \"$current_monitor\" })"
hyprctl dispatch "hl.dsp.focus({ workspace = $ws })"
