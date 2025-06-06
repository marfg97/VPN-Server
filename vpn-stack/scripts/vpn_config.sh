#!/bin/bash

# ===================================================
# VPN Server Setup Script for AWS EC2 (Ubuntu 22.04)
# OpenVPN + Easy-RSA (Elliptic Curve Keys)
# ===================================================

# 0. Root check
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Run this script as root or with sudo!" >&2
  exit 1
fi

# Variables
VPN_PORT="1194"
VPN_PROTOCOL="udp"
VPN_NETWORK="10.8.0.0"
VPN_NETMASK="255.255.255.0"
CLIENTS=5
DNS1="8.8.8.8"
DNS2="8.8.4.4"

# Get EC2 public IP and DNS
SERVER_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
SERVER_DNS=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)

# 1. Update and install
echo "🔄 Installing dependencies..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y && apt-get upgrade -y
apt-get install -y openvpn easy-rsa ufw curl unzip

# 2. Easy-RSA setup
echo "🔐 Setting up Easy-RSA..."
mkdir -p /etc/openvpn/easy-rsa
cp -r /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/
cd /etc/openvpn/easy-rsa

cat > vars <<EOF
set_var EASYRSA_ALGO ec
set_var EASYRSA_CURVE secp384r1
set_var EASYRSA_DIGEST "sha384"
EOF

./easyrsa init-pki
echo -ne "\n" | ./easyrsa build-ca nopass
./easyrsa gen-dh
./easyrsa build-server-full server nopass

for i in $(seq 1 $CLIENTS); do
  ./easyrsa build-client-full client$i nopass
done

openvpn --genkey --secret pki/ta.key

# 3. Move server certs
echo "📁 Moving certs to OpenVPN..."
cp pki/ca.crt pki/private/server.key pki/issued/server.crt pki/dh.pem pki/ta.key /etc/openvpn/

# 4. Server configuration
echo "🔧 Creating OpenVPN server config..."
cat > /etc/openvpn/server.conf <<EOF
port $VPN_PORT
proto $VPN_PROTOCOL
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
server $VPN_NETWORK $VPN_NETMASK
topology subnet
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS $DNS1"
push "dhcp-option DNS $DNS2"
keepalive 10 120
tls-auth ta.key 0
key-direction 0
cipher AES-256-GCM
auth SHA384
user nobody
group nogroup
persist-key
persist-tun
status /var/log/openvpn-status.log
log-append /var/log/openvpn.log
verb 3
explicit-exit-notify 1
sndbuf 393216
rcvbuf 393216
push "sndbuf 393216"
push "rcvbuf 393216"
tls-server
EOF

# 5. Enable IP forwarding
echo "📶 Enabling IP forwarding..."
sed -i 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p > /dev/null

echo "🌐 Adding iptables NAT rule for VPN..."
iptables -t nat -A POSTROUTING -s $VPN_NETWORK/24 -o ens5 -j MASQUERADE
# 6. Configure UFW
echo "🔥 Setting firewall rules..."
ufw allow $VPN_PORT/$VPN_PROTOCOL
ufw allow OpenSSH
sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
echo '
*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s '"$VPN_NETWORK"'/24 -o ens5 -j MASQUERADE
COMMIT
' >> /etc/ufw/before.rules
ufw --force enable

# 7. Client configuration files
echo "👥 Generating .ovpn files..."
CLIENT_DIR="/home/ubuntu/vpn-clients"
mkdir -p $CLIENT_DIR

for i in $(seq 1 $CLIENTS); do
cat > $CLIENT_DIR/client$i.ovpn <<EOF
client
dev tun
proto $VPN_PROTOCOL
remote $SERVER_DNS $VPN_PORT
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
auth SHA384
key-direction 1
<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
<cert>
$(cat /etc/openvpn/easy-rsa/pki/issued/client$i.crt)
</cert>
<key>
$(cat /etc/openvpn/easy-rsa/pki/private/client$i.key)
</key>
<tls-auth>
$(cat /etc/openvpn/ta.key)
</tls-auth>
EOF
done

chown -R ubuntu:ubuntu $CLIENT_DIR

# 8. Enable and start OpenVPN
echo "🚀 Enabling OpenVPN service..."
systemctl enable openvpn@server
systemctl start openvpn@server

# 9. Output summary
echo "==================================================="
echo "✅ OpenVPN server setup complete!"
echo "==================================================="
echo "🔐 Client .ovpn files saved in: $CLIENT_DIR"
echo "📥 To download them:"
echo "scp -i your-key.pem ubuntu@$SERVER_DNS:$CLIENT_DIR/client*.ovpn ."
echo "==================================================="
