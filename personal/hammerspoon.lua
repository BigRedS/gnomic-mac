-- Personal layer for Hammerspoon: Avi's preferences and hardware.

local M = {}

-- Overrides for the GNOME layer's defaults. External displays get a wide left
-- window and a narrow right one.
M.settings = {
  splitExternal = 0.7,
  fullscreen = "maximise",
  -- The drop-down terminal is never tiled, and Super+arrow there is usually
  -- a missed Ctrl+arrow.
  noSnapApps = { "com.googlecode.iterm2" },
}

---------------------------------------------------------------------------
-- Webcam: force 50Hz anti-flicker on the C920 whenever it's connected.
-- UK mains lighting flickers at 50Hz; the C920 defaults to 60Hz and forgets
-- the setting every time it's unplugged.
---------------------------------------------------------------------------
local UVC = os.getenv("HOME") .. "/bin/uvc-util"   -- built by init.sh
local WEBCAMS = {
  { vendor = 0x046d, product = 0x082d },   -- Logitech HD Pro Webcam C920
}

local function setAntiFlicker(v, p)
  local id = string.format("0x%04x:0x%04x", v, p)
  local out, ok = hs.execute(UVC .. " -V " .. id .. " -s power-line-frequency=1 2>&1")
  if not ok then print("uvc-util failed for " .. id .. ": " .. out) end
end

function M.start()
  M.webcamWatcher = hs.usb.watcher.new(function(ev)
    if ev.eventType ~= "added" then return end
    for _, cam in ipairs(WEBCAMS) do
      if ev.vendorID == cam.vendor and ev.productID == cam.product then
        hs.timer.doAfter(3, function() setAntiFlicker(cam.vendor, cam.product) end)
      end
    end
  end):start()

  -- Also apply at start, in case the camera is already plugged in.
  for _, cam in ipairs(WEBCAMS) do setAntiFlicker(cam.vendor, cam.product) end
end

return M
