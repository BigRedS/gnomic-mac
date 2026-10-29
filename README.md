# mac-setup

Make a Mac behave enough like GNOME that Debian/GNOME muscle memory works, with a PC keyboard.

It doesn't make macOS look like GNOME. It makes the interactions less surprising: Super does what Super does, windows
snap where you expect, text moves by word on Ctrl+arrows.

It's split into three layers, applied in order. Each works without the ones after it:

| Layer | What it does | Who it's for |
|---|---|---|
| `gnome` | Tap Super to search, top-left corner for the overview, Super+arrows to snap, Alt+Tab between windows, Alt+F4, fixed desktops spanning all displays on Ctrl+Alt+arrows and Super+PgUp/PgDn, screenshots to file and clipboard, PC-style Home/End and word movement, Finder Delete key | Anyone used to GNOME |
| `pc-keyboard` | Ctrl, Super and Alt where a PC keyboard has them, on the MacBook keyboard and on a PC keyboard in Mac mode | Anyone with a PC-layout keyboard |
| `personal` | My apps, file associations, webcam fix, terminal, 70/30 snapping, no native full screen | Me. Read it as an example, or skip it |

This is documentation as much as automation; partly to remind me what I like.

Dotfiles live in chezmoi, which has a `~/.bashrc_macos` for macOS shell config.

---

## Repo layout

```
init.sh                      ./init.sh [--admin] [LAYER...]; safe to re-run
gnome/
  Brewfile                   Hammerspoon, Karabiner-Elements, AltTab
  defaults.sh                System Settings: desktops, hot corner, tiling, screenshots (section 2 = candidates)
  hammerspoon.lua            Super keys, tap-Super veto, screenshot clipboard, Finder Delete
  karabiner.json             tap-Super detection
  DefaultKeyBinding.dict     Home/End, Ctrl+arrows       → copied to ~/Library/KeyBindings/
pc-keyboard/
  karabiner.json             per-keyboard modifier fixes, virtual keyboard type
personal/
  Brewfile  defaults.sh  hammerspoon.lua  karabiner.json
  duti.conf, fix-file-associations   which app opens which file type
hammerspoon/init.lua         settings (incl. what tapping Super does); loads gnome.lua then personal.lua  → ~/.hammerspoon/
karabiner/build.sh           merges the layers' karabiner.json → ~/.config/karabiner/karabiner.json
```

`~/.hammerspoon` is a real directory holding a symlink per layer. `~/.config/karabiner/karabiner.json` is generated.
Change the repo, not those.

---

## Setup

This needs permissions that are _normally_ available on corporate MacBooks at tech firms:

* Admin rights for Homebrew, `/etc/shells`, and approving system extensions
* Hammerspoon: Accessibility and Input Monitoring
* Karabiner-Elements: its driver extension (DriverKit) and Input Monitoring

Hammerspoon and Karabiner are hard requirements. Without them it's probably easier to go the VM route.

macOS 15 or later ships `jq`, which the Karabiner build needs; on older versions `init.sh` installs it from Homebrew.

### 1. Get the repo and run the script

Do this _before_ chezmoi, since this is how the personal layer gets a Bash newer than the Millennium Dome.

```sh
xcode-select --install
git clone git@github.com:BigRedS/mac-config ~/src/mac-setup
cd ~/src/mac-setup
./init.sh                         # all three layers
./init.sh gnome pc-keyboard       # or just some; gnome is required
./init.sh --admin                 # personal layer: also make Homebrew's bash the login shell
```

With the personal layer, chezmoi is now installed, so add the key to GitHub and set that up.

A cask fails if the app was already installed by hand at a different version. Update or delete the app and re-run.

### 2. Permissions prompts

There's a lot of clicking. `init.sh` launches each app to trigger its prompts, but just in case:

**Privacy & Security**

* *Accessibility*: Hammerspoon, for the window keys.
* *Input Monitoring*: Hammerspoon, for the Activities veto and the Finder Delete key.
* *Input Monitoring*: `karabiner_grabber` and `karabiner_observer` (might show as `Karabiner-Core-Service`).
* *Screen Recording*: AltTab, for window thumbnails.

