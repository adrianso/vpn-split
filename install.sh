#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$HOME/.local/bin"
LOG_DIR="$HOME/.local/var/log"
CONFIG_DIR="$HOME/.config/vpn-split"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_NAME="com.adrianso.vpn-split"

# Prompt for target host
EXISTING_HOST=""
if [[ -f "$CONFIG_DIR/config" ]]; then
  EXISTING_HOST=$(grep -E '^HOST=' "$CONFIG_DIR/config" | cut -d= -f2- || true)
fi

if [[ -n "$EXISTING_HOST" ]]; then
  read -rp "Hostname to route through VPN [$EXISTING_HOST]: " TARGET_HOST
  TARGET_HOST="${TARGET_HOST:-$EXISTING_HOST}"
else
  read -rp "Hostname to route through VPN: " TARGET_HOST
fi

if [[ -z "$TARGET_HOST" ]]; then
  echo "ERROR: hostname is required"
  exit 1
fi

echo ""
echo "Installing vpn-split for $USER (target: $TARGET_HOST)..."

# Unload existing daemon if running
launchctl unload "$PLIST_DIR/$PLIST_NAME.plist" 2>/dev/null || true

# Save config
mkdir -p "$CONFIG_DIR"
echo "HOST=$TARGET_HOST" > "$CONFIG_DIR/config"
echo "  Saved config to $CONFIG_DIR/config"

# Copy script
mkdir -p "$BIN_DIR"
cp "$SCRIPT_DIR/vpn-split" "$BIN_DIR/vpn-split"
chmod +x "$BIN_DIR/vpn-split"
echo "  Installed $BIN_DIR/vpn-split"

# Create log dir
mkdir -p "$LOG_DIR"

# Generate and install plist from template
mkdir -p "$PLIST_DIR"
sed "s|__HOME__|$HOME|g" "$SCRIPT_DIR/$PLIST_NAME.plist.template" > "$PLIST_DIR/$PLIST_NAME.plist"
echo "  Installed $PLIST_DIR/$PLIST_NAME.plist"

# Sudoers entry for passwordless route
SUDOERS_FILE="/etc/sudoers.d/vpn-split"
if [[ ! -f "$SUDOERS_FILE" ]]; then
  echo "  Creating sudoers entry (requires sudo)..."
  echo "$USER ALL=(root) NOPASSWD: /sbin/route" | sudo tee "$SUDOERS_FILE" > /dev/null
  sudo chmod 440 "$SUDOERS_FILE"
  sudo visudo -cf "$SUDOERS_FILE"
  echo "  Created $SUDOERS_FILE"
else
  echo "  $SUDOERS_FILE already exists, skipping"
fi

# Load daemon
launchctl load "$PLIST_DIR/$PLIST_NAME.plist"
echo "  Loaded launchd agent"

echo ""
echo "Done. vpn-split is running. Check logs at:"
echo "  tail -f $LOG_DIR/vpn-split.log"
