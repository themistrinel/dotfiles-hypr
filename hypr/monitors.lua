--------------------
---- MONITORS ----
--------------------
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

-- Monitor LG UltraGear (primary, top)
hl.monitor({
  output   = "DP-1",
  mode     = "1920x1080@180",
  position = "0x0",
  scale    = 1,
})

-- Monitor Samsung/Generic (HDMI-A-2)
hl.monitor({
  output   = "HDMI-A-2",
  mode     = "1920x1080@100",
  position = "auto",
  scale    = 1,
})

-- Fallback for old HDMI-A-1 identifier
hl.monitor({
  output   = "HDMI-A-1",
  mode     = "1920x1080@100",
  position = "auto",
  scale    = 1,
})
