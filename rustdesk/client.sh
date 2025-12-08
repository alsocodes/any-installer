#!/bin/bash
set -e

# =======================
# RustDesk Client Installer
# Usage:
#   sudo sh install-rustdesk-client.sh <SERVER_IP> "<PUBLIC_KEY>"
# =======================

if [ -z "$1" ] || [ -z "$2" ]; then
    echo ""
    echo "❌ ERROR: Argumen kurang."
    echo "Cara pakai:"
    echo "  sudo sh $0 <SERVER_IP> \"<PUBLIC_KEY>\""
    echo ""
    exit 1
fi

SERVER_IP="$1"
PUBLIC_KEY="$2"

echo "====================================="
echo " Installing RustDesk Client (Auto Config)"
echo "====================================="
echo "Server IP   : $SERVER_IP"
echo "Public Key  : $PUBLIC_KEY"
echo ""

# --- Install dependencies ---
apt update
apt install -y curl wget

# --- Download RustDesk latest .deb ---
echo "[+] Downloading RustDesk..."
wget -O rustdesk.deb https://github.com/rustdesk/rustdesk/releases/latest/download/rustdesk.deb

echo "[+] Installing RustDesk..."
apt install ./rustdesk.deb -y
rm rustdesk.deb

# --- Create config directory ---
mkdir -p ~/.config/rustdesk

# --- Write configuration ---
echo "[+] Writing RustDesk config..."
cat > ~/.config/rustdesk/RustDesk2.toml <<EOF
rendezvous-server = "$SERVER_IP"
relay-server = "$SERVER_IP"
key = "$PUBLIC_KEY"
EOF

echo "[+] Config saved to ~/.config/rustdesk/RustDesk2.toml"

# --- Enable RustDesk system service ---
echo "[+] Enabling RustDesk background service..."
systemctl enable --now rustdesk || true

echo ""
echo "====================================="
echo " RustDesk client installed & configured!"
echo "-------------------------------------"
echo "ID Server   : $SERVER_IP"
echo "Relay Server: $SERVER_IP"
echo "Key         : (already applied)"
echo "====================================="
echo "Device ini kini bisa diremote via RustDesk."
