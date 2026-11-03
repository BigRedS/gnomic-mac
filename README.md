# gnomic-mac

Make a Mac behave enough like Gnome that my Debian/Gnome muscle memory works.

This doesn't make macOS look like Gnome and it doesn't fix the cmd-c-vs-ctrl-c thing, but it makes Super behave like it does in Gnome, windows snap as you expect ctrl+arrows move the cursor as you expect.

It's split into three layers, because it's also got some of my personal preference in it and splitting it hopefully makes this useful for others:

| Layer        | What it does | Who it's for |
|---           |---|---|
| `gnome`      | Tap Super to search, top-left corner for the overview, Super+arrows to snap, Alt+Tab between windows, Alt+F4, fixed desktops spanning all displays on Ctrl+Alt+arrows and Super+PgUp/PgDn, screenshots to file and clipboard, PC-style Home/End and word movement, Finder Delete key | Anyone used to GNOME |
| `pc-keyboard` | Ctrl, Super and Alt where a PC keyboard has them, on the MacBook keyboard and on a PC keyboard in Mac mode | Anyone with a (British) PC-layout keyboard |
| `personal`    | My apps, file associations, webcam fix, terminal, 70/30 snapping, no native full screen | Me. Read it as an example, or skip it |

This is documentation as much as automation; partly to remind me what I like, much of this I found by being surprised and then trying to remember what keypress I'd just tried to do. There's a few circles in the git history as I wrongly-assumed my preferences and habits.

My dotfiles live in chezmoi; I use bash and have a  `~/.bashrc_macos` for macOS-specific shell config but I don't want to over-complicate that with all
my mac-specific fixes..

---

## Repo layout

