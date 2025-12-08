#!/bin/bash
set -e

echo "===== RustDesk Server Auto Installer (HBBS + HBBR) ====="
echo "Detecting public IP..."
PUBLIC_IP=$(curl -s ifconfig.me || echo "0.0.0.0")
echo "Detected IP: $PUBLIC_IP"
echo ""

echo "===== Installing dependencies ====="
apt update
apt install -y build-essential pkg-config libssl-dev libclang-dev curl unzip ufw

echo ""
echo "===== Preparing directories ====="
mkdir -p /var/lib/rustdesk
cd /var/lib/rustdesk

echo ""
echo "===== Fetching RustDesk latest version... ====="
LATEST=$(curl -s https://api.github.com/repos/rustdesk/rustdesk-server/releases/latest \
    | grep browser_download_url \
    | grep linux-x64 \
    | cut -d '"' -f 4)

if [[ -n "$LATEST" ]]; then
    echo "Latest version found:"
    echo "$LATEST"
    DOWNLOAD_URL="$LATEST"
else
    echo "❗ Gagal mendapatkan versi terbaru dari GitHub API."
    echo "Menggunakan fallback versi stabil 1.1.10..."
    # DOWNLOAD_URL="https://github.com/rustdesk/rustdesk-server/releases/download/1.1.10/rustdesk-server-linux-x64.zip"
    DOWNLOAD_URL="https://github.com/rustdesk/rustdesk-server/releases/download/1.1.14/rustdesk-server-linux-amd64.zip"
fi

echo ""
echo "===== Downloading RustDesk Server ====="
wget -O rustdesk-server.zip "$DOWNLOAD_URL"
unzip -o rustdesk-server.zip
mv hbbs hbbr /usr/local/bin/
chmod +x /usr/local/bin/hbbs /usr/local/bin/hbbr
rm rustdesk-server.zip

echo ""
echo "===== Generating encryption keys ====="
/usr/local/bin/hbbs -g 2>/dev/null || true

echo ""
echo "===== Creating systemd service: HBBS ====="
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

echo "===== Creating systemd service: HBBR ====="
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

echo ""
echo "===== Enabling & starting services ====="
systemctl daemon-reload
systemctl enable --now hbbs
systemctl enable --now hbbr

echo ""
echo "===== Opening firewall ====="
ufw allow 21114 || true
ufw allow 21115 || true
ufw allow 21116 || true
ufw allow 21117 || true

echo ""
echo "===== INSTALLATION COMPLETE ====="
echo "Public IP     : $PUBLIC_IP"
echo "HBBS Status   : $(systemctl is-active hbbs)"
echo "HBBR Status   : $(systemctl is-active hbbr)"
echo ""
echo "===== CLIENT CONFIG ====="
echo "ID Server     : $PUBLIC_IP"
echo "Relay Server  : $PUBLIC_IP"
echo ""
echo "Public Key:"
cat /var/lib/rustdesk/id_ed25519.pub
echo ""
echo "Masukkan key di atas ke RustDesk client (Settings → ID/Relay Server)."
echo "========================================================="
