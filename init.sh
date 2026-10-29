#!/bin/bash
# init.sh — bootstrap a Mac from this repo, one layer at a time.
#
#   ./init.sh [--admin] [LAYER...]
#
# Layers, applied in this order (default: all three):
#   gnome        GNOME-style window keys, Activities, Alt+Tab, text movement
#   pc-keyboard  Ctrl/Super/Alt where a PC keyboard has them
#   personal     Avi's apps, file associations, webcam, preferences
# gnome is required; the others are optional, e.g. ./init.sh gnome pc-keyboard
#
#   --admin      also make Homebrew's bash the login shell (personal layer; needs sudo)
#
# Safe to re-run: every step checks before it acts, so running it again just
# fixes whatever has drifted. Written for macOS's own bash 3.2, because it runs
# before Homebrew's bash exists. The manual steps are in README.md.

set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
ADMIN=0
LAYERS=()
for arg in "$@"; do
  case "$arg" in
    --admin) ADMIN=1 ;;
    -h|--help) sed -n '2,17p' "$0"; exit 0 ;;
    gnome|pc-keyboard|personal) LAYERS+=("$arg") ;;
    *) echo "Unknown option or layer: $arg" >&2; exit 1 ;;
  esac
done
[ ${#LAYERS[@]} -gt 0 ] || LAYERS=(gnome pc-keyboard personal)

# Put the layers in canonical order whatever order they were given in, since
# later layers override earlier ones.
ordered=()
for l in gnome pc-keyboard personal; do
  for want in "${LAYERS[@]}"; do [ "$want" = "$l" ] && ordered+=("$l") && break; done
done
LAYERS=("${ordered[@]}")
[ "${LAYERS[0]}" = gnome ] || { echo "The gnome layer is required; the others build on it." >&2; exit 1; }

has_layer() {
  local l
  for l in "${LAYERS[@]}"; do [ "$l" = "$1" ] && return 0; done
  return 1
}

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

###############################################################################
step "Preflight"
###############################################################################

if [ "$(uname -s)" != "Darwin" ]; then
  echo "This is for macOS." >&2; exit 1
fi
ok "macOS $(sw_vers -productVersion), repo at $REPO, layers: ${LAYERS[*]}"

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

for l in "${LAYERS[@]}"; do
  [ -f "$REPO/$l/Brewfile" ] || continue
  if brew bundle check --no-upgrade --file="$REPO/$l/Brewfile" >/dev/null 2>&1; then
    ok "$l/Brewfile"
  else
    # An app installed outside Homebrew makes its cask fail here unless it's
    # the same version Homebrew would install (then brew adopts it). Either
    # update the app to match, or delete it and re-run to let brew install it.
    brew bundle install --no-upgrade --file="$REPO/$l/Brewfile" && did "$l/Brewfile" \
      || warn "$l/Brewfile: some installs failed (see above)"
  fi
done

# karabiner/build.sh needs jq, which ships with macOS 15 and later.
if command -v jq >/dev/null 2>&1; then ok "jq"; else brew install jq && did "jq"; fi

###############################################################################
step "Hammerspoon"
###############################################################################

# ~/.hammerspoon is a real directory of per-layer symlinks, so skipping a
# layer is just not linking its module. Older setups linked the whole
# directory into the repo; undo that first or the links land in the repo.
if [ -L "$HOME/.hammerspoon" ]; then rm "$HOME/.hammerspoon"; did "removed old ~/.hammerspoon directory symlink"; fi
link "$REPO/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"
for l in gnome personal; do
  if has_layer "$l"; then
    link "$REPO/$l/hammerspoon.lua" "$HOME/.hammerspoon/$l.lua"
  elif [ -L "$HOME/.hammerspoon/$l.lua" ]; then
    rm "$HOME/.hammerspoon/$l.lua"; did "unlinked ~/.hammerspoon/$l.lua (layer not selected)"
  fi
done

###############################################################################
step "Karabiner"
###############################################################################

# Karabiner's config is generated from each layer's fragment into a real
# ~/.config/karabiner, where Karabiner also keeps its backups. Older setups
# linked that directory into the repo; keep the live file and undo that.
if [ -L "$HOME/.config/karabiner" ]; then
  old_karabiner="$(cd "$HOME/.config/karabiner" && pwd -P)"
  rm "$HOME/.config/karabiner"
  mkdir -p "$HOME/.config/karabiner"
  if [ -f "$old_karabiner/karabiner.json" ]; then cp -p "$old_karabiner/karabiner.json" "$HOME/.config/karabiner/"; fi
  did "replaced ~/.config/karabiner symlink with a real directory (restart Karabiner-Elements to pick it up)"
fi
layer_dirs=()
for l in "${LAYERS[@]}"; do layer_dirs+=("$REPO/$l"); done
"$REPO/karabiner/build.sh" "${layer_dirs[@]}"

###############################################################################
step "Text movement (DefaultKeyBinding.dict)"
###############################################################################

# Copied, not linked: some sandboxed apps won't follow a symlink here.
mkdir -p "$HOME/Library/KeyBindings"
if cmp -s "$REPO/gnome/DefaultKeyBinding.dict" "$HOME/Library/KeyBindings/DefaultKeyBinding.dict"; then
  ok "DefaultKeyBinding.dict"
else
  cp "$REPO/gnome/DefaultKeyBinding.dict" "$HOME/Library/KeyBindings/DefaultKeyBinding.dict"
  did "DefaultKeyBinding.dict (quit and reopen apps to pick it up)"
fi

###############################################################################
step "macOS settings"
###############################################################################

for l in "${LAYERS[@]}"; do
  if [ -f "$REPO/$l/defaults.sh" ]; then
    bash "$REPO/$l/defaults.sh" && did "$l/defaults.sh" || warn "$l/defaults.sh reported a problem"
  fi
done

###############################################################################
if has_layer personal; then
step "Personal: default apps (expect one confirmation prompt per changed file type)"
###############################################################################

  if command -v duti >/dev/null 2>&1; then
    "$REPO/personal/fix-file-associations" "$REPO/personal/duti.conf" && ok "file associations" \
      || warn "fix-file-associations reported a problem"
  else
    warn "duti missing — file associations skipped"
  fi

###############################################################################
step "Personal: uvc-util (webcam 50Hz anti-flicker)"
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
step "Personal: login shell"
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
fi

###############################################################################
step "Start the apps that need permissions"
###############################################################################

apps=(Hammerspoon Karabiner-Elements AltTab)
if has_layer personal; then apps+=(Tabby); fi
for app in "${apps[@]}"; do
  if open -ga "$app" 2>/dev/null; then ok "$app launched"
  else warn "couldn't launch $app"
  fi
done

cat <<'EOF2'

Scripted part done. Now work through the manual steps in README.md —
in particular the Hammerspoon and Karabiner permissions: nothing keyboard-related
works until those are granted. Log out and back in once you've finished.
EOF2
