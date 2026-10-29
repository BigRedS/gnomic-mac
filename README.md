# mac-setup

Trying to mac a mac compatible with some Debian/Gnome-learned muscle-memory

Mostly:
* Keybindings a bit like Gnome's GB keyboard layout
* Sensible file-associations
* Remove camera flicker on UK 50Hz power supplies

Doesn't make it look like gnome or feel like gnome, just makes the interactions a little less surprising.

This is documentation as much as it is automation; partly to remind me what I like.

Dotfiles and whatnot are in chezmoi, which has a specific ~/.bashrc_macos file for macos shell config


---

## Repo layout

```
init.sh                      bootstrap: Homebrew + apps, symlinks, uvc-util, settings — safe to re-run
macos-defaults.sh            the scriptable System Settings (section 1 = in use, section 2 = candidates)
fix-defaults                 re-applies duti.conf, only for file types that have drifted
duti.conf                    which app opens which file type       → ~/.duti
hammerspoon/init.lua         window keys, Finder Delete, watchers  → ~/.hammerspoon/init.lua
karabiner/                   all keyboard remapping                → ~/.config/karabiner (whole directory)
  karabiner.json
  assets/complex_modifications/tabby-meta.json
keybindings/DefaultKeyBinding.dict   Home/End + Ctrl+arrows        → copied to ~/Library/KeyBindings/
```

Add `karabiner/automatic_backups/` to `.gitignore` — Karabiner writes backups there.

---

## Setup

This needs several permissions that're _normally_ available on corporate macbooks at tech firms:

* Admin rights for Homebrew, `/etc/shells`, and approving system extensions
* Hammerspoon: Accessibility and Input Monitoring permissions
* Karabiner-Elements: its driver extension (DriverKit) and Input Monitoring

Hammerspoon and Karabiner are pretty hard requirements here. Without those, it's probably easier to go the VM route.

### 1. Get the repo and run the script

Do this _before_ chezmoi, since this is how we get a Bash that's newer than the millenium dome, and work in that rather than zsh.

Use xcode to get git and other dependencies

```sh
xcode-select --install
git clone git@github.com:BigRedS/macbook-config ~/src/mac-setup
cd ~/src/mac-setup
./init.sh
./init.sh --admin
```

Chezmoi will now be installed, so add the key to Github and set that up.

### 2. Permissions prompts

There's a lot of clicking about to get the right permissions. `init.sh` will try to launch each app to get the permissions prompts, but just in case here's the hopefully-complete list of requirements.

**Privacy & Security**

* *Privacy & Security -> Accessibility*: Allow Hammerspoon for keyboard-shortcuts to move windows
* *Privacy & Security -> Input Monitoring*: Allow Hammerspoon for 'tap-cmd' to act like tapping the windows key in gnome
* *Privacy & Security → Input Monitoring*: allow `karabiner_grabber` and `karabiner_observer`
   (might be listed as `Karabiner-Core-Service`) for keyboard overrides
* *Accessibility -> Screen Recording* Allow AltTab for alt-tab to work

**Login Items & Extensions**

* *General -> Login Items & Extensions  -> Driver Extensions*: enable `Karabiner-DriverKit-VirtualHIDDevice`
* *General -> Login Items & Extensions -> Login Items*: allow Karabiner's background items.

Check Karabiner-Elements Settings -> Log shows no driver errors, and `Karabiner-EventViewer` logs key presses.

Karabiner silently does nothing until all four are done so check the EventViewer and its startup logs if it doesn't work.
**Mic and Camera**

Might as well do these _before_ trying to join a meeting! Firefox, Teams, Zoom, Granola

If Karabiner was already running before `init.sh` linked `~/.config/karabiner`, quit and reopen it.

Hammerspoon should start at login: tick *Launch Hammerspoon at login* in its preferences (or have `hs.autoLaunch(true)` in
`init.lua`). Karabiner and AltTab add themselves.

### 3. Keyboard

1. *System Settings -> Keyboard -> Text Input -> Edit*

   Add `British – PC`, remove every other source, and untick *Automatically switch to a document's input source*. Leave the keyboard itself in mac-mode (Fn+O on logitech).

2. *System Settings → Keyboard → Keyboard Shortcuts → Modifier Keys*

   Reset to defaults, even the caps-lock-escape-swap; doing anything here confuses Karabiner

4. Check Karabiner's remaps

   These come from `karabiner/karabiner.json` so should be in-place as soon as karabiner is running

   | Device | From | To | Why |
   |---|---|---|---|
   | All keyboards | Caps Lock | Escape | Habit. |
   | MacBook keyboard | fn/Globe | Left Control | Puts Ctrl bottom-left, where a PC has it. |
   | MacBook keyboard | Left Control | fn/Globe | …and keeps fn reachable (fn+arrows = Home/End/PgUp/PgDn). |
   | Logitech | Right Option | Right Control | In Mac mode the right-hand Ctrl position sends Option. macOS's own settings can't tell left from right, so only Karabiner can fix this without breaking the Start key. |

