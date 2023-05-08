#!/bin/bash

PORT=21778
RPCPORT=21777
CONF_DIR=~/.boco
COINZIP='https://github.com/bocodev/BOCO/releases/download/v1.0/boco-1.0.0-x86_64-linux-gnu.zip'

cd ~
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

function configure_systemd {
  cat << EOF > /etc/systemd/system/boco.service
[Unit]
Description=boco Service
After=network.target
[Service]
User=root
Group=root
Type=forking
ExecStart=/usr/local/bin/bocod
ExecStop=-/usr/local/bin/boco-cli stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  sleep 2
  systemctl enable boco.service
  systemctl start boco.service
}

echo ""
echo ""
DOSETUP="y"

if [ $DOSETUP = "y" ]  
then
  apt-get update
  apt install zip unzip git curl wget -y
  cd /usr/local/bin/
  wget $COINZIP
  unzip boco-1.0.0-x86_64-linux-gnu.zip
  rm boco-qt boco-tx boco-1.0.0-x86_64-linux-gnu.zip
  chmod +x boco*
  
  mkdir -p $CONF_DIR
  cd $CONF_DIR
  wget https://downloads.masternodes.biz/snapshots/boco.zip
  unzip boco.zip
  rm boco.zip

fi

 IP=$(curl -s4 api.ipify.org)
 echo ""
 echo "Configure your masternodes now!"
 echo "Detecting IP address:$IP"
 echo ""
 echo "Enter masternode private key"
 read PRIVKEY
 
  echo "rpcuser=user"`shuf -i 100000-10000000 -n 1` >> boco.conf_TEMP
  echo "rpcpassword=pass"`shuf -i 100000-10000000 -n 1` >> boco.conf_TEMP
  echo "rpcallowip=127.0.0.1" >> boco.conf_TEMP
  echo "rpcport=$RPCPORT" >> boco.conf_TEMP
  echo "listen=1" >> boco.conf_TEMP
  echo "server=1" >> boco.conf_TEMP
  echo "daemon=1" >> boco.conf_TEMP
  echo "maxconnections=250" >> boco.conf_TEMP
  echo "masternode=1" >> boco.conf_TEMP
  echo "" >> boco.conf_TEMP
  echo "port=$PORT" >> boco.conf_TEMP
  echo "externalip=$IP:$PORT" >> boco.conf_TEMP
  echo "masternodeaddr=$IP:$PORT" >> boco.conf_TEMP
  echo "masternodeprivkey=$PRIVKEY" >> boco.conf_TEMP
  mv boco.conf_TEMP boco.conf
  cd
  echo ""
  echo -e "Your ip is ${GREEN}$IP:$PORT${NC}"

	## Config Systemctl
	configure_systemd
  
echo ""
echo "Commands:"
echo -e "Start Boco Service: ${GREEN}systemctl start boco${NC}"
echo -e "Check Boco Status Service: ${GREEN}systemctl status boco${NC}"
echo -e "Stop Boco Service: ${GREEN}systemctl stop boco${NC}"
echo -e "Check Masternode Status: ${GREEN}boco-cli getmasternodestatus${NC}"

echo ""
echo -e "${GREEN}Boco Masternode Installation Done${NC}"
exec bash
exit
