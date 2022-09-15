#wireguardCopyConfigFilesScript - this will copy your config files to local machine so you can connect to your VPN
echo " "
echo " "
echo "WireGuard VPN Setup Script Config Downloader"
echo " "

read -p "Press any key to begin downloading your config files ..."
echo " "
echo "Attempting to create local directory ~/atak/wireguard if it does not exist already"
echo " "
sudo mkdir ~/atak
sudo mkdir ~/atak/wireguard

echo " "
echo "What is your server IP address?"
read PUB_SERVER_IP

echo " "
echo "Connecting to Server...."

scp root@$PUB_SERVER_IP:/etc/wireguard/*.conf ~/atak/wireguard

cd ~/atak/wireguard
ls -al
echo " "
echo " "
echo "****************************************************************"
echo "Your config files have been downloaded, a list of them is above."
echo "****************************************************************"
echo " "
echo " "
