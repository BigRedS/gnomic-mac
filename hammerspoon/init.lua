-- ~/.hammerspoon/init.lua
--
-- Loads each layer that init.sh linked into ~/.hammerspoon: gnome.lua always,
-- personal.lua if present. Layers are plain modules with a start() function;
-- settings are passed in explicitly so a later layer can override them.

local function present(name)
  return hs.fs.attributes(hs.configdir .. "/" .. name .. ".lua") ~= nil
end

-- Defaults for the GNOME layer. A later layer can override these.
local settings = {
  -- GNOME snaps windows to halves.
  snapLeft = hs.layout.left50,
  snapRight = hs.layout.right50,
  -- What tapping Super alone does. GNOME's Activities is two things at once,
  -- a window overview and a search box, and macOS splits them:
  --   "search"   Spotlight (Cmd+Space); the overview is on the top-left hot
  --              corner, as in GNOME (set in gnome/defaults.sh)
  --   "overview" Mission Control
  superTap = "search",
  -- What happens when a window asks for macOS's native full screen (green
  -- button, Ctrl+Cmd+F, an app's own menu):
  --   "native"   leave it alone: the window gets its own desktop, and with
  --              one desktop spanning all displays the others go blank
  --   "maximise" undo it straight away and maximise instead, as GNOME's
  --              full screen stays on the current desktop. Video players
  --              then can't go truly full screen either.
  fullscreen = "native",
  -- Must match the screenshot location in gnome/defaults.sh.
  screenshotDir = os.getenv("HOME") .. "/Pictures/Screenshots",
}

local personal = present("personal") and require("personal") or nil
if personal and personal.settings then
  for k, v in pairs(personal.settings) do settings[k] = v end
end

require("gnome").start(settings)
if personal then personal.start() end

---------------------------------------------------------------------------
-- Reload when any layer's file changes. The files in ~/.hammerspoon are
-- symlinks into the repo, and editing the repo copy doesn't touch the
-- symlink, so watch the directories the symlinks point into.
---------------------------------------------------------------------------
local function reloadOnLua(files)
  for _, f in ipairs(files) do
    if f:sub(-4) == ".lua" then hs.reload(); return end
  end
end

configWatchers = {}
local watched = {}
for _, name in ipairs({ "init", "gnome", "personal" }) do
  local real = hs.fs.pathToAbsolute(hs.configdir .. "/" .. name .. ".lua")
  local dir = real and real:match("^(.*)/[^/]+$")
  if dir and not watched[dir] then
    watched[dir] = true
    table.insert(configWatchers, hs.pathwatcher.new(dir, reloadOnLua):start())
  end
end

hs.alert.show("Hammerspoon config loaded")
