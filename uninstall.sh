#!/bin/bash
set -euo pipefail

BIN_DIR="$HOME/.local/bin"
LOG_DIR="$HOME/.local/var/log"
CONFIG_DIR="$HOME/.config/vpn-split"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_NAME="com.adrianso.vpn-split"
SUDOERS_FILE="/etc/sudoers.d/vpn-split"

echo "Uninstalling vpn-split..."

# Unload daemon
launchctl unload "$PLIST_DIR/$PLIST_NAME.plist" 2>/dev/null || true
echo "  Unloaded launchd agent"

# Remove files
rm -f "$PLIST_DIR/$PLIST_NAME.plist"
echo "  Removed plist"

rm -f "$BIN_DIR/vpn-split"
echo "  Removed script"

rm -f "$LOG_DIR/vpn-split.log"
echo "  Removed log"

rm -rf "$CONFIG_DIR"
echo "  Removed config"

# Remove sudoers entry
if [[ -f "$SUDOERS_FILE" ]]; then
  echo "  Removing sudoers entry (requires sudo)..."
  sudo rm -f "$SUDOERS_FILE"
  echo "  Removed $SUDOERS_FILE"
fi

echo ""
echo "Done. vpn-split fully removed."
