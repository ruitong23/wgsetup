# wgsetup quick setting for vps wg

1. start with 

wget https://raw.githubusercontent.com/ruitong23/wgsetup/main/wgsetup.sh

2. if no wget

apt update && apt install wget -y

3. then

chmod +x wgsetup.sh

./wgsetup.sh

check 

if no internet check firewall

ufw disable

if can't run or no such file 

sed -i 's/\r$//' wgsetup.sh

then

./wgsetup.sh
