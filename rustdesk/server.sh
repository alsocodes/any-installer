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

# Auto detect folder
if [[ -f "hbbs" && -f "hbbr" ]]; then
    SRC_PATH="."
elif [[ -f "amd64/hbbs" && -f "amd64/hbbr" ]]; then
    SRC_PATH="amd64"
else
    echo "❗ ERROR: hbbs/hbbr not found in extracted archive!"
    exit 1
fi

echo "Using binary path: $SRC_PATH"
cp "$SRC_PATH/hbbs" /usr/local/bin/
cp "$SRC_PATH/hbbr" /usr/local/bin/
chmod +x /usr/local/bin/hbbs /usr/local/bin/hbbr

rm rustdesk-server.zip

echo "Generating keys..."
/usr/local/bin/hbbs -g 2>/dev/null || true

echo "Creating HBBS service..."
cat >/etc/systemd/system/hbbs.service <<EOF
[Unit]
Description=RustDesk HBBS Service
After=network.target

[Service]
ExecStart=/usr/local/bin/hbbs -k /var/lib/rustdesk/id_ed25519 -r $PUBLIC_IP:21117
WorkingDirectory=/var/lib/rustdesk
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

echo "Creating HBBR service..."
cat >/etc/systemd/system/hbbr.service <<EOF
[Unit]
Description=RustDesk HBBR Relay Service
After=network.target

[Service]
ExecStart=/usr/local/bin/hbbr -k /var/lib/rustdesk/id_ed25519
WorkingDirectory=/var/lib/rustdesk
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now hbbs
systemctl enable --now hbbr

ufw allow 21114 || true
ufw allow 21115 || true
ufw allow 21116 || true
ufw allow 21117 || true

echo "===== INSTALLATION DONE ====="
echo "ID / Relay Server: $PUBLIC_IP"
echo "Public Key:"
cat /var/lib/rustdesk/id_ed25519.pub