```
init.sh                      ./init.sh [--admin] [LAYER...]; safe to re-run
gnome/
  Brewfile                   Hammerspoon, Karabiner-Elements, AltTab, Rectangle
  defaults.sh                System Settings: desktops, hot corner, Rectangle, screenshots (section 2 = candidates)
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
Change the repo and re-run init, not those.

---

## Setup

This needs permissions that are _normally_ available on corporate MacBooks at tech firms:

* Admin rights for Homebrew, `/etc/shells`, and approving system extensions
* Hammerspoon: Accessibility and Input Monitoring
* Karabiner-Elements: its driver extension (DriverKit) and Input Monitoring

Hammerspoon and Karabiner are absolutely required

Karabiner uses jq to assemble its config files, new macoses come with it, but init.sh will install it if it's not here.

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

With the personal layer done, chezmoi is now installed, so add the key to GitHub and set that up.

A homebrew cask fails if the app was already installed by hand at a different version. Update or delete the app and re-run.

### 2. Permissions prompts

There's a lot of clicking here, apple _loves_ a confirmation dialog.

`init.sh` launches each app to trigger its prompts, but just in case these are what you need:

**Privacy & Security**

* *Accessibility*: Hammerspoon, for the window keys.
* *Accessibility*: Rectangle, for title-bar double-click and drag-to-edge snapping.
* *Input Monitoring*: Hammerspoon, for the Activities veto and the Finder Delete key.
* *Input Monitoring*: `karabiner_grabber` and `karabiner_observer` (might show as `Karabiner-Core-Service`).
* *Screen Recording*: AltTab, for window thumbnails.

**Login Items & Extensions**

* *Driver Extensions*: enable `Karabiner-DriverKit-VirtualHIDDevice`.
* *Login Items*: allow Karabiner's background items.

Karabiner silently does nothing until all of these are done. Check *Karabiner-Elements Settings → Log* shows no driver
errors, and that `Karabiner-EventViewer` logs key presses.

If Karabiner was running before `init.sh` first set up `~/.config/karabiner`, it keeps watching the old location and
ignores changes. Reboot (or maybe log out and back in again?), then check it's reading the new file (see [Checks](#checks)).

Hammerspoon should start at login: tick *Launch Hammerspoon at login* in its preferences. Karabiner and AltTab add
themselves.

**Mic and camera** (personal): might as well do these _before_ trying to join a meeting. Firefox, Teams, Zoom, Granola, etc.

### 3. gnome: manual steps

1. Rectangle (there's no `defaults` key for either of these):
   * It may prompt saying it conflicts with macos tiling; in this case disable it in macos. The scripts attempt to do that first anyway.
   * It will prompt to pick a Shortcut Set, pick either and then delete them all, hammerspoon will deal with keyboard shortcuts here.
   * Enable *Launch on login*
2. AltTab:
   * shortcut on **Cmd+Tab** (physical Alt+Tab)
   * *Appearance → Apparition delay* **0**
   * Alt+backtick goes through current app's windows, AltTab could be configured to intercept this and show a thumbnail picker using its 'second shortcut' feature, but doesn't currently.
3. Notifications. Best done once everything is installed, and redone now and then:
   * Most apps: alert style *None*, but keep *Show in Notification Centre* and *Badge application icon*. Have no annoying pop-ups, but things sit in th enotification list that you can drop-down
   * **Alerts** (stay until dismissed) only for things that must interrupt: calls and calendar reminders.
4. Hammerspoon:
   * Enable *Launch Hammerspoon at login*


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
| All | | | Karabiner's virtual keyboard is set to ANSI, for some reason this is actually right, not ISO. Who knows why. |

### 5. personal: manual steps

iTerm2 needs no manual work, but grant it Accessibility if it asks.

Teams has its own notification settings too. There is no way to set rules here in MacOS, you just have to keep on top of the notifications settings.

### 6. Finish

Log out and back in (keyboard shortcuts and key bindings fully apply after a fresh login), then run through
[Checks](#checks).

---

## Keys at a glance

This doesn't try to break the cmd-c/cmd-v macos expectations, just the other things I tend to forget are different in macos.

Super is the windows key, option on the Macbook. It's the one next to Ctrl.

Alt is the key next to the space bar, the cmd on the Macbook. It's overridden for a few of these (alt+., alt+f4, alt+backtick)

| Keys | Does | Layer | Provided by |
|---|---|---|---|
| Tap **Super** on its own | Search (Spotlight); set `superTap = "overview"` in `hammerspoon/init.lua` for Mission Control | gnome | Karabiner + Hammerspoon |
| Mouse to **top-left corner** | Mission Control | gnome | macOS hot corner (scripted) |
| **Super + ← / →** | Snap window left / right (halves by default; 70/30 in personal) | gnome | Hammerspoon |
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
| Drag window to left / right edge | Half screen | gnome | Rectangle |
| Double-click title bar | Maximise | gnome | Rectangle |
| Green button, **Ctrl + Cmd + F** | Maximise, never native full screen | personal | Hammerspoon (`fullscreen` setting) |
| **Cmd + Shift + 3 / 4 / 5** | Screenshot to `~/Pictures/Screenshots` *and* the clipboard | gnome | macOS + Hammerspoon |
| **Caps Lock** | Escape | personal | Karabiner |
| **Ctrl + Space** | Drop-down terminal | personal | iTerm2 hotkey window |
| **Alt + .** (in iTerm2 or Tabby) | Last argument | personal | Karabiner |
| **Ctrl + W** (outside iTerm2 and Tabby) | Delete previous word, not close the window | personal | Karabiner |

`DefaultKeyBinding.dict` only affects native Mac apps. Electron apps (Teams, Slack, VS Code) ignore it.

---

## Why some things are the way they are
- **Tap Super to search** In gnome tapping super gets you an overview with a search box, but they're different things in macos.
  When I tap super in gnome it's to search-for-and-run a thing, so this triggers Spotlight with that, not the overview.
  The overview is triggered by the hot corners, which is what I do in Gnome for that anyway.

- **Screenshots to file and straight-to-clipboard** the only way to do this seemed to be to write the file then to immediately
  copy it. If Macos shows a thumbnail of the screenshot it only writes the file once the thumbnail goes away, so the thumbnail
  is also disabled here.

- **MacOS' weird full-screen becomes a normal maximise** not-entirely-reliably; Hammerspoon is configured to notice a window
  going into full-screen and put it back to maximised which it does reliably-enough but not 100% reliably. This also breaks
  full-screen video in Firefox, for example, so is hidden in my personal layer

- **Super is Option, not Cmd.** It's the key in Super's position on both keyboards, which is different to other goes at this I looked at.
  Cmd stays Cmd because Cmd+C/V/X, Cmd+arrows and the rest are how every Mac app works and I found trying to change that even more confusing than not.

- **Super+PgUp/PgDn re-send Ctrl+Cmd+arrows.** MacOS only allows one keyboard-shortcut per action, so to have two keyboard shortcuts
  for 'move to the next desktop' Hammerspoon notices Super+PgUp and sends Ctrl+Cmd+arrow to the OS.

- **macOS's own tiling *shortcuts* are disabled**; arrow keys send a hidden fn flag, so the
  Globe+Ctrl+arrow tiling shortcuts also fired on plain Ctrl+arrows from external keyboards, moving windows instead of
  the cursor. `gnome/defaults.sh` disables those 18 shortcuts.

- **One desktop across both displays**, Displays have separate Spaces is off, This is how my laptop behaves; I think Gnome moves just
  the primary one by default and honestly I'm not sure why my laptop is different. This switches off macOS's built-in
  window tiling entirely as a side-effect so we use Rectangle for those.

- **Desktop switching is on Ctrl+Alt+arrows**, not Ctrl+arrows (the macOS default), since those are for moving the cursor
whole-words at a time. And ctrl+alt+arrow is a mapping I think I'm used to from Gnome 2.x days?

- **Karabiner's config is generated.** Each layer has a `karabiner.json`and `karabiner/build.sh` merges them
  into the appropriate profile and leaves Karabiner's other settings be. Changes made in Karabiner's GUI get
  overwritten. The config can have `_comment` keys, which the build strips

**Complex rules from later layers go first** in the generated config. Karabiner uses the first rule that matches, so
  a later layer can override an earlier one.
- **`~/.config/karabiner` is a real directory**, not a link into the repo. Karabiner saves by replacing
  `karabiner.json` and writes backups next to it and these get messy in a git repo.
- **`DefaultKeyBinding.dict` is copied, not symlinked**, because some sandboxed apps won't follow a symlink there.

---

## personal: background notes

### Default apps (duti)

Finder's *Change All…* dialog for setting default apps is forever being overridden by apps (Cursor wants to be the default for CSVs?),
so `init.sh` runs `fix-file-associations`, which points file types at the apps in `personal/duti.conf`. duti is really prompt-happy (every change needs a confirmation), so the script only applies the entries that have changed.

### iTerm2: Quake-style drop-down terminal

I like Guake and now DDTerm under Gnome. This drops down from the current-display at full-width and 40% of height, triggered with ctrl-space.
Outside of that I tend to configure colours and sizes and whatnot on-the-fly by mouse.

This repo writes a `personal/iterm2/com.googlecode.iterm2.plist` which iTerm will edit, so it's easy enough to make mouse-driven
edits automatic, but also that file will change a lot.

Getting alt to work as meta (so alt+dot works for the last arg to the previous command) is the problem that triggered this whole repo.
The alt key itself sends Cmd for some reason, but every terminal expcts it to send Option. Karabiner then turns Alt+`.`/`b`/`f`/`d`/Backspace into
Escape-then-key, only when iTerm2 or Tabby is frontmost (I used tabby for a bit when I was annoyed with iTerm2).

To find more aps to add to this rule, use osascript - `osascript -e 'id of app "iTerm"'` prints `com.googlecode.iterm2` which is what goes in the karabiner config.

### Bash

macOS's shell is a late-2000s BSD tribute act. `init.sh --admin` adds Homebrew's bash to `/etc/shells` and makes it
the login shell.

You can't just replace the BSD userland with GNU, because some tooling detects macOS and expects BSD interfaces. The GNU
tools are installed under their `g*` names (`gsed`, `gdate`, `gfind`…) and aliased in `~/.bashrc_macos`.

### Webcam flicker (50Hz)

UK mains lighting makes webcams flicker unless they're set to 50Hz. The C920 defaults to 60Hz and forgets the setting
every time the dock is unplugged, so `personal/hammerspoon.lua` sets it whenever the camera connects.

[uvc-util](https://github.com/jtfrey/uvc-util) isn't in homebrew so `init.sh` clones it into `~/opt/`, builds it, and
links to it from `~/bin`.

Query and set the setting by hand with 1 = 50Hz, 2 = 60Hz:

```
uvc-util -V <vendor>:<product> -S power-line-frequency
uvc-util -V <vendor>:<product> -s power-line-frequency=1
```

---

## Checks

"Why is hammerspoon not working" check:
* Open the Hammerspoon console (menu-bar icon -> Console) and enter `print(require("gnome").superMouseWatcher:isEnabled(), hs.eventtap.isSecureInputEnabled(), hs.accessibilityState())`:
* Expect: `true false true`.
* First `false`: permissions; quit and relaunch Hammerspoon.
* Second `true`: something is holding Secure Input (password field, a terminal's "Secure Keyboard Entry", etc.)

"RegisterEventHotKey failed: -9878" in the Hammerspoon console:
* another app or a macOS shortcut is already configured to use that key or key-combo. Free it, then do Hammerspoon's *Reload Config*

Karabiner-EventViewer shows what each physical key really sends, handy to check when a remap misbehaves. Simple modifications apply before complex rules.
- `tail /var/log/karabiner/core_service.log` shows a `Load …karabiner.json` line whenever it notices a change to the config
- `plutil -extract AppleSymbolicHotKeys.79 xml1 -o - ~/Library/Preferences/com.apple.symbolichotkeys.plist` gets the current value for a keyboard shortcut

Duti managed file associations
* `duti -x <extension>` prints the current association for a given extension

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

- **SSH keys in Keychain**: `~/.ssh/config` with `Host *`, `AddKeysToAgent yes`, `UseKeychain yes`.
- **Global gitignore with `.DS_Store`**; and the filesystem is case-insensitive, which bites git case-only renames.
- **Spotlight**: add code folders to *System Settings → Spotlight → Privacy* so it stops indexing `node_modules`.
- **Finder**: Enter renames (Cmd+O opens); there's no Cut (copy, then Cmd+Option+V moves).

## Loose ends

- Settings marked `VERIFY` in `gnome/defaults.sh` and `personal/defaults.sh` (freeing Ctrl+Space)
  haven't been checked on a fresh Mac. Do the before/after diff once and remove the marker.
- Hammerspoon's Finder Delete tap received no key events at all on 2026-10-27 while other events arrived, which points
  at Input Monitoring. Check it actually works.
- Super+L, Super+D and Super+H take Option+L, Option+D and Option+H, which type characters on Mac keyboard layouts.
- The full-screen-to-maximise catcher (`fullscreen = "maximise"`) works the first time but not reliably after that. See f39303d
- A full-screen screenshot (Cmd+Shift+3) with two displays makes one file per display, and the clipboard gets whichever
  was written last. GNOME captures all displays as one image. Cmd+Shift+4 or 5 for one area doesn't have this problem.
