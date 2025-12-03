#!/bin/bash

set -e

VERSION="1.7.0"
ARCH="linux-amd64"
FILE="node_exporter-${VERSION}.${ARCH}.tar.gz"
URL="https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/${FILE}"

echo "===> Downloading Node Exporter v${VERSION}..."
cd /tmp
wget -q $URL

echo "===> Extracting..."
tar -xzf $FILE

echo "===> Installing binary..."
sudo mv "node_exporter-${VERSION}.${ARCH}/node_exporter" /usr/local/bin/
sudo chmod +x /usr/local/bin/node_exporter

echo "===> Creating systemd service..."
sudo tee /etc/systemd/system/node_exporter.service >/dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=nobody
Group=nogroup
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

echo "===> Reloading systemd & enabling service..."
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter

echo "===> Cleaning up..."
rm -rf "/tmp/node_exporter-${VERSION}.${ARCH}"*
echo "===> Done!"

echo "Node Exporter is running on port :9100"
systemctl status node_exporter --no-pager
