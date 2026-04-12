# wgsetup
quick setting for vps wg

start with 

wget https://raw.githubusercontent.com/ruitong23/wgsetup/main/wgsetup.sh

if no wget

apt update && apt install wget -y

then

chmod +x wgsetup.sh

./wgsetup.sh

if no internet check firewall

ufw disable

if can't run or no such file 

sed -i 's/\r$//' wgsetup.sh

then

./wgsetup.sh
