#!/bin/bash

#  Configurar reglas de firewall
ufw allow 1194/udp
ufw allow 22/tcp
ufw enable

#  Habilitar IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

#  Crear archivos de configuración para clientes
for i in {1..5}; do
  cat > /etc/openvpn/client/client$i.ovpn <<EOF
client
dev tun
proto udp
remote $(curl -s ifconfig.me) 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
verb 3
<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
<cert>
$(cat /etc/openvpn/easy-rsa/pki/issued/client$i.crt)
</cert>
<key>
$(cat /etc/openvpn/easy-rsa/pki/private/client$i.key)
</key>
EOF
done

# Comprimir configuraciones para descarga
apt install -y zip
zip /home/ubuntu/client-configs.zip /etc/openvpn/client/*.ovpn


echo "Configuración completada!"
echo "Descarga los archivos de configuración con:"
echo "scp -i tu-key.pem ubuntu@$(curl -s ifconfig.me):/home/ubuntu/client-configs.zip ."