**Login Items & Extensions**

* *Driver Extensions*: enable `Karabiner-DriverKit-VirtualHIDDevice`.
* *Login Items*: allow Karabiner's background items.

Karabiner silently does nothing until all of these are done. Check *Karabiner-Elements Settings → Log* shows no driver
errors, and that `Karabiner-EventViewer` logs key presses.

If Karabiner was running before `init.sh` first set up `~/.config/karabiner`, it keeps watching the old location and
ignores changes. Reboot, then check it's reading the new file (see [Checks](#checks)).

Hammerspoon should start at login: tick *Launch Hammerspoon at login* in its preferences. Karabiner and AltTab add
themselves.

**Mic and camera** (personal): might as well do these _before_ trying to join a meeting. Firefox, Teams, Zoom, Granola.

### 3. gnome: manual steps

1. *System Settings → Desktop & Dock → Windows*. `defaults.sh` sets these, but they're marked VERIFY, so check:
   * *Drag windows to screen edges to tile* **on**
   * *Drag windows to menu bar to fill screen* **on**
   * *Tiled windows have margins* **off**
2. AltTab:
   * shortcut on **Cmd+Tab** (physical Alt+Tab)
   * *Appearance → Apparition delay* **0**
   * Alt+backtick already cycles the current app's windows: it's macOS's own Cmd+backtick. For a switcher with
     thumbnails instead, set AltTab's second shortcut to hold **Cmd**, key **`**, showing the active app's windows.
3. Notifications. Best done once everything is installed, and redone now and then:
   * Most apps: alert style *None*, but keep *Show in Notification Centre* and *Badge application icon*. Nothing pops
     up; everything waits in the list behind the clock, like GNOME.
   * **Alerts** (stay until dismissed) only for things that must interrupt: calls and calendar reminders.

### 4. pc-keyboard: manual steps

1. *System Settings → Keyboard → Text Input → Edit*: add `British – PC`, remove every other source, and untick
   *Automatically switch to a document's input source*. Leave the keyboard itself in Mac mode (Fn+O on a Logitech).
2. *System Settings → Keyboard → Keyboard Shortcuts → Modifier Keys*: reset to defaults, even Caps Lock. Anything set
   here confuses Karabiner.
3. Using a PC keyboard other than the Logitech MX Mechanical Mini? Put its vendor and product IDs (from
   *Karabiner-EventViewer → Devices*) into `pc-keyboard/karabiner.json`.

What the layer does:

| Keyboard | From | To | Why |
|---|---|---|---|
| MacBook | fn/Globe | Left Control | Puts Ctrl bottom-left, where a PC has it. |
| MacBook | Left Control | fn/Globe | Keeps fn reachable (fn+arrows = Home/End/PgUp/PgDn). |
| Logitech | Right Option | Right Control | In Mac mode the right-hand Ctrl position sends Option. macOS can't tell left Option from right, so only Karabiner can fix this without breaking Super. |
| All | | | Karabiner's virtual keyboard is set to ANSI, not ISO. Found by trial: that's what makes British PC come out right. |

### 5. personal: manual steps

Tabby:
- Set Ctrl+Space as the drop-down trigger (`defaults.sh` frees it from input-source switching).
- Maybe set *use option as meta key*. Probably not needed with the Karabiner rule below.

Teams has its own notification settings too. Trim them or you get duplicates.

### 6. Finish