4. Karabiner's keymap

   *Virtual Keyboard → keyboard type: ANSI*: for some reason this is actually right, not ISO. Who knows why.

5. Karabiner's complex rules

   These are in `karabiner.json` already, but if they're missing: *Karabiner → Complex Modifications → Add predefined rule* and choose from `~/.config/karabiner/assets/complex_modifications/`:

   * `karabiner-tabby-meta.json` — alt-as-meta for Tabby (alt+. etc.)
   * `karabiner-cmd-tap.json` — tap Cmd alone → F19, which Hammerspoon turns into Mission Control

### 4. Windows, Spaces, Desktops etc.

Most of this is scripted (`macos-defaults.sh` and `hammerspoon/init.lua`). Manual bits:

2. *Check System Settings → Desktop & Dock → Windows*:
   * *Drag windows to screen edges to tile* **on**
   * *Drag windows to menu bar to fill screen* **on**
   * *Tiled windows have margins* **off**.

These are _hopefully_ scripted but check!

3. AltTab settings:
  * shortcut on **Cmd+Tab**
  * *Appearance → Apparition delay* **0**.


### 6. Notifications

Trying to turn down notification hell. This is all manual and best done once everything is installed, or redone periodically:

- Most apps: alert style *None*, but keep *Show in Notification Centre* and *Badge application icon*. Nothing pops up - everything waits in the list behind the clock, like gnome.
- **Alerts** (stay until dismissed) only for things that must interrupt: Zoom/Granola/Teams calls, calendar reminders.
- **Teams** has its own notification settings too — trim them or you get duplicates

### 7. Tabby

- Set alt+space as drop-down trigger
- Set 'use option as meta key' perhaps?


### 8. Finish

