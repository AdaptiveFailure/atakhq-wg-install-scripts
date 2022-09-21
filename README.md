# Wireguard Install Scripts

This is a script package that will install wireguard for you inside a docker container on Ubuntu (non-docker for CentOS7). 

Also creates QR codes for easy connection.


1. SSH into your server as root

2. Install git if you do not have it installed already

`sudo yum install -y git` for centos7, ubuntu should have installed already.

3. Clone this repo to your server

`git clone https://github.com/atakhq/wg-install-scripts.git`

4. Move into the folder, make the script executable, run it

`cd wg-install-scripts`

`sudo chmod +x *`

`. wgInstallScript_CENTOS7.sh`

or

`. wgInstallScript_UBUNTU.sh`

## Post Install

Connect to your docker instance so you can grab your QR Codes for logins:

`docker exec -it wireguard bash`

Move to the app folder, and run the show peer script to display the QR code on the screen to scan in wireguard to make your connection:

`cd /app`

`./show-peer 1`
