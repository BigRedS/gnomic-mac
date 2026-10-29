#!/bin/bash
# init.sh — bootstrap a new Mac from this repo.
#
# Safe to re-run: every step checks before it acts, so running it again just
# fixes whatever has drifted. Written for macOS's own bash 3.2, because it runs
# before Homebrew's bash exists.
#
#   ./init.sh            user-level setup (no sudo, except Homebrew's own installer)
#   ./init.sh --admin    also make Homebrew's bash the login shell (needs sudo)
#
# The manual steps that can't be scripted are in README.md.

set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
ADMIN=0
for arg in "$@"; do
  case "$arg" in
    --admin) ADMIN=1 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

###############################################################################
# Homebrew install list — add to these
###############################################################################

BREW_FORMULAE=(
  # Shell: modern bash instead of macOS's 3.2 from 2007
  bash
  bash-completion@2
  # GNU userland, installed under g-prefixed names (gsed, gdate…) — aliased in ~/.bashrc_macos, NOT put on PATH
  coreutils
  gnu-sed
  findutils
  grep
  gawk
  gnu-tar
  # File associations (used by fix-defaults)
  duti
  # Dotfiles
  chezmoi
  git
)

BREW_CASKS=(
  hammerspoon          # GNOME-ish window keys, Finder Delete key, app/USB watchers
  karabiner-elements   # all keyboard remapping
  alt-tab              # Cmd+Tab switches windows, not apps
  tabby                # drop-down terminal on Ctrl+Space
  coteditor            # the "gedit" — default for text/YAML/JSON
  libreoffice          # default for CSV
  #firefox             # disabled; hopefully this gets fewer of the "close firefox and lose all your work to carry on using your browser" thing when it updates underneath itself 
  thunderbird
  # microsoft-teams    # Probably MDMed
  # granola            # ditto
)

###############################################################################
# Helpers
###############################################################################

step() { printf '\n\033[1m== %s\033[0m\n' "$*"; }
ok()   { printf '   ok    %s\n' "$*"; }
did()  { printf '   done  %s\n' "$*"; }
warn() { printf '   \033[33mWARN\033[0m  %s\n' "$*"; }

# link SRC DST — symlink DST → SRC, backing up anything that's already there.
link() {
  local src="$1" dst="$2"
  if [ ! -e "$src" ]; then warn "not in repo, skipping: $src"; return 0; fi
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    if [ "$(readlink "$dst")" = "$src" ]; then ok "$dst"; return 0; fi
    rm "$dst"
  elif [ -e "$dst" ]; then
    local bak
    bak="$dst.bak.$(date +%Y%m%d%H%M%S)"
    mv "$dst" "$bak"
    warn "moved existing $dst to $bak"
  fi
  ln -s "$src" "$dst"
  did "$dst → $src"
}

# in_list ITEM LIST — true if ITEM is a whole line of LIST (avoids grep -q + pipefail SIGPIPE).
in_list() {
  case $'\n'"$2"$'\n' in
    *$'\n'"$1"$'\n'*) return 0 ;;
    *) return 1 ;;
  esac
}

###############################################################################
step "Preflight"
###############################################################################

if [ "$(uname -s)" != "Darwin" ]; then
  echo "This is for macOS." >&2; exit 1
fi
ok "macOS $(sw_vers -productVersion), repo at $REPO"

if ! xcode-select -p >/dev/null 2>&1; then
  warn "Xcode command-line tools missing — starting the installer."
  xcode-select --install || true
  echo "Re-run ./init.sh when the command-line tools have finished installing."
  exit 1
fi
ok "Xcode command-line tools"

###############################################################################
step "Homebrew"
###############################################################################

if ! command -v brew >/dev/null 2>&1; then
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ -x "$b" ] && eval "$("$b" shellenv)" && break
  done
fi
if ! command -v brew >/dev/null 2>&1; then
  echo "   Installing Homebrew (asks for your password)…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ -x "$b" ] && eval "$("$b" shellenv)" && break
  done
fi
ok "brew at $(command -v brew)"
BREW_PREFIX="$(brew --prefix)"

installed_f="$(brew list --formula -1 2>/dev/null || true)"
for f in "${BREW_FORMULAE[@]}"; do
  if in_list "$f" "$installed_f"; then ok "$f"
  else brew install "$f" && did "$f" || warn "brew install $f failed"
  fi
done

installed_c="$(brew list --cask -1 2>/dev/null || true)"
for c in "${BREW_CASKS[@]}"; do
  if in_list "$c" "$installed_c"; then ok "$c"
  else brew install --cask "$c" && did "$c" || warn "brew install --cask $c failed (already installed outside brew?)"
  fi
done

###############################################################################
step "Config files"
###############################################################################

