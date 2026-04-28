#!/usr/bin/env python3
"""Rotate hue of pywal colors and re-export all templates."""

import json, sys, colorsys, subprocess
from pathlib import Path

CACHE = Path.home() / ".cache/wal"
SHIFT = float(sys.argv[1]) if len(sys.argv) > 1 else 120  # degrees (0-360)
LIGHT = "--light" in sys.argv


def shift(color, degrees, sat_boost=1.3):
    h = color.lstrip("#")
    r, g, b = (int(h[i:i+2], 16) / 255 for i in (0, 2, 4))
    hh, l, s = colorsys.rgb_to_hls(r, g, b)
    hh = (hh + degrees / 360) % 1.0
    s = min(s * sat_boost, 1.0)
    r, g, b = colorsys.hls_to_rgb(hh, l, s)
    return "#{:02x}{:02x}{:02x}".format(int(r*255), int(g*255), int(b*255))


colors_file = CACHE / "colors.json"
data = json.loads(colors_file.read_text())

for key in data["colors"]:
    data["colors"][key] = shift(data["colors"][key], SHIFT)

data["special"]["background"] = shift(data["special"]["background"], SHIFT, sat_boost=1.0)
data["special"]["foreground"] = shift(data["special"]["foreground"], SHIFT)
data["special"]["cursor"]     = data["special"]["foreground"]

# Write modified theme to a temp file and apply
tmp = CACHE / "colors-hue-shifted.json"
tmp.write_text(json.dumps(data, indent=4))

cmd = ["wal", "--theme", str(tmp), "-n", "-t", "-e"]
if LIGHT:
    cmd.append("-l")
subprocess.run(cmd)
