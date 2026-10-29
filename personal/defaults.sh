#!/bin/bash
# personal/defaults.sh — System Settings for Avi's own setup.
# Safe to re-run. User-level only (no sudo).

set -u

# Free Ctrl+Space for Tabby (and Ctrl+Opt+Space) from input-source switching   # VERIFY
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 "<dict><key>enabled</key><false/></dict>"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 61 "<dict><key>enabled</key><false/></dict>"

###############################################################################
# Apply
###############################################################################
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null || true
echo "Done. Keyboard shortcut changes may need a logout/login."
