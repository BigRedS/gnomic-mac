-- ~/.hammerspoon/init.lua
--
-- Loads each layer that init.sh linked into ~/.hammerspoon: gnome.lua always,
-- personal.lua if present. Layers are plain modules with a start() function;
-- settings are passed in explicitly so a later layer can override them.

local function present(name)
  return hs.fs.attributes(hs.configdir .. "/" .. name .. ".lua") ~= nil
end

-- GNOME snaps windows to halves. A later layer can override these.
local settings = {
  snapLeft = hs.layout.left50,
  snapRight = hs.layout.right50,
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
