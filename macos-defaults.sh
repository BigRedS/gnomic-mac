#!/bin/bash
# macos-defaults.sh — the scriptable half of the Mac setup.
# Safe to re-run. User-level only (no sudo).
#
# Section 1 = things actually decided/set up. Section 2 = candidates from the
# "common Linux→Mac complaints" list, commented out until chosen — uncomment as you adopt them.
#
# Lines marked VERIFY: key names I'm less sure of on current macOS. Check once with
#   defaults read > /tmp/before; <change it in System Settings>; defaults read > /tmp/after; diff /tmp/before /tmp/after

set -u

###############################################################################
# 1. DECIDED
###############################################################################

# Clicking the wallpaper no longer sweeps all windows away (only in Stage Manager)
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
# Stage Manager off
defaults write com.apple.WindowManager GloballyEnabled -bool false

# Built-in drag-to-snap tiling (replaces Rectangle's drag behaviour)          # VERIFY
defaults write com.apple.WindowManager EnableTilingByEdgeDrag -bool true
defaults write com.apple.WindowManager EnableTopTilingByEdgeDrag -bool true
defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false

# Expanded save dialogs (so you can see where things go)
defaults write -g NSNavPanelExpandedStateForSaveMode -bool true
defaults write -g NSNavPanelExpandedStateForSaveMode2 -bool true

# Free Ctrl+Space for Tabby (and Ctrl+Opt+Space) from input-source switching   # VERIFY
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 "<dict><key>enabled</key><false/></dict>"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 61 "<dict><key>enabled</key><false/></dict>"

# Ctrl+Cmd+Left/Right (= Ctrl+Alt on the Logitech) → move left/right a Space    (verified)
# 79 = Move left a space, 81 = Move right a space. Params: char (65535 = none), keycode (123 ←, 124 →),
# modifier mask (ctrl 262144 + cmd 1048576 + fn/arrow 8388608 = 9699328).
# Check against: plutil -extract AppleSymbolicHotKeys.79 xml1 -o - ~/Library/Preferences/com.apple.symbolichotkeys.plist
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 79 \
  '<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>123</integer><integer>9699328</integer></array><key>type</key><string>standard</string></dict></dict>'
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 81 \
  '<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>124</integer><integer>9699328</integer></array><key>type</key><string>standard</string></dict></dict>'

# Ctrl+Cmd+Up → Mission Control (32), Ctrl+Cmd+Down → Application windows (33)   (verified)
# Modifier mask: ctrl 262144 + cmd 1048576 + fn/arrow 8388608 = 9699328. Keycodes 126 ↑, 125 ↓.
# Check against: plutil -extract AppleSymbolicHotKeys.32 xml1 -o - ~/Library/Preferences/com.apple.symbolichotkeys.plist
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 32 \
  '<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>126</integer><integer>9699328</integer></array><key>type</key><string>standard</string></dict></dict>'
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 33 \
  '<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>125</integer><integer>9699328</integer></array><key>type</key><string>standard</string></dict></dict>'

# Disable macOS's built-in window-tiling shortcuts (Globe+Ctrl+arrows etc.). Arrow keys carry the fn
# flag, so these also fire on plain Ctrl+arrows from external keyboards. Snapping is done by Hammerspoon
# (Option+arrows); Ctrl+arrows are word-jump via DefaultKeyBinding.dict.
# IDs captured by diffing defaults before/after unticking them in System Settings.
for id in 233 235 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 256; do
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$id" "<dict><key>enabled</key><false/></dict>"
done

###############################################################################
# 2. CANDIDATES — not yet decided; uncomment to adopt
###############################################################################

# --- Spaces / Dock (suggested early on, never confirmed) ---
# defaults write com.apple.dock mru-spaces -bool false           # keep Spaces in fixed order
# defaults write com.apple.dock wvous-tl-corner -int 2           # top-left hot corner → Mission Control
# defaults write com.apple.dock wvous-tl-modifier -int 0
# defaults write com.apple.dock autohide -bool true
# defaults write com.apple.dock autohide-delay -float 0
# defaults write -g AppleActionOnDoubleClick -string "Fill"     # double-click title bar → Fill  VERIFY

# --- Windows ---
# defaults write -g NSWindowShouldDragOnGesture -bool true       # Ctrl+Cmd+drag moves windows (logout)

# --- Keyboard & text ---
# defaults write -g ApplePressAndHoldEnabled -bool false         # key repeat instead of accent picker
# defaults write -g KeyRepeat -int 2                             # fast repeat (logout)
# defaults write -g InitialKeyRepeat -int 15                     # short delay (logout)
# defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false
# defaults write -g NSAutomaticDashSubstitutionEnabled -bool false
# defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
# defaults write -g NSAutomaticCapitalizationEnabled -bool false
# defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false

# --- Finder ---
# defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# defaults write com.apple.finder AppleShowAllFiles -bool true
# defaults write com.apple.finder ShowPathbar -bool true
# defaults write com.apple.finder ShowStatusBar -bool true
# defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
# defaults write com.apple.finder FXDefaultSearchScope -string SCcf   # search current folder
# defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# --- Screenshots ---
# mkdir -p "$HOME/Pictures/Screenshots"
# defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"

# --- Accessibility (often needs Full Disk Access for the terminal) ---
# defaults write com.apple.universalaccess reduceMotion -bool true

###############################################################################
# Apply
###############################################################################
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null || true
killall Dock Finder SystemUIServer cfprefsd 2>/dev/null || true
echo "Done. Some changes need a logout/login."
