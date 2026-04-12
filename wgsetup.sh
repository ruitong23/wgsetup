#!/bin/bash

set -e

echo "=== WireGuard Auto Setup (3 Clients) ==="

apt update -y
apt install -y wireguard curl iptables qrencode

INTERFACE=$(ip route | awk '/default/ {print $5; exit}')
if [ -z "$INTERFACE" ]; then
  echo "ERROR: Could not detect default network interface."
  exit 1
fi

SERVER_IP=$(curl -4 -s ifconfig.me || true)
if [ -z "$SERVER_IP" ]; then
  SERVER_IP=$(curl -4 -s ipinfo.io/ip || true)
fi
if [ -z "$SERVER_IP" ]; then
  echo "ERROR: Could not detect public IPv4."
  exit 1
fi

echo "Detected interface: $INTERFACE"
echo "Detected public IP: $SERVER_IP"

mkdir -p /etc/wireguard
chmod 700 /etc/wireguard
cd /etc/wireguard

wg genkey | tee server_private.key | wg pubkey > server_public.key
SERVER_PRIVATE=$(cat server_private.key)
SERVER_PUBLIC=$(cat server_public.key)

for i in 1 2 3; do
  wg genkey | tee client${i}_private.key | wg pubkey > client${i}_public.key
done

CLIENT1_PRIVATE=$(cat client1_private.key)
CLIENT1_PUBLIC=$(cat client1_public.key)

CLIENT2_PRIVATE=$(cat client2_private.key)
CLIENT2_PUBLIC=$(cat client2_public.key)

CLIENT3_PRIVATE=$(cat client3_private.key)
CLIENT3_PUBLIC=$(cat client3_public.key)

cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
PrivateKey = $SERVER_PRIVATE
Address = 10.0.0.1/24
ListenPort = 51820

PostUp = sysctl -w net.ipv4.ip_forward=1
PostUp = iptables -t nat -A POSTROUTING -o $INTERFACE -j MASQUERADE
PostUp = iptables -A FORWARD -i wg0 -o $INTERFACE -j ACCEPT
PostUp = iptables -A FORWARD -i $INTERFACE -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT

PostDown = iptables -t nat -D POSTROUTING -o $INTERFACE -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -o $INTERFACE -j ACCEPT
PostDown = iptables -D FORWARD -i $INTERFACE -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT

[Peer]
PublicKey = $CLIENT1_PUBLIC
AllowedIPs = 10.0.0.2/32

[Peer]
PublicKey = $CLIENT2_PUBLIC
AllowedIPs = 10.0.0.3/32

[Peer]
PublicKey = $CLIENT3_PUBLIC
AllowedIPs = 10.0.0.4/32
EOF

chmod 600 /etc/wireguard/wg0.conf

if grep -q '^net.ipv4.ip_forward=' /etc/sysctl.conf; then
  sed -i 's/^net.ipv4.ip_forward=.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf
else
  echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
fi
sysctl -p >/dev/null

wg-quick down wg0 2>/dev/null || true

iptables -t nat -F
iptables -F FORWARD

wg-quick up wg0
systemctl enable wg-quick@wg0 >/dev/null 2>&1 || true

echo ""
echo "=== SERVER READY ==="
echo "WireGuard interface: wg0"
echo "Public IP: $SERVER_IP"
echo "Port: 51820"
echo "Interface: $INTERFACE"
echo ""

show_client_config() {
  local NUM="$1"
  local PRIV="$2"
  local ADDR="$3"

  echo "Press Enter to show client $NUM config..."
  read

  CONFIG=$(cat <<EOF
[Interface]
PrivateKey = $PRIV
Address = $ADDR/24
DNS = 1.1.1.1

[Peer]
PublicKey = $SERVER_PUBLIC
Endpoint = $SERVER_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
)

  echo ""
  echo "========== CLIENT $NUM CONFIG START =========="
  echo ""
  echo "$CONFIG"
  echo ""
  echo "========== CLIENT $NUM CONFIG END =========="
  echo ""

  echo "Scan this QR with WireGuard mobile app:"
  echo ""

  qrencode -t ANSIUTF8 <<< "$CONFIG"

  echo ""
  echo "============================================="
  echo ""
  echo "Copy the config above for desktop, or scan the QR for phone."
  echo ""
}

show_client_config 1 "$CLIENT1_PRIVATE" "10.0.0.2"
show_client_config 2 "$CLIENT2_PRIVATE" "10.0.0.3"
show_client_config 3 "$CLIENT3_PRIVATE" "10.0.0.4"

echo "=== ALL DONE ==="