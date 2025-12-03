#!/bin/bash

set -e

ENV_FILE="/etc/frp/.env"

echo "=== Installing FRPC ==="

# ================================
#  Load ENV
# ================================
if [[ -f "$ENV_FILE" ]]; then
    echo "Loading environment variables from $ENV_FILE"
    source "$ENV_FILE"
else
    echo "ERROR: $ENV_FILE not found!"
    echo "Please create it first:"
    echo ""
    echo "SERVER_IP=xx.xx.xx.xx"
    echo "SERVER_PORT=7000"
    echo "TOKEN=your_secret"
    echo "SSH_NAME=avod1"
    echo "SSH_LOCALPORT=22"
    echo "SSH_REMOTEPORT=6211"
    echo "EXP_NAME=nodeexp1"
    echo "EXP_LOCALPORT=9100"
    echo "EXP_REMOTEPORT=6212"
    exit 1
fi

sudo mkdir -p /etc/frp
cd /etc/frp

# ================================
# Install FRPC
# ================================
if ! command -v frpc >/dev/null 2>&1; then
    echo "Downloading FRPC..."
    wget -qO frpc.tar.gz https://github.com/fatedier/frp/releases/download/v0.60.0/frp_0.60.0_linux_amd64.tar.gz
    tar -xzf frpc.tar.gz
    sudo cp frp_0.60.0_linux_amd64/frpc /usr/local/bin/
    sudo chmod +x /usr/local/bin/frpc
fi

echo "FRPC installed."

# ================================
# Build frpc.toml from ENV values
# ================================
cat <<EOF | sudo tee /etc/frp/frpc.toml >/dev/null
[common]
server_addr = "$SERVER_IP"
server_port = $SERVER_PORT
token = "$TOKEN"
tls_enable = true
login_fail_exit = false

# SSH Tunnel
[$SSH_NAME]
type = "tcp"
local_ip = "127.0.0.1"
local_port = $SSH_LOCALPORT
remote_port = $SSH_REMOTEPORT

# Node Exporter Tunnel
[$EXP_NAME]
type = "tcp"
local_ip = "127.0.0.1"
local_port = $EXP_LOCALPORT
remote_port = $EXP_REMOTEPORT
EOF

echo "frpc.toml created."

# ================================
# systemd service
# ================================
cat <<EOF | sudo tee /etc/systemd/system/frpc.service >/dev/null
[Unit]
Description=FRP Client Service
After=network.target

[Service]
ExecStart=/usr/local/bin/frpc -c /etc/frp/frpc.toml
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable frpc
sudo systemctl restart frpc

echo "FRPC service started."
echo "=== INSTALL DONE ==="