Log out and back in (keyboard shortcuts and key bindings fully apply after a fresh login), then run through
[Checks](#checks).

---

## Keys at a glance

**Super is the key next to Ctrl**: Option on the MacBook, Start on a PC keyboard in Mac mode. **Alt is the key next to
the space bar**: Cmd on both, keeping its Mac meaning apart from Alt+Tab, Alt+F4 and the terminal.

| Keys | Does | Layer | Provided by |
|---|---|---|---|
| Tap **Super** on its own | Search (Spotlight); set `superTap = "overview"` in `hammerspoon/init.lua` for Mission Control | gnome | Karabiner + Hammerspoon |
| Mouse to **top-left corner** | Mission Control | gnome | macOS hot corner (scripted) |
| **Super + ← / →** | Snap window left / right (halves; 70/30 in personal) | gnome | Hammerspoon |
| **Super + ↑ / ↓** | Maximise / restore | gnome | Hammerspoon |
| **Super + H** | Minimise window | gnome | Hammerspoon |
| **Super + Shift + ← / →** | Window to other display | gnome | Hammerspoon |
| **Super + L** | Lock screen | gnome | Hammerspoon |
| **Super + D** | Show desktop | gnome | Hammerspoon |
| **Alt + F4** | Close window (Fn+Alt+F4 on a MacBook) | gnome | Hammerspoon |
| **Alt + Tab** | Switch windows | gnome | AltTab |
| **Alt + `** | Next window of this app | gnome | macOS (built in) |
| **Ctrl + Alt + ← / →**, **Super + PgUp / PgDn** | Previous / next desktop | gnome | macOS shortcut (scripted); Hammerspoon forwards Super+PgUp/PgDn |
| **Ctrl + Alt + ↑** | Mission Control | gnome | macOS shortcut (scripted) |
| **Ctrl + Alt + ↓** | This app's windows | gnome | macOS shortcut (scripted) |
| **Home / End** | Start / end of line | gnome | DefaultKeyBinding.dict |
| **Ctrl + ← / →** | Previous / next word | gnome | DefaultKeyBinding.dict |
| **Ctrl + Backspace / Delete** | Delete word | gnome | DefaultKeyBinding.dict |
| **Delete** (in Finder) | Move to Bin | gnome | Hammerspoon |
| Drag window to screen edge / top | Half screen / fill | gnome | macOS tiling |
| Double-click title bar | Maximise (Fill) | gnome | macOS (scripted) |
| Green button, **Ctrl + Cmd + F** | Maximise, never native full screen | personal | Hammerspoon (`fullscreen` setting) |
| **Cmd + Shift + 3 / 4 / 5** | Screenshot to `~/Pictures/Screenshots` *and* the clipboard | gnome | macOS + Hammerspoon |
| **Caps Lock** | Escape | personal | Karabiner |
| **Ctrl + Space** | Drop-down terminal | personal | Tabby |
| **Alt + .** (in Tabby) | Last argument | personal | Karabiner |

`DefaultKeyBinding.dict` only affects native Mac apps. Electron apps (Teams, Slack, VS Code, Tabby) ignore it.

---

## Why some things are the way they are

- **Tapping Super searches; the overview is on the top-left corner.** GNOME's Activities is a window overview and a
  search box at once, and macOS splits them into Mission Control and Spotlight. GNOME also has the top-left hot corner,
  so mouse users get the overview there and keyboard users get search on Super. Swap with `superTap` in
  `hammerspoon/init.lua`.
- **Screenshots: file and clipboard, no floating thumbnail.** macOS can save a screenshot or copy it, not both, so
  Hammerspoon watches the Screenshots folder and copies each new file. With the thumbnail on, macOS only writes the
  file once the thumbnail goes away, about 5 seconds later. The copy then lands late and overwrites anything copied in
  the meantime (tested 2026-10-29).
- **Super+PgUp/PgDn re-send Ctrl+Cmd+arrows.** macOS allows one shortcut per action. The synthetic key needs the fn
  flag, because macOS stores arrow-key shortcuts with it.
- **Native full screen becomes maximise (personal).** macOS can't turn native full screen off, and with one desktop
  spanning both displays it blanks the other screen. Hammerspoon takes any window that goes full screen straight back
  out and maximises it once the exit animation ends. Video players can't go truly full screen either, which is why
  the GNOME layer leaves it off: `fullscreen = "maximise"` in a later layer turns it on.
- **Super is Option, not Cmd.** It's the key in Super's position on both keyboards. Cmd stays Cmd because Cmd+C/V/X,
  Cmd+arrows and the rest are how every Mac app works; remapping it costs more than it saves.
- **Tap-Super-for-Activities is split across Karabiner and Hammerspoon.** Karabiner spots the lone tap
  (`to_if_alone` → F19) because it sits under everything: it sees keys that AltTab swallows before Hammerspoon's
  eventtap gets them, and it never mistakes its own synthetic modifier releases for real ones. Hammerspoon binds F19
  and vetoes it if the mouse was used while Super was held, because Karabiner can't see the trackpad. Doing it all in
  one layer gives phantom Activities either on fast Alt+Tab / Tabby's Alt+. or on Super+click. Before Super moved to
  Option, the tap was on Cmd, which is where those collisions came from.
- **macOS's own tiling *shortcuts* are off** (drag-to-snap stays on). Arrow keys carry a hidden fn flag, so the
  Globe+Ctrl+arrow tiling shortcuts also fired on plain Ctrl+arrows from external keyboards, moving windows instead of
  the cursor. `gnome/defaults.sh` disables those 18 shortcuts.
- **One desktop spans both displays**, so switching moves every screen together ("Displays have separate Spaces" is
  off). Stock GNOME only switches the primary display and leaves the others put; macOS can't do that, so this is the
  nearer of the two it offers. The menu bar and Dock then only show on the main display, and full-screen apps blank
  the other displays; the personal layer turns full screen into maximise for that reason.
- **Desktop switching is on Ctrl+Alt+arrows**, not Ctrl+arrows (the macOS default). That frees Ctrl+arrows for word
  movement, as on Linux.
- **Karabiner's config is generated.** Each layer has a `karabiner.json` fragment; `karabiner/build.sh` merges them
  into the selected profile and leaves Karabiner's other settings alone. Remaps changed in Karabiner's GUI get
  overwritten on the next run. Fragments can carry `_comment` keys, which the build strips.
- **Complex rules from later layers go first** in the generated config. Karabiner uses the first rule that matches, so
  a later layer can override an earlier one.
- **`~/.config/karabiner` is a real directory**, not a link into the repo. Karabiner saves by replacing
  `karabiner.json` and writes backups next to it; neither belongs in git.
- **`DefaultKeyBinding.dict` is copied, not symlinked**, because some sandboxed apps won't follow a symlink there.
- **The keyboard shortcut values in `defaults.sh` were captured, not guessed:** set it once in System Settings, then
  `defaults read` before and after and `diff`. See [Scripting another setting](#scripting-another-setting).

---

## personal: background notes

### Default apps (duti)

Finder's *Change All…* is forever being overridden by apps, so `init.sh` runs `fix-file-associations`, which points
file types at the apps in `personal/duti.conf`. duti is really prompt-happy (every change needs a confirmation), so
the script only applies the entries that have drifted.

### Tabby: Quake-style drop-down terminal

Getting Alt to work as Meta in the shell needs care: physical Alt sends Cmd. A Karabiner rule in
`personal/karabiner.json` turns Alt+`.`/`b`/`f`/`d`/Backspace into Escape-then-key, only when Tabby is frontmost.
`osascript -e 'id of app "Tabby"'` should print `org.tabby`.

### Bash

macOS's shell is a late-2000s BSD tribute act. `init.sh --admin` adds Homebrew's bash to `/etc/shells` and makes it
the login shell.

You can't just replace the BSD userland with GNU, because some tooling detects macOS and expects BSD interfaces. The GNU
tools are installed under their `g*` names (`gsed`, `gdate`, `gfind`…) and aliased in `~/.bashrc_macos`.

### Webcam flicker (50Hz)

UK mains lighting makes webcams flicker unless they're set to 50Hz. The C920 defaults to 60Hz and forgets the setting
every time the dock is unplugged, so `personal/hammerspoon.lua` sets it whenever the camera connects.

`init.sh` clones [uvc-util](https://github.com/jtfrey/uvc-util) into `~/opt/uvc-util`, builds it, and links
`~/bin/uvc-util`; it isn't in Homebrew. Query and set the setting by hand with (1 = 50Hz, 2 = 60Hz):

```
uvc-util -V <vendor>:<product> -S power-line-frequency
uvc-util -V <vendor>:<product> -s power-line-frequency=1
```

---

## Checks

- **Hammerspoon console** (menu-bar icon → Console):
  `print(require("gnome").superMouseWatcher:isEnabled(), hs.eventtap.isSecureInputEnabled(), hs.accessibilityState())`
  → `true false true`.
  - First `false` → permissions; quit and relaunch Hammerspoon.
  - Second `true` → something is holding Secure Input (password field, a terminal's "Secure Keyboard Entry",
    1Password).
- **"RegisterEventHotKey failed: -9878"** in the console → another app or a macOS shortcut already owns that key. Free
  it, then *Reload Config* (Hammerspoon only claims keys at load time).
- **Karabiner-EventViewer** shows what each physical key really sends; the first thing to check when a remap
  misbehaves. Simple modifications apply before complex rules.
- **Karabiner picked up a change?** `tail /var/log/karabiner/core_service.log` shows a `Load …karabiner.json` line.
- **A keyboard shortcut's stored value:**
  `plutil -extract AppleSymbolicHotKeys.79 xml1 -o - ~/Library/Preferences/com.apple.symbolichotkeys.plist`
- **Which app owns a file type:** `duti -x yaml`.

## Scripting another setting

1. `defaults read > /tmp/before.txt`
2. Change the setting in System Settings.
3. `defaults read > /tmp/after.txt && diff /tmp/before.txt /tmp/after.txt`
4. Ignore the noise (timestamps, counters) and turn what's left into a `defaults write` in the right layer's
   `defaults.sh`.

`defaults read` prints numeric keys without quotes, so grep for `79 =`, not `"79"`.

## Candidates (not adopted yet)

Section 2 of `gnome/defaults.sh` holds commented-out settings from common Linux-to-Mac complaints. Uncomment to adopt:
Dock autohide, Ctrl+Cmd+drag to move windows, key repeat instead of the accent picker, smart quotes/autocorrect off,
Finder (hidden files, extensions, path bar, search current folder), Reduce Motion.

Other things worth knowing about:

- **BetterDisplay**: sharp text on non-4K external monitors (macOS dropped subpixel anti-aliasing).
- **SSH keys in Keychain**: `~/.ssh/config` with `Host *`, `AddKeysToAgent yes`, `UseKeychain yes`.
- **Global gitignore with `.DS_Store`**; and the filesystem is case-insensitive, which bites git case-only renames.
- **Spotlight**: add code folders to *System Settings → Spotlight → Privacy* so it stops indexing `node_modules`.
- **Finder**: Enter renames (Cmd+O opens); there's no Cut (copy, then Cmd+Option+V moves).

## Loose ends

- Settings marked `VERIFY` in `gnome/defaults.sh` and `personal/defaults.sh` (built-in tiling, freeing Ctrl+Space)
  haven't been checked on a fresh Mac. Do the before/after diff once and remove the marker.
- Hammerspoon's Finder Delete tap received no key events at all on 2026-10-27 while other events arrived, which points
  at Input Monitoring. Check it actually works.
- Super+L, Super+D and Super+H take Option+L, Option+D and Option+H, which type characters on Mac keyboard layouts.
- The full-screen-to-maximise catcher (`fullscreen = "maximise"`) works the first time but not reliably after that.
  Seen on 2026-10-29: a second green-button click stayed in full screen, and in a scripted test a second cycle left
  the window 30px tall. Likely causes: it trusts `hs.window.filter`'s change detection, which only compares
  full-screen state after a 0.5s settle and can keep a stale "full screen" record, and it maximises on a fixed 1s
  timer rather than once the exit has finished. Fix by checking `isFullScreen()` on every move/resize, and
  maximising only after the window reports it's out and has stopped resizing; test several cycles in a row.
- A full-screen screenshot (Cmd+Shift+3) with two displays makes one file per display, and the clipboard gets whichever
  was written last. GNOME captures all displays as one image. Cmd+Shift+4 or 5 for one area doesn't have this problem.
