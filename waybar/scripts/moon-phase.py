#!/usr/bin/env python3
import json
import ephem

# Bragança Paulista, SP
obs = ephem.Observer()
obs.lat = '-22.9538'
obs.lon = '-46.5425'

moon = ephem.Moon(obs)
phase = moon.phase  # 0-100 (iluminação %)

# Determina fase pelo ciclo lunar
prev_new = ephem.previous_new_moon(obs.date)
next_new = ephem.next_new_moon(obs.date)
cycle = float(next_new - prev_new)
age = float(obs.date - prev_new) / cycle  # 0.0 a 1.0

if age < 0.0625:   icon, name = "🌑", "Lua Nova"
elif age < 0.1875: icon, name = "🌒", "Lua Crescente"
elif age < 0.3125: icon, name = "🌓", "Quarto Crescente"
elif age < 0.4375: icon, name = "🌔", "Crescente Gibosa"
elif age < 0.5625: icon, name = "🌕", "Lua Cheia"
elif age < 0.6875: icon, name = "🌖", "Minguante Gibosa"
elif age < 0.8125: icon, name = "🌗", "Quarto Minguante"
elif age < 0.9375: icon, name = "🌘", "Minguante"
else:              icon, name = "🌑", "Lua Nova"

print(json.dumps({
    "text": icon,
    "tooltip": f"{name} ({phase:.0f}% iluminada)"
}, ensure_ascii=False))
