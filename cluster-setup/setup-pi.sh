#!/bin/bash

set -e

# Validate input
if [[ "$EUID" -ne 0 ]]; then
  echo "Please run this script with sudo"
  exit 1
fi

# Recommend using screen
if [[ -z "$STY" ]]; then
  echo "Warning: It is recommended to run this script inside a 'screen' session to avoid disconnection issues (especially over SSH)."
fi

# Optional logging to file
LOGFILE="/var/log/first_setup_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -i "$LOGFILE")
exec 2>&1

# Update & Upgrade
echo "Updating and upgrading packages..."
apt update && apt upgrade -y

# Install packages
echo "Installing required packages..."
apt install -y curl wget net-tools iperf3

# Install Ookla speedtest CLI
echo "⚡ Installing speedtest CLI..."
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"
wget https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-aarch64.tgz
tar -xvzf ookla-speedtest-1.2.0-linux-aarch64.tgz
cp speedtest /usr/local/bin
chmod +x /usr/local/bin/speedtest
cd /
rm -rf "$TMP_DIR"

echo "Add some aliases"
# Some aliases for useful command
printf "\n\nwatch -n 2 vcgencmd measure_temp\n" >> $HOME/.bashrc

echo "First setup complete. Run 'network-setup.sh <IP_ADDRESS> <ethernet|wifi> [SSID] [PASSWORD]' next."