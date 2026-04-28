#!/bin/bash
# Switch to workspace on current monitor
ws=$1
current_monitor=$(hyprctl activeworkspace -j | jq -r '.monitor')
hyprctl dispatch moveworkspacetomonitor "$ws $current_monitor"
hyprctl dispatch workspace "$ws"
