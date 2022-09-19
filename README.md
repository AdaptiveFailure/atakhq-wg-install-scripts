# wg-install-scripts

This is a script package that will install wireguard for you on a centos7 or ubuntu server and walk you through the entire process, prompting your for user creation so your don't have to manually create certs one by one.


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

5. Copy the config file downloader script to your local machine and run it

`git clone https://github.com/atakhq/wg-install-scripts.git`

`cd wg-centos7-install-scripts`

`sudo chmod +x *`

`. wgLocalMachineConfigDownloader.sh`

6. You now have the config files locally and can connect with the wireguard app after you import the config file and create a connection.
