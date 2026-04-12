# wgsetup
quick setting for vps wg

start with 

wget https://raw.githubusercontent.com/ruitong23/wgsetup/main/wgsetup.sh

if no wget

apt update && apt install wget -y

then

chmod +x wgsetup.sh
./wgsetup.sh

check firewall

ufw disable
