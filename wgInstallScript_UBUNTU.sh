#WireGuard VPN Setup Script UBUNTU
echo "WireGuard VPN Setup Script UBUNTU"
echo "** YOU MUST RUN THIS SCRIPT AS ROOT USER **"
echo " "
read -p "Press any key to begin ..."

DEVICE_NAME=$(ip -o -4 route show to default | awk '{print $5}')
echo "FOUND DEVICE NAME: $DEVICE_NAME"

PUB_SERVER_IP=$(ip addr show enp3s0 | awk 'NR==3{print substr($2,1,(length($2)-3))}')
echo "FOUND SERVER IP: $PUB_SERVER_IP"

PUB_SERVER_GATEWAY_IP=$(ip route list table main default | awk '{print $3}')
echo "FOUND SERVER GATEWAY IP: $PUB_SERVER_GATEWAY_IP"


sudo apt-get update -y
sudo apt-get install wireguard  -y

#Make the server keys
cd /etc/wireguard
wg genkey | sudo tee /etc/wireguard/server_private.key | wg pubkey | sudo tee /etc/wireguard/server_public.key
SERVER_PRIV_KEY_PATH="/etc/wireguard/server_private.key"
SERVER_PUB_KEY_PATH="/etc/wireguard/server_public.key"

#Read the server keys
while read line; do
SERVER_PRIV_KEY=$line
done < $SERVER_PRIV_KEY_PATH

while read line; do
SERVER_PUB_KEY=$line
done < $SERVER_PUB_KEY_PATH

echo " "
echo " "

#Make the Client Keys
echo "How many clients do you want to configure?"
read CLIENT_COUNT
CLIENT_ARR=()
for ((i=1; i<=$CLIENT_COUNT;i++))

do
    CLIENT_IP=`expr $i + 1`
    echo "What is the username for client #$i?"
    read CLIENT_NAME
    echo "Creating certs for $CLIENT_NAME"
    wg genkey | sudo tee /etc/wireguard/${CLIENT_NAME}_private.key | wg pubkey | sudo tee /etc/wireguard/${CLIENT_NAME}_public.key
    #Read the server key

    #Read the Client Key
    NEWLINE=$'\n'
    CLIENT_PUB_KEY_PATH="/etc/wireguard/${CLIENT_NAME}_public.key"
    CLIENT_PRIV_KEY_PATH="/etc/wireguard/${CLIENT_NAME}_private.key"

    while read line; do
    CLIENT_PUB_KEY=$line
    done < $CLIENT_PUB_KEY_PATH

    while read line; do
    CLIENT_PRIV_KEY=$line
    done < $CLIENT_PRIV_KEY_PATH


    CLIENT_ARR+=("[Peer]
PublicKey = ${CLIENT_PUB_KEY}
AllowedIPs = 10.10.10.${CLIENT_IP}/32$NEWLINE")

#Create the client config file for connecting
sudo tee /etc/wireguard/wg-${CLIENT_NAME}.conf >/dev/null << EOF
[Interface]
Address = 10.10.10.${CLIENT_IP}/24
DNS = 10.10.10.1
PrivateKey = $CLIENT_PRIV_KEY
[Peer]
PublicKey = $SERVER_PUB_KEY
AllowedIPs = 0.0.0.0/0 
Endpoint = $PUB_SERVER_IP:51820
PersistentKeepalive = 25
EOF

 done   

#Secure Private keys
sudo chmod go= /etc/wireguard/private.key

#Create the server config file
sudo tee /etc/wireguard/wg0.conf >/dev/null << EOF
[Interface]
Address = 10.10.10.1/24
SaveConfig = true
PrivateKey = $SERVER_PRIV_KEY
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $DEVICE_NAME -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $DEVICE_NAME -j MASQUERADE

${CLIENT_ARR[*]}
EOF

#Cleanup some stupid spaces from the array insert
sudo sed -i 's/\s\[/\[/g' /etc/wireguard/wg0.conf 


#Enable IP Forwarding
sudo rm /etc/sysctl.conf
sudo tee /etc/sysctl.conf >/dev/null << EOF
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
EOF

#Load the new setup
sudo sysctl -p

#Open required ports
sudo ufw allow 51820/udp
sudo ufw allow OpenSSH
sudo ufw disable
sudo ufw enable

#Start the server
sudo systemctl enable wg-quick@wg0.service
sudo systemctl start wg-quick@wg0.service
echo $(sudo systemctl status wg-quick@wg0.service)
echo " "
echo "********************************************************************"
echo "Setup Script done, your WireGuard VPN Service should now be running (check status above should see a green dot and Active)"
echo "********************************************************************"
echo " "
echo "********************************************************************"
echo "All of your connection config files are located in /etc/wireguard/"
echo "********************************************************************"
echo " "
echo "********************************************************************"
echo "Please run the config file download script on your local machine to obtain the files to issue to your users"
echo "********************************************************************"
