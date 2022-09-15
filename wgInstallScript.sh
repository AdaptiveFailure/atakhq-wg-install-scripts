#WireGuard VPN Setup Script CentOs7
echo "WireGuard VPN Setup Script CentOs7"
echo "** YOU MUST RUN THIS SCRIPT AS ROOT USER **"
echo " "
read -p "Press any key to begin ..."

echo "What is your server IP address?"
read PUB_SERVER_IP

sudo yum install epel-release https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm -y
sudo yum install yum-plugin-elrepo -y
sudo yum install kmod-wireguard wireguard-tools -y
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
Address = 10.10.10.2/24
DNS = 10.10.10.1
PrivateKey = $CLIENT_PRIV_KEY

[Peer]
PublicKey = $SERVER_PUB_KEY
AllowedIPs = 0.0.0.0/0 
Endpoint = $PUB_SERVER_IP:51820
PersistentKeepalive = 25
EOF

 done   

#echo "${CLIENT_ARR[*]}"

#Create the server config file
sudo tee /etc/wireguard/wg0.conf >/dev/null << EOF
[Interface]
Address = 10.10.10.1/24
SaveConfig = true
PrivateKey = $SERVER_PRIV_KEY
ListenPort = 51820

${CLIENT_ARR[*]}
EOF

#Cleanup some stupid spaces from the array insert
sudo sed -i 's/\s\[/\[/g' /etc/wireguard/wg0.conf 

#Secure the directory
sudo chmod 600 /etc/wireguard/ -R

#Enable IP Forwarding
sudo systemctl start firewalld
sudo firewall-cmd --zone=public --permanent --add-masquerade
sudo systemctl reload firewalld

#Install a DNS Resolver on the Server
sudo yum install bind -y
sudo systemctl start named
sudo systemctl enable named
systemctl status named

sudo rm /etc/named.conf
sudo tee /etc/named.conf >/dev/null << EOF
options {
        directory	"/var/named";
        dump-file	"/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        recursing-file  "/var/named/data/named.recursing";
        secroots-file   "/var/named/data/named.secroots";
        allow-query     { localhost; 10.10.10.0/24; };

	recursion yes;

        dnssec-enable yes;
        dnssec-validation yes;

        /* Path to ISC DLV key */
        bindkeys-file "/etc/named.root.key";

        managed-keys-directory "/var/named/dynamic";

        pid-file "/run/named/named.pid";
        session-keyfile "/run/named/session.key";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
        type hint;
        file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
EOF

#Restart named for changes to take effect
sudo systemctl restart named

#Allow VPN Port 53
sudo firewall-cmd --zone=public --permanent --add-rich-rule='rule family="ipv4" source address="10.10.10.0/24" accept'

#Open WireGuard UDP port 51820 on the server.
sudo firewall-cmd --permanent --add-port=51820/udp
sudo systemctl reload firewalld

#Start the server
sudo systemctl start wg-quick@wg0.service
sudo systemctl enable wg-quick@wg0.service
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
