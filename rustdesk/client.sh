#!/bin/bash
set -e

# =======================
# RustDesk Client Installer
# =======================

if [ -z "$SERVER_IP" ] || [ -z "$SERVER_KEY" ]; then
    echo "❌ ERROR: Variabel lingkungan tidak ada."
    echo ""
    echo "Cara pakai:"
    echo "SERVER_IP=\"1.2.3.4\" SERVER_KEY=\"PUB_KEY\" \\"
    echo "  curl -sSL https://raw.githubusercontent.com/alsocodes/any-installer/main/rustdesk/client.sh | bash"
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
