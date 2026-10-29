-- GNOME layer for Hammerspoon: window keys and Activities, GNOME-style.
--
-- Super is the Option key: the key next to Ctrl, which is where Super/Start
-- sits on a PC keyboard (and what Start sends on a PC keyboard in Mac mode).
-- Hammerspoon calls Option "alt". Physical Alt is Cmd and keeps its Mac
-- meaning, apart from Alt+F4 below.

local M = {}

local SUPER = { "alt" }
local SUPER_SHIFT = { "alt", "shift" }
local ALT = { "cmd" }

local LEFT_OPTION = 58
local FORWARD_DELETE = 117
local types = hs.eventtap.event.types

local function withWindow(fn)
  return function()
    local w = hs.window.focusedWindow()
    if w then fn(w) end
  end
end

-- settings: see hammerspoon/init.lua for what each one means.
function M.start(settings)
  hs.window.animationDuration = 0

  ---------------------------------------------------------------------------
  -- Tap Super on its own -> search or overview (settings.superTap)
  --
  -- The tap is detected by Karabiner (to_if_alone on left Option -> F19), not
  -- here: an eventtap can't see everything that should cancel a tap (AltTab
  -- eats Cmd+Tab before it), and does see Karabiner's own synthetic modifier
  -- releases, so it gets fooled both ways. Karabiner can't see the trackpad,
  -- so this side vetoes the tap if the mouse was used while Super was held.
  ---------------------------------------------------------------------------
  local superUsedWithMouse = false

  M.superMouseWatcher = hs.eventtap.new({
    types.flagsChanged,
    types.leftMouseDown, types.rightMouseDown, types.otherMouseDown,
    types.scrollWheel,
  }, function(e)
    if e:getType() == types.flagsChanged then
      -- Fresh Super press: forget a click from a previous hold that never
      -- produced an F19 (e.g. Super+click, then Super+Left before letting go).
      if e:getKeyCode() == LEFT_OPTION and e:getFlags().alt then superUsedWithMouse = false end
    elseif e:getFlags().alt then
      superUsedWithMouse = true
    end
    return false
  end):start()

  hs.hotkey.bind({}, "f19", function()
    local used = superUsedWithMouse
    superUsedWithMouse = false
    if used then return end
    if settings.superTap == "overview" then
      hs.spaces.toggleMissionControl()
    else
      hs.eventtap.keyStroke({ "cmd" }, "space", 0)
    end
  end)

  ---------------------------------------------------------------------------
  -- Window snapping
  --   Super+Left/Right        snap to a side
  --   Super+Up                maximise
  --   Super+Down              restore previous size (or un-maximise)
  --   Super+Shift+Left/Right  move window to the next display
  ---------------------------------------------------------------------------
  local savedFrames = {}

  local function remember(w)
    if not savedFrames[w:id()] then savedFrames[w:id()] = w:frame() end
  end

  hs.hotkey.bind(SUPER, "left", withWindow(function(w)
    remember(w); w:moveToUnit(settings.snapLeft)
  end))

  hs.hotkey.bind(SUPER, "right", withWindow(function(w)
    remember(w); w:moveToUnit(settings.snapRight)
  end))

  hs.hotkey.bind(SUPER, "up", withWindow(function(w)
    remember(w); w:maximize()
  end))

  hs.hotkey.bind(SUPER, "down", withWindow(function(w)
    local f = savedFrames[w:id()]
    if f then
      w:setFrame(f)
      savedFrames[w:id()] = nil
    else
      -- Nothing saved: shrink to a centred 60% window, like GNOME's unmaximise.
      w:moveToUnit({ 0.2, 0.15, 0.6, 0.7 })
    end
  end))

  -- GNOME's Super+H hides the window; minimise is the Mac equivalent.
  hs.hotkey.bind(SUPER, "h", withWindow(function(w) w:minimize() end))

  hs.hotkey.bind(SUPER_SHIFT, "left", withWindow(function(w)
    w:moveOneScreenWest(false, true)
  end))

  hs.hotkey.bind(SUPER_SHIFT, "right", withWindow(function(w)
    w:moveOneScreenEast(false, true)
  end))

  -- Forget saved sizes for windows that close.
  M.savedFrameCleaner = hs.window.filter.new():subscribe(
    hs.window.filter.windowDestroyed,
    function(w) if w then savedFrames[w:id()] = nil end end
  )

  ---------------------------------------------------------------------------
  -- Super+PgUp/PgDn -> previous/next desktop, alongside Ctrl+Alt+arrows.
  -- macOS allows one shortcut per action, so these re-send the Ctrl+Cmd+arrow
  -- shortcut set in gnome/defaults.sh. The fn flag is required: macOS stores
  -- arrow-key shortcuts with it, and without it the synthetic key is ignored
  -- (tested 2026-10-29).
  ---------------------------------------------------------------------------
  local function switchDesktop(arrow)
    return function()
      for _, down in ipairs({ true, false }) do
        local e = hs.eventtap.event.newKeyEvent(arrow, down)
        e:setFlags({ ctrl = true, cmd = true, fn = true })
        e:post()
      end
    end
  end
  hs.hotkey.bind(SUPER, "pageup", switchDesktop("left"))
  hs.hotkey.bind(SUPER, "pagedown", switchDesktop("right"))

  ---------------------------------------------------------------------------
  -- Screenshots go to a file and the clipboard, as in GNOME. macOS only does
  -- one or the other, so it saves the file and this copies each new one.
  -- macOS writes a hidden temporary file and renames it, so skip dotfiles,
  -- and remember what's been copied since one screenshot fires several events.
  ---------------------------------------------------------------------------
  local copiedScreenshots = {}
  -- Hammerspoon can start before init.sh has run defaults.sh on a fresh Mac.
  if not hs.fs.attributes(settings.screenshotDir) then hs.fs.mkdir(settings.screenshotDir) end
  M.screenshotWatcher = hs.pathwatcher.new(settings.screenshotDir, function(paths)
    for _, path in ipairs(paths) do
      local name = path:match("[^/]+$") or ""
      if not name:match("^%.") and name:lower():match("%.png$")
         and not copiedScreenshots[path] and hs.fs.attributes(path) then
        local image = hs.image.imageFromPath(path)
        if image then
          copiedScreenshots[path] = true
          hs.pasteboard.writeObjects(image)
        end
      end
    end
  end):start()

  ---------------------------------------------------------------------------
  -- Native full screen -> maximise (settings.fullscreen = "maximise").
  -- macOS has no setting to turn native full screen off, so catch windows as
  -- they enter it, take them back out, and maximise once the exit animation
  -- has finished (maximising mid-animation is ignored).
  ---------------------------------------------------------------------------
  if settings.fullscreen == "maximise" then
    M.pendingMaximise = {}
    M.fullscreenFilter = hs.window.filter.new():subscribe(
      hs.window.filter.windowFullscreened,
      function(w)
        if not w then return end
        w:setFullScreen(false)
        M.pendingMaximise[w:id()] = hs.timer.doAfter(1, function()
          M.pendingMaximise[w:id()] = nil
          w:maximize()
        end)
      end
    )
  end

  ---------------------------------------------------------------------------
  -- Odds and ends
  ---------------------------------------------------------------------------
  hs.hotkey.bind(SUPER, "l", function() hs.caffeinate.lockScreen() end)
  hs.hotkey.bind(SUPER, "d", function() hs.spaces.toggleShowDesktop() end)
  -- Fn+Alt+F4 on a MacBook keyboard.
  hs.hotkey.bind(ALT, "f4", withWindow(function(w) w:close() end))

  ---------------------------------------------------------------------------
  -- Finder: Delete key -> Move to Bin (except while renaming)
  ---------------------------------------------------------------------------
  M.finderDeleteTap = hs.eventtap.new({ types.keyDown }, function(e)
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
  end):start()
end

return M
