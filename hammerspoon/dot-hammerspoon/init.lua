-- ~/.hammerspoon/init.lua
-- GNOME-ish behaviour for macOS.
--
-- "Super" for window keys is Ctrl+Cmd rather than Cmd alone, because
-- Cmd+Left/Right are start/end-of-line in every Mac text field and
-- stealing them gets old fast. Change SUPER below if you disagree.

local SUPER = { "ctrl", "cmd" }
local SNAP = { "alt" }

hs.window.animationDuration = 0

---------------------------------------------------------------------------
-- 1. Tap Cmd on its own -> Activities (Mission Control)
--    Holding Cmd, or using it with any key or click, does nothing extra.
---------------------------------------------------------------------------
local LEFT_CMD = 55
local TAP_MAX_SECONDS = 0.35

local cmdDownAt = nil
local types = hs.eventtap.event.types

-- Kept global so it isn't garbage-collected and silently stop working.
superTapWatcher = hs.eventtap.new({
  types.flagsChanged, types.keyDown,
  types.leftMouseDown, types.rightMouseDown, types.otherMouseDown,
  types.scrollWheel,
}, function(e)
  local t = e:getType()
  if t ~= types.flagsChanged then
    cmdDownAt = nil -- Cmd was used as a modifier
    return false
  end

  local f = e:getFlags()
  if e:getKeyCode() == LEFT_CMD then
    if f.cmd and not (f.alt or f.ctrl or f.shift or f.fn) then
      cmdDownAt = hs.timer.secondsSinceEpoch()
    elseif not f.cmd and cmdDownAt then
      local held = hs.timer.secondsSinceEpoch() - cmdDownAt
      cmdDownAt = nil
      if held < TAP_MAX_SECONDS then
        hs.spaces.toggleMissionControl()
        -- Swap for this if you'd rather Super open Raycast/Alfred:
        -- hs.eventtap.keyStroke({ "cmd" }, "space")
      end
    end
  else
    cmdDownAt = nil
  end
  return false
end)
superTapWatcher:start()

---------------------------------------------------------------------------
-- 2. Window snapping, GNOME-style
--    Super+Left/Right  half screen
--    Super+Up          maximise
--    Super+Down        restore previous size (or un-maximise)
--    Super+Shift+Left/Right  throw window to the next display
---------------------------------------------------------------------------
local savedFrames = {}

local function withWindow(fn)
  return function()
    local w = hs.window.focusedWindow()
    if w then fn(w) end
  end
end

local function remember(w)
  if not savedFrames[w:id()] then
    savedFrames[w:id()] = w:frame()
  end
end

hs.hotkey.bind(SNAP, "left", withWindow(function(w)
  remember(w); w:moveToUnit(hs.layout.left70)
end))

hs.hotkey.bind(SNAP, "right", withWindow(function(w)
  remember(w); w:moveToUnit(hs.layout.right30)
end))

hs.hotkey.bind(SNAP, "up", withWindow(function(w)
  remember(w); w:maximize()
end))

hs.hotkey.bind(SNAP, "down", withWindow(function(w)
  local f = savedFrames[w:id()]
  if f then
    w:setFrame(f)
    savedFrames[w:id()] = nil
  else
    -- Nothing saved: shrink to a centred 60% window, like GNOME's unmaximise.
    w:moveToUnit({ 0.2, 0.15, 0.6, 0.7 })
  end
end))

hs.hotkey.bind({ "ctrl", "cmd", "shift" }, "left", withWindow(function(w)
  w:moveOneScreenWest(false, true)
end))

hs.hotkey.bind({ "ctrl", "cmd", "shift" }, "right", withWindow(function(w)
  w:moveOneScreenEast(false, true)
end))

-- Forget saved sizes for windows that close.
savedFrameCleaner = hs.window.filter.new():subscribe(
  hs.window.filter.windowDestroyed,
  function(w) if w then savedFrames[w:id()] = nil end end
)

---------------------------------------------------------------------------
-- 3. Odds and ends
---------------------------------------------------------------------------
-- Super+L: lock screen
hs.hotkey.bind(SUPER, "l", function() hs.caffeinate.lockScreen() end)

-- Alt+F4: close the focused window (Fn+Alt+F4 on a MacBook keyboard)
hs.hotkey.bind({ "alt" }, "f4", withWindow(function(w) w:close() end))

-- Super+D: show desktop
hs.hotkey.bind(SUPER, "d", function() hs.spaces.toggleShowDesktop() end)

---------------------------------------------------------------------------
-- Reload automatically when this file changes.
---------------------------------------------------------------------------
configWatcher = hs.pathwatcher.new(hs.configdir, function(files)
  for _, f in ipairs(files) do
    if f:sub(-4) == ".lua" then
      hs.reload()
      return
    end
  end
end):start()

---------------------------------------------------------------------------
-- Finder: PC Delete key -> Move to Bin (except while renaming)
---------------------------------------------------------------------------
local FORWARD_DELETE = 117

finderDeleteTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(e)
  if e:getKeyCode() ~= FORWARD_DELETE then return false end
  local f = e:getFlags()
  if f.cmd or f.alt or f.ctrl or f.shift then return false end

  local app = hs.application.frontmostApplication()
  if not app or app:bundleID() ~= "com.apple.finder" then return false end

  local focused = hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
  local role = focused and focused:attributeValue("AXRole")
  if role == "AXTextField" or role == "AXTextArea" then return false end

  hs.eventtap.keyStroke({ "cmd" }, "delete", 0)
  return true
end)
finderDeleteTap:start()

hs.alert.show("Hammerspoon config loaded")
