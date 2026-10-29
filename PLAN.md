# Plan: split into GNOME / PC-keyboard / personal layers

Status: agreed, not started. Waiting for a go-ahead.

## Goal

One repo, three layers, each usable without the ones after it:

1. **gnome** - make macOS behave like GNOME. Useful to anyone.
2. **pc-keyboard** - PC-style modifier layout on the MacBook keyboard and on PC keyboards in Mac mode, plus British PC
   input source. Useful to anyone with that hardware.
3. **personal** - Avi's apps, file associations, webcam, preferences. Kept here rather than in chezmoi so chezmoi doesn't
   grow macOS-only special cases.

`init.sh` runs the layers in order; each layer can be skipped.

## Decisions

- **Super is the key next to Ctrl**: Option on the MacBook, Start on a PC keyboard in Mac mode. It's the key that
  already snaps windows. Every Super binding moves to it (see below).
- **Physical Alt is Cmd** and keeps its Mac meaning, apart from the Alt-ish things GNOME users expect (Alt+Tab,
  Alt+F4, Alt-as-Meta in the terminal).
- **Personal layer stays in this repo.**
- **Tap Super (Option) alone → Activities**, not tap Cmd. That's what GNOME does, and it removes the Cmd+Tab and Tabby
  alt+. collisions at the source, since nothing else uses a lone Option. The Karabiner `to_if_alone` + Hammerspoon veto
  split from 2026-10-27 stays, to cope with Option+click.
- **Karabiner config assembled with jq from per-layer JSON fragments.** jq ships with macOS (`/usr/bin/jq`), so no new
  dependency. Goku was considered: it has no include mechanism, so it would still need a merge step, plus a third-party
  tap with one maintainer. Karabiner's GUI edits get overwritten, so rules are only changed in the fragments.

## What moves where

| Thing | Layer | Mechanism |
|---|---|---|
| Tap Super → Activities | gnome | Karabiner `to_if_alone` → F19, Hammerspoon binds F19 |
| Super+arrows snap, Super+Shift+arrows other display | gnome | Hammerspoon `gnome.lua` |
| Super+L lock, Super+D desktop | gnome | Hammerspoon `gnome.lua` |
| Alt+F4 close, Alt+Tab windows (AltTab) | gnome | Hammerspoon / Brewfile |
| Ctrl+Alt+arrows desktops; macOS tiling shortcuts off | gnome | `defaults` |
| Stage Manager off, click-wallpaper off, expanded save dialogs | gnome | `defaults` |
| Finder Delete → Bin | gnome | Hammerspoon `gnome.lua` |
| Home/End, Ctrl+arrows word-jump | gnome | `DefaultKeyBinding.dict` (needs adding; it's referenced but missing) |
| Notification-list setup | gnome | README manual steps |
| fn ↔ Ctrl on MacBook keyboard | pc-keyboard | Karabiner device rule |
| Right Option → Right Ctrl on PC keyboard | pc-keyboard | Karabiner device rule; vendor/product IDs in the fragment |
| British – PC input source, ANSI virtual keyboard | pc-keyboard | README manual steps |
| Caps Lock ↔ Escape | personal | Karabiner |
| Tabby + Alt-as-Meta rule | personal | Brewfile + Karabiner |
| Bash, GNU tools, chezmoi, login shell | personal | Brewfile + `init.sh --admin` |
| CotEditor, LibreOffice, Thunderbird, duti associations | personal | Brewfile + duti |
| C920 50Hz fix, uvc-util | personal | Hammerspoon `personal.lua` + `init.sh` |
| 70/30 snap widths | personal | overrides the gnome default of halves |

## Layout

```
init.sh                         runs each layer's steps; flags to skip layers
gnome/        Brewfile  defaults.sh  hammerspoon.lua  karabiner.json  DefaultKeyBinding.dict
pc-keyboard/  defaults.sh  karabiner.json
personal/     Brewfile  defaults.sh  hammerspoon.lua  karabiner.json  duti.conf
hammerspoon/init.lua            loads gnome.lua, then personal.lua if present
karabiner/build.sh              merges each layer's karabiner.json into ~/.config/karabiner/karabiner.json
```

Brewfiles replace the arrays in `init.sh`; `brew bundle --file=<layer>/Brewfile` is existing tooling.

## Existing bugs to fix on the way

- `init.sh` links Hammerspoon, `duti.conf` and `fix-defaults` from paths that don't exist; the live machine works only
  because links were made by hand.
- Lock screen and show desktop are on Ctrl+Cmd, not Super.
- Karabiner `automatic_backups/` and `.obsidian/` are tracked.
- README's repo-layout section and keys table are out of date.

## Order of work

Each step a separate commit, tested on this machine before the next:

1. Done: Hammerspoon split into `gnome.lua` / `personal.lua`; Super consistently on Option; tap-Super on Option.
2. Done: Karabiner fragments + jq merge step.
3. Brewfiles and per-layer `defaults.sh`.
4. `init.sh` rewritten around layers; fix the broken paths.
5. README rewritten per layer.
