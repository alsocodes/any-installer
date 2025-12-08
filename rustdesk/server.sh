#!/bin/bash
set -e

echo "===== RustDesk Server Auto Installer ====="
PUBLIC_IP=$(curl -s ifconfig.me || echo "0.0.0.0")
echo "Detected public IP: $PUBLIC_IP"

apt update
apt install -y build-essential pkg-config libssl-dev libclang-dev curl unzip ufw

mkdir -p /var/lib/rustdesk
cd /var/lib/rustdesk

echo "Fetching latest RustDesk release..."
LATEST=$(curl -s https://api.github.com/repos/rustdesk/rustdesk-server/releases/latest \
  | grep browser_download_url \
  | grep linux-amd64.zip \
  | cut -d '"' -f 4)

if [[ -n "$LATEST" ]]; then
    DOWNLOAD_URL="$LATEST"
else
    echo "API failed — using fallback version 1.1.14"
    DOWNLOAD_URL="https://github.com/rustdesk/rustdesk-server/releases/download/1.1.14/rustdesk-server-linux-amd64.zip"
fi

echo "Downloading RustDesk..."
wget -O rustdesk-server.zip "$DOWNLOAD_URL"

echo "Extracting..."
unzip -o rustdesk-server.zip
rm rustdesk-server.zip

# --- FIX: detect real folder (amd64/) ---
if [[ -d "amd64" ]]; then
    BIN_DIR="amd64"
else
    echo "ERROR: Folder amd64 tidak ditemukan!"
    ls -lah
    exit 1
fi

cp "$BIN_DIR/hbbs" /usr/local/bin/
cp "$BIN_DIR/hbbr" /usr/local/bin/
chmod +x /usr/local/bin/hbbs /usr/local/bin/hbbr

echo "Generating keys..."
/usr/local/bin/hbbs -g || true

# ---------- FIX PUBLIC KEY ----------
KEY_PATH="/var/lib/rustdesk/.config/rustdesk/id_ed25519.pub"

if [[ ! -f "$KEY_PATH" ]]; then
    echo "Key belum muncul, regenerate..."
    /usr/local/bin/hbbs -g || true
fi

if [[ ! -f "$KEY_PATH" ]]; then
    echo "❌ ERROR: Key still not found!"
    echo "Expected at: $KEY_PATH"
    exit 1
fi

echo "Copying key to /var/lib/rustdesk/"
cp /var/lib/rustdesk/.config/rustdesk/id_ed25519 /var/lib/rustdesk/
cp /var/lib/rustdesk/.config/rustdesk/id_ed25519.pub /var/lib/rustdesk/

# -------------------------------------

echo ""
echo "===== INSTALLATION COMPLETE ====="
echo "ID Server : $PUBLIC_IP"
echo "Relay     : $PUBLIC_IP"
echo ""
echo "Public Key:"
cat /var/lib/rustdesk/id_ed25519.pub
echo ""
echo "Paste key ke RustDesk client → Settings → ID/Relay Server"
echo "========================================================="