Log out and back in (keyboard shortcuts and key bindings fully apply after a fresh login), then run through
[Checks](#checks).


## Background Notes


### Duti: Default apps

Finder's 'Change All...' is forever being overidden by apps - so I use `duti`.

`init.sh` runs `fix-defaults`, which points file types at the apps in `duti.conf`

It is _really_ prompt happy, every change requires a confirmation, so `fix-defaults` tests for differences
to the yaml and only applies changes

### Tabby: Quake-style drop-down terminal

I don't (yet) remember how far off default I am

I use ctrl-space to show/hide the window here, macos-defaults.sh unsets ctrl-space as the macos default
of input-switcher.

Careful handing is needed in macos to get alt working properly in shells; Karabiner has a `tabby-meta.json` that works around the fact that the Logitec's Alt key sends Cmd. It replaces a physical Alt+\<key\> with
Escape-then-\<key\> specifically in windows whose app ID matches the rule; `osascript -e 'id of app "Tabby"'` should print `org.tabby`.

### Bash

Macos' shell is a late-2000s BSD tribute act. init.sh adds Homebrew's bash to /etc/shells and runs `chsh` to
set it as the default.

You can't just replace the BSD Coreutils with GNU ones because some tooling detects it's on a mac and expects
BSD interfaces; GNU tools are installed under their `g*` names (`gsed`, `gdate`, `gfind`…) and aliased in `~/.bashrc_macos`.

### 8. Webcam flicker (50Hz)

UK mains lighting makes webcams flicker unless they're set to 50Hz; the C920 defaults to 60Hz and forgets the setting every
time the dock is unplugged.

`init.sh` clones [uvc-util](https://github.com/jtfrey/uvc-util) into `~/opt/uvc-util`, builds it, and links
`~/bin/uvc-util`; it isn't in Homebrew.

Query the current setting with

```
uvc-util -V <vendor>:<product> -S power-line-frequency
```

and set it with a lower-case `-s` (1 = 50Hz, 2 = 60Hz):

```
uvc-util -V <vendor>:<product> -s power-line-frequency=1
```

## Keys at a glance

On the Logitech in Mac mode: **Start = Option, Alt = Cmd**. On the MacBook, the keys are as labelled (with fn/Ctrl swapped).

| Physical keys (Logitech) | Does | Provided by |
|---|---|---|
| Tap **left Alt** on its own | Mission Control (Activities) | Hammerspoon |
| **Start + ← / →** | Window to left / right half | Hammerspoon |
| **Start + ↑ / ↓** | Maximise / restore | Hammerspoon |
| **Ctrl + Alt + ← / →** | Previous / next desktop | macOS shortcut (scripted) |
| **Ctrl + Alt + ↑** | Mission Control | macOS shortcut (scripted) |
| **Ctrl + Alt + ↓** | This app's windows | macOS shortcut (scripted) |
| **Ctrl + Alt + Shift + ← / →** | Window to other display | Hammerspoon |
| **Ctrl + Alt + L** | Lock screen | Hammerspoon |
| **Ctrl + Alt + D** | Show desktop | Hammerspoon |
| **Alt + Tab** | Switch windows | AltTab |
| **Ctrl + Space** | Drop-down terminal | Tabby |
| **Alt + .** (in Tabby) | Last argument | Karabiner rule |
| **Caps Lock** | Escape | Karabiner |
| **Home / End** | Start / end of line | DefaultKeyBinding.dict |
| **Ctrl + ← / →** | Previous / next word | DefaultKeyBinding.dict |
| **Delete** (in Finder) | Move to Bin | Hammerspoon |
| Drag window to screen edge / top | Half screen / fill | macOS tiling |

`DefaultKeyBinding.dict` only affects native Mac apps. Electron apps (Teams, Slack, Cursor, Tabby) ignore it.

---

## Why some things are the way they are

- **macOS's own tiling *shortcuts* are switched off** (drag-to-snap stays on). Arrow keys carry a hidden "fn" flag, so
  macOS's Globe+Ctrl+arrow tiling shortcuts also fired on plain Ctrl+arrows from external keyboards, moving windows when I
  wanted to move by word. `macos-defaults.sh` disables those 18 shortcuts.
- **Desktop switching is on Ctrl+Alt+arrows, not Ctrl+arrows** (the macOS default). That frees Ctrl+arrows for word
  movement, as on Linux.
- **Window snapping is on Start+arrows, not Cmd+arrows.** Start is where Super is on the PC keyboard; Cmd+arrows keep their
  normal Mac meaning (start/end of line in text fields).
- **Tap-Cmd-for-Activities is split across Karabiner and Hammerspoon.** Karabiner spots the lone tap (`to_if_alone` → F19)
  because it sits under everything: it sees the Tab in Cmd+Tab, which AltTab eats before Hammerspoon's eventtap gets it, and
  it knows its own fake Cmd release (emitted when rewriting Cmd+. for Tabby) isn't a real one. Hammerspoon binds F19 and only
  vetoes it if the mouse was used while Cmd was held, because Karabiner can't see the trackpad. Doing it all in one layer
  gives either phantom Mission Controls on alt-tab / alt+. or on Cmd+click.
- **Karabiner's directory is symlinked, not the file.** Karabiner saves by replacing `karabiner.json`, which would turn a
  symlinked file back into a plain file.
- **`DefaultKeyBinding.dict` is copied, not symlinked**, because some sandboxed apps won't follow a symlink there.
- **The keyboard shortcut values in `macos-defaults.sh` were captured, not guessed:** set it once in System Settings, then
  `defaults read` before and after and `diff`. Same technique for anything else worth scripting (below).

---

## Checks

- **Hammerspoon console** (menu-bar icon → Console):
  `print(superTapWatcher:isEnabled(), hs.eventtap.isSecureInputEnabled(), hs.accessibilityState())` → `true false true`.
  - First `false` → permissions; quit and relaunch Hammerspoon.
  - Second `true` → something is holding Secure Input (password field, a terminal's "Secure Keyboard Entry", 1Password).
- **"RegisterEventHotKey failed: -9878"** in the console → another app or a macOS shortcut already owns that key. Free it,
  then **Reload Config** (Hammerspoon only claims keys at load time).
- **Karabiner-EventViewer** shows what each physical key really sends — the first thing to check when a remap misbehaves.
  Simple modifications apply before complex rules.
- **A keyboard shortcut's stored value:**
  `plutil -extract AppleSymbolicHotKeys.79 xml1 -o - ~/Library/Preferences/com.apple.symbolichotkeys.plist`
- **Which app owns a file type:** `duti -x yaml`.

## Scripting another setting

1. `defaults read > /tmp/before.txt`
2. Change the setting in System Settings.
3. `defaults read > /tmp/after.txt && diff /tmp/before.txt /tmp/after.txt`
4. Ignore the noise (timestamps, counters) and turn what's left into a `defaults write` in `macos-defaults.sh`.

`defaults read` prints numeric keys without quotes, so grep for `79 =`, not `"79"`.

## Candidates (not adopted yet)

Section 2 of `macos-defaults.sh` holds commented-out settings from common Linux-to-Mac complaints — uncomment to adopt:
fixed Spaces order, hot corner, Dock autohide, key repeat instead of the accent picker, smart quotes/autocorrect off,
Finder (hidden files, extensions, path bar, search current folder), screenshot folder, Reduce Motion.

Other things worth knowing about:

- **BetterDisplay** — sharp text on non-4K external monitors (macOS dropped subpixel anti-aliasing).
- **SSH keys in Keychain** — `~/.ssh/config`: `Host *`, `AddKeysToAgent yes`, `UseKeychain yes`.
- **Global gitignore with `.DS_Store`**; and the filesystem is case-insensitive, which bites git case-only renames.
- **Spotlight** — add code folders to System Settings → Spotlight → Privacy so it stops indexing `node_modules`.
- **Finder** — Enter renames (Cmd+O opens); there's no Cut (copy, then Cmd+Option+V moves).

## Loose ends

- Settings marked `VERIFY` in `macos-defaults.sh` (built-in tiling, freeing Ctrl+Space) haven't been checked on a fresh Mac — do the before/after diff once and remove the marker.
  belongs in this README.
