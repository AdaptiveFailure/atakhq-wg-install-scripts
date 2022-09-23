# Wireguard Install Scripts

This is a script package that will install wireguard for you on Ubuntu or CentOS7. 

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

Run `wgLocalMachineConfigDownloader.sh` from your local machine to download the config QR Code PNG's to scan and auto-create your connections on your client devices. 
