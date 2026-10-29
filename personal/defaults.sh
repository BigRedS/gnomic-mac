#!/bin/bash
# personal/defaults.sh — System Settings for Avi's own setup.
# Safe to re-run. User-level only (no sudo).

set -u

# Free Ctrl+Space for the drop-down terminal (and Ctrl+Opt+Space) from input-source switching   # VERIFY
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 "<dict><key>enabled</key><false/></dict>"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 61 "<dict><key>enabled</key><false/></dict>"

# iTerm2 reads its settings from personal/iterm2/ and saves changes made in
# its settings window straight back there, so tweaks made with the mouse
# land in the repo. Save mode 2 = automatically (0 = on quit, 1 = never).
ITERM_PREFS="$(cd "$(dirname "$0")" && pwd)/iterm2"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$ITERM_PREFS"
defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile -bool true
defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile_selection -int 2

###############################################################################
# Apply
###############################################################################
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null || true
echo "Done. Keyboard shortcut changes may need a logout/login."
