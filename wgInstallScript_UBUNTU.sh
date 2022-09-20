#WireGuard VPN Setup Script UBUNTU
echo "WireGuard VPN Setup Script UBUNTU"
echo "** YOU MUST RUN THIS SCRIPT AS ROOT USER **"
echo " "
read -p "Press any key to begin ..."

echo "What is your server IP address?"
read PUB_SERVER_IP

echo "What is your server Gateway IP address? (same IP as before except last octet is 1)"
read PUB_SERVER_GATEWAY_IP

echo "What is the name of your ethernet device? (run this command to find out: 'ip route list table main default')"
read DEVICE_NAME

sudo apt-get update -y
sudo apt-get install wireguard wireguard-tools -y
sudo mkdir -p /etc/wireguard/

#Make the server private keys
cd /etc/wireguard
wg genkey | sudo tee /etc/wireguard/server_private.key | wg pubkey | sudo tee /etc/wireguard/server_public.key
sudo mkdir -p /etc/wireguard/

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
PostUp = ufw route allow in on wg0 out on $DEVICE_NAME
PostUp = iptables -t nat -I POSTROUTING -o $DEVICE_NAME -j MASQUERADE
PostUp = ip6tables -t nat -I POSTROUTING -o $DEVICE_NAME -j MASQUERADE
PreDown = ufw route delete allow in on wg0 out on $DEVICE_NAME
PreDown = iptables -t nat -D POSTROUTING -o $DEVICE_NAME -j MASQUERADE
PreDown = ip6tables -t nat -D POSTROUTING -o $DEVICE_NAME -j MASQUERADE
PostUp = ip rule add table 200 from $PUB_SERVER_IP
PostUp = ip route add table 200 default via $PUB_SERVER_GATEWAY_IP
PreDown = ip rule delete table 200 from $PUB_SERVER_IP
PreDown = ip route delete table 200 default via $PUB_SERVER_GATEWAY_IP
PrivateKey = $SERVER_PRIV_KEY
ListenPort = 51820
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
sudo systemctl status wg-quick@wg0.service
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
