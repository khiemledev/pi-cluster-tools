#!/bin/bash

set -e

# Validate input
if [[ "$EUID" -ne 0 ]]; then
  echo "Please run this script with sudo"
  exit 1
fi

if [[ $# -lt 2 ]]; then
  echo "Usage: sudo $0 <IP_ADDRESS> <ethernet|wifi> [SSID] [PASSWORD]"
  exit 1
fi

# Optional logging to file
LOGFILE="/var/log/net_setup_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -i "$LOGFILE")
exec 2>&1

IP_ADDR="$1"
MODE="$2"
SSID="$3"
PASSWORD="$4"
NETPLAN_FILE="/etc/netplan/50-cloud-init.yaml"
BACKUP_FILE="${NETPLAN_FILE}.backup"

# Backup netplan config
echo "Backing up ${NETPLAN_FILE} to ${BACKUP_FILE}..."
cp "$NETPLAN_FILE" "$BACKUP_FILE"

# Generate netplan config
echo "Generating new netplan config..."

if [[ "$MODE" == "ethernet" ]]; then
cat > "$NETPLAN_FILE" <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses:
        [$IP_ADDR/24]
      routes:
        - to: 0.0.0.0/0
          via: 192.168.0.1
      nameservers:
        search: [local]
        addresses: [1.1.1.1, 1.0.0.1, 8.8.8.8, 8.8.4.4, 208.67.222.222, 208.67.220.220]
      dhcp6: false
      dhcp4: false
EOF

elif [[ "$MODE" == "wifi" ]]; then
  if [[ -z "$SSID" || -z "$PASSWORD" ]]; then
    echo "SSID and PASSWORD are required for wifi mode"
    exit 1
  fi

  PSK=$(wpa_passphrase "$SSID" "$PASSWORD" | grep psk= | tail -n1 | cut -d= -f2)

cat > "$NETPLAN_FILE" <<EOF
network:
  version: 2
  renderer: networkd
  wifis:
    wlan0:
      access-points:
        "$SSID":
          auth:
            key-management: "psk"
            password: "$PSK"
      addresses:
        [$IP_ADDR/24]
      routes:
        - to: 0.0.0.0/0
          via: 192.168.0.1
      nameservers:
        search: [local]
        addresses: [1.1.1.1, 1.0.0.1, 8.8.8.8, 8.8.4.4, 208.67.222.222, 208.67.220.220]
      dhcp6: false
      dhcp4: false
EOF

else
  echo "Invalid mode: $MODE. Use 'ethernet' or 'wifi'."
  exit 1
fi

# Apply netplan
echo "Applying netplan..."
netplan apply

echo "Network setup complete."