# ~/.hammerspoon is a real directory of per-layer symlinks, so skipping a
# layer is just not linking its module. Older setups linked the whole
# directory into the repo; undo that first or the links land in the repo.
[ -L "$HOME/.hammerspoon" ] && rm "$HOME/.hammerspoon" && did "removed old ~/.hammerspoon directory symlink"
link "$REPO/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"
link "$REPO/gnome/hammerspoon.lua" "$HOME/.hammerspoon/gnome.lua"
link "$REPO/personal/hammerspoon.lua" "$HOME/.hammerspoon/personal.lua"

# Karabiner rewrites karabiner.json by replacing the file, which breaks a
# symlink to the file itself — so link the whole directory instead.
link "$REPO/karabiner" "$HOME/.config/karabiner"

# Default-app list read by fix-defaults.
link "$REPO/duti.conf" "$HOME/.duti"

# Copied, not linked: some sandboxed apps won't follow a symlink here.
if [ -f "$REPO/keybindings/DefaultKeyBinding.dict" ]; then
  mkdir -p "$HOME/Library/KeyBindings"
  if cmp -s "$REPO/keybindings/DefaultKeyBinding.dict" "$HOME/Library/KeyBindings/DefaultKeyBinding.dict"; then
    ok "DefaultKeyBinding.dict"
  else
    cp "$REPO/keybindings/DefaultKeyBinding.dict" "$HOME/Library/KeyBindings/DefaultKeyBinding.dict"
    did "DefaultKeyBinding.dict (quit and reopen apps to pick it up)"
  fi
else
  warn "not in repo, skipping: keybindings/DefaultKeyBinding.dict"
fi

###############################################################################
step "uvc-util (webcam 50Hz anti-flicker)"
###############################################################################

UVC_SRC="$HOME/opt/uvc-util"
mkdir -p "$HOME/opt" "$HOME/bin"

if [ -d "$UVC_SRC/.git" ]; then
  before="$(git -C "$UVC_SRC" rev-parse HEAD)"
  git -C "$UVC_SRC" pull --ff-only --quiet || warn "couldn't update $UVC_SRC"
  after="$(git -C "$UVC_SRC" rev-parse HEAD)"
else
  git clone --quiet https://github.com/jtfrey/uvc-util.git "$UVC_SRC"
  before=""; after="new"
fi

if [ ! -x "$UVC_SRC/src/uvc-util" ] || [ "$before" != "$after" ]; then
  (cd "$UVC_SRC/src" && cc -o uvc-util -framework IOKit -framework Foundation \
     uvc-util.m UVCController.m UVCType.m UVCValue.m) \
    && did "built $UVC_SRC/src/uvc-util" \
    || warn "uvc-util build failed"
else
  ok "uvc-util already built"
fi
link "$UVC_SRC/src/uvc-util" "$HOME/bin/uvc-util"

case ":$PATH:" in
  *":$HOME/bin:"*) ok "\$HOME/bin is on PATH" ;;
  *) warn "\$HOME/bin isn't on PATH in this shell — check .bashrc_macos (chezmoi)" ;;
esac

###############################################################################
step "macOS settings"
###############################################################################

if [ -x "$REPO/macos-defaults.sh" ]; then
  "$REPO/macos-defaults.sh"
else
  warn "macos-defaults.sh missing or not executable"
fi

###############################################################################
step "Default apps (expect one confirmation prompt per changed file type)"
###############################################################################

if [ -x "$REPO/fix-defaults" ] && command -v duti >/dev/null 2>&1; then
  "$REPO/fix-defaults" || warn "fix-defaults reported a problem"
else
  warn "fix-defaults or duti missing — skipped"
fi

###############################################################################
step "Login shell"
###############################################################################

BREW_BASH="$BREW_PREFIX/bin/bash"
if [ "$ADMIN" -eq 1 ]; then
  if grep -qx "$BREW_BASH" /etc/shells; then
    ok "$BREW_BASH in /etc/shells"
  else
    echo "$BREW_BASH" | sudo tee -a /etc/shells >/dev/null && did "added $BREW_BASH to /etc/shells"
  fi
  current_shell="$(dscl . -read "/Users/$USER" UserShell | awk '{print $2}')"
  if [ "$current_shell" = "$BREW_BASH" ]; then
    ok "login shell is $BREW_BASH"
  else
    chsh -s "$BREW_BASH" && did "login shell → $BREW_BASH (new terminals)"
  fi
else
  echo "   Skipped (needs sudo). Re-run with --admin, or do it by hand — see README."
fi

###############################################################################
step "Start the apps that need permissions"
###############################################################################

for app in Hammerspoon Karabiner-Elements AltTab Tabby; do
  if open -ga "$app" 2>/dev/null; then ok "$app launched"
  else warn "couldn't launch $app"
  fi
done

cat <<'EOF'

Scripted part done. Now work through "Manual steps" in README.md —
in particular the Hammerspoon and Karabiner permissions: nothing keyboard-related
works until those are granted. Log out and back in once you've finished.
EOF
