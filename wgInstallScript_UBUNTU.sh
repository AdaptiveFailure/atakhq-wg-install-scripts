#WireGuard VPN Setup Script UBUNTU 

echo "WireGuard VPN Docker Setup Script UBUNTU" 
echo " " 
read -p "Press any key to begin ..." 

echo "What port do you want to use? (Defaults to 51820 if nothing entered)"
read PORTNUM

if [ -z "${PORTNUM}" ]; then 
    PORTNUM='51820'
else 
    PORTNUM=${PORTNUM}
fi

echo "Would you like to specify a DNS? (Defaults to 94.140.14.14 AdGuard DNS Server if nothing entered)"
read PEERDNS

if [ -z "${PEERDNS}" ]; then 
    PEERDNS='94.140.14.14'
else 
    PEERDNS=${PEERDNS}
fi

echo "What is your Timezone? (Defaults to America/New_York if nothing entered)"
read TZ

if [ -z "${TZ}" ]; then 
    TZ='America/New_York'
else 
    TZ=${TZ}
fi


echo "How many Clients do you want to configure? (Deafults to 5 if nothing entered)" 
read CLIENT_COUNT 
if [ -z "${CLIENT_COUNT}" ]; then 
    CLIENT_COUNT='5'
else 
    CLIENT_COUNT=${CLIENT_COUNT}
fi

#Create the docker-compose file
CCOUNT=""
for ((i=1;i<=$CLIENT_COUNT;i++)) 
	do 
		CCOUNT+=$i
		CCOUNT+=","
	done 
CCOUNT_INPUT=$(echo $CCOUNT | sed 's/,$//')
cd ~ 
mkdir wireguard 
cd wireguard/ 

sudo tee ~/wireguard/docker-compose.yml >/dev/null << EOF
---
version: "2.1"
services:
  wireguard:
    image: ghcr.io/linuxserver/wireguard
    container_name: wireguard
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=$TZ
      - SERVERPORT=$PORTNUM
      - PEERDNS=$PEERDNS
      - PEERS=$CCOUNT_INPUT
    volumes:
      - /path/to/appdata/config:/config
      - /lib/modules:/lib/modules
    ports:
      - $PORTNUM:$PORTNUM/udp
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
    restart: unless-stopped
EOF
	
docker-compose up -d

echo " " 
echo "********************************************************************" 
echo "Setup Script done, your WireGuard VPN Docker Service should now be running " 
echo "********************************************************************" 
echo " "
echo "********************************************************************" 
echo "Connect to your docker instance so you can grab your QR Codes for logins:"
echo "docker exec -it wireguard bash" 
echo " "
echo "Move to the app folder, and run the show peer script to display the QR code on the screen to scan in wireguard to make your connection:"
echo "cd /app"
echo "./show-peer 1"
echo " "
echo "********************************************************************" 
echo " "
echo "********************************************************************" 
echo "WARNING: IF YOU ARE USING THE CONFIG FILES FROM THE PEER FOLDERS INSTEAD OF THE QR CODES MAKE SURE TO EDIT ALLOWED IPs SO YOU DO NOT LEAK YOUR IP" 
echo "********************************************************************"
