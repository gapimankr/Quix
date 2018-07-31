NONE='\033[00m'
RED='\033[01;91m'
GREEN='\033[01;32m'

echo "${RED}Installing required packages, done in 3 steps. ${NONE}";

echo "${RED}1. Installing swap file. ${NONE}";
#setup swap to make sure there's enough memory for compiling the daemon 
dd if=/dev/zero of=/mnt/myswap.swap bs=1M count=4000
mkswap /mnt/myswap.swap
chmod 0600 /mnt/myswap.swap
swapon /mnt/myswap.swap

echo "${RED}2. Installing dependencies. ${NONE}";
#download and install required packages
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt-get install software-properties-common curl -y
sudo apt-get install nano git -y
sudo apt-get install wget -y
sudo apt-get install curl -y
sudo apt-get install htop -y

sudo apt-get install build-essential libtool autotools-dev automake pkg-config libssl-dev software-properties-common autoconf -y
sudo apt-get install libgmp3-dev libevent-dev bsdmainutils libboost-all-dev -y
sudo apt-get install libzmq3-dev -y
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get update -y
sudo apt-get install libdb4.8-dev libdb4.8++-dev -y
sudo apt-get install libminiupnpc-dev -y

#get quix client from github, compile the client
echo "${RED}3. Installing Quix client. ${NONE}";
cd $HOME
sudo mkdir $HOME/quix
git clone https://github.com/quixcoin/quix.git quix
cd $HOME/quix
chmod 777 autogen.sh
./autogen.sh
./configure
chmod 777 share/genbuild.sh
sudo make
sudo make install

#setup config file for the masternode
sudo apt-get install pwgen -y

echo "${RED}Installation completed. ${NONE}";

#get masternode key from user
echo "${RED}Paste here your masternode key (right mouse click) and confirm with Enter ${NONE}";
read KEYM

sudo mkdir $HOME/.quixcore
PASSWORD=`pwgen -1 20 -n`
EXTIP=`wget -qO- ident.me`
printf "rpcuser=masternode\nrpcpassword=$PASSWORD\ndaemon=1\nlisten=1\nserver=1\nmaxconnections=512\nrpcallowip=127.0.0.1\nexternalip=$EXTIP:6333\nmasternode=1\nmasternodeprivkey=$KEYM\naddnode=185.243.113.89:6333\naddnode=95.179.158.178:6333\naddnode=23.95.215.20:6333\naddnode=133.130.88.165:6333\naddnode=91.121.209.225:6333\naddnode=149.28.125.160:6333\naddnode=185.205.210.16:6333\naddnode=51.15.125.144:6333\naddnode=199.247.4.7:6333\naddnode=167.99.91.99:6333\naddnode=80.240.28.128:6333\naddnode=185.206.145.27:6333\naddnode=144.202.68.62:6333\naddnode=172.94.14.155:6333" > /$HOME/.quixcore/quix.conf

#start the client and make sure it's synced before confirming completion
quixd --daemon
sleep 5

echo "${RED}Waiting for your Quix client to fully sync with the network, this can take a while. ${NONE}";
block=1
while true
do
	realblock=`quix-cli getblockcount` 
	echo "Block: $realblock" #write block
	if [ $realblock -eq $block ] #check block if is done
	then 
		sleep 60
		realblock=$((`quix-cli getblockcount`))
		if [ $realblock -eq $block ] #second check block if is done
		then 
			echo "${RED}Synced will be done in 4 steps. ${NONE}"
			break
		fi
	fi
	block=$((realblock))
	sleep 5	
done

echo "${RED}1. Blockchain sync start.${NONE}"
until quix-cli mnsync status | grep -m 1 '"IsBlockchainSynced": true'; do sleep 1 ; done > /dev/null 2>&1
echo "${GREEN}BlockchainSynced done. ${NONE}"

echo "${RED}2. Masternode List sync start.${NONE}"
until quix-cli mnsync status | grep -m 1 '"IsMasternodeListSynced": true'; do sleep 1 ; done > /dev/null 2>&1
echo "${GREEN}MasternodeListSynced done. ${NONE}"

echo "${RED}3. Winners List sync start.${NONE}"
until quix-cli mnsync status | grep -m 1 '"IsWinnersListSynced": true'; do sleep 1 ; done > /dev/null 2>&1
echo "${GREEN}WinnersListSynced done. ${NONE}"

echo "${RED}4. Sync start.${NONE}"
until quix-cli mnsync status | grep -m 1 '"IsSynced": true'; do sleep 1 ; done > /dev/null 2>&1
echo "${GREEN}Sync done. ${NONE}"

echo "${RED}Setting up your VPS is finish. You can now start MasterNode in your wallet. ${NONE}"; 

echo "${RED}Waiting that MasterNode start.${NONE}"
until quix-cli masternode status | grep -m 1 '"status": "Masternode successfully started"'; do sleep 1 ; done > /dev/null 2>&1
echo "${GREEN}Done! Masternode successfully started, now you can close connection and wait until in your wallet will write ENABLED.${NONE}"

echo ""
echo "If this guild help you, then you can sent me some tips ;)"
echo "QUIX QRfy36th8YXJwWQt627hQ5gNLU487uqTCJ"
echo "BTC 12nxh3nUTJHve3XGaXrh692xQZMVLJLFJm"
echo "DOGE DJbHoCkzwzqjyrJxT1hGwN1rzZdJFzBseG"
