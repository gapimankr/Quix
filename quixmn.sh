NONE='\033[00m'
RED='\033[01;91m'
GREEN='\033[01;32m'

echo "${RED}Installing required packages, done in 3 steps. ${NONE}";

echo "${RED}1. Do you like install swap file? (y) or (n) ${NONE}";
read SWAPQ
if [ $SWAPQ = 'y' ] || [ $SWAPQ = 'Y' ]
	then
		#setup swap to make sure there's enough memory for compiling the daemon 
		dd if=/dev/zero of=/mnt/myswap.swap bs=1M count=4000
		mkswap /mnt/myswap.swap
		chmod 0600 /mnt/myswap.swap
		swapon /mnt/myswap.swap
		echo "/mnt/myswap.swap    none    swap    sw    0   0" >> /etc/fstab
fi

echo "${RED}2. Do you like install dependencies and updates? (y) or (n) ${NONE}";
read DATAQ
if [ $DATAQ = 'y' ] || [ $DATAQ = 'Y' ]
	then
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
		sudo apt-get install pwgen -y
fi

#get quix client from github, compile the client
echo "${RED}3. How do you like install client? Download wallet from GitHub *Quicker, BUT use only of last wallet version is 0.12.1.1 (d) or Compiling wallet (c). (d) or (c) ${NONE}";
read INSTALLQ

cd $HOME
if [ $INSTALLQ = 'd' ] || [ $INSTALLQ = 'D' ]
	then
		sudo mkdir $HOME/wallet_quix && cd wallet_quix
		wget https://github.com/quixcoin/quix/releases/download/0.12.1.1/QUIX_LINUX.tar.gz
		tar -xvf QUIX_LINUX.tar.gz && rm QUIX_LINUX.tar.gz && cd QUIX_LINUX
		chmod +x quix* && mv quix* /usr/local/bin && cd $HOME
		rm -r wallet_quix
		quixd --daemon
		sleep 60
		killall quixd
elif [ $INSTALLQ = 'c' ] || [ $INSTALLQ = 'C' ]
	then
	sudo mkdir $HOME/quix
	git clone https://github.com/quixcoin/quix.git quix
	cd $HOME/quix
	chmod 777 autogen.sh
	./autogen.sh
	./configure
	chmod 777 share/genbuild.sh
	sudo make
	sudo make install	
	sudo mkdir $HOME/.quixcore
fi

#setup config file for the masternode
echo "${RED}Installation completed. ${NONE}";

#get masternode key from user
echo "${RED}Paste here your masternode key (right mouse click) and confirm with Enter ${NONE}";
read KEYM

PASSWORD=`pwgen -1 20 -n`
EXTIP=`wget -qO- ident.me`

echo "rpcuser=masternode"             > /$HOME/.quixcore/quix.conf
echo "rpcpassword=$PASSWORD"         >> /$HOME/.quixcore/quix.conf
echo "rpcallowip=127.0.0.1"          >> /$HOME/.quixcore/quix.conf
echo "maxconnections=500"            >> /$HOME/.quixcore/quix.conf
echo "daemon=1"                      >> /$HOME/.quixcore/quix.conf
echo "server=1"                      >> /$HOME/.quixcore/quix.conf
echo "listen=1"                      >> /$HOME/.quixcore/quix.conf
echo "rpcport=6334"                  >> /$HOME/.quixcore/quix.conf
echo "externalip=$EXTIP:6333"        >> /$HOME/.quixcore/quix.conf
echo "masternodeprivkey=$KEYM"       >> /$HOME/.quixcore/quix.conf
echo "masternode=1"                  >> /$HOME/.quixcore/quix.conf
echo " "                             >> /$HOME/.quixcore/quix.conf
echo "addnode=185.243.113.89:6333"   >> /$HOME/.quixcore/quix.conf
echo "addnode=95.179.158.178:6333"   >> /$HOME/.quixcore/quix.conf
echo "addnode=23.95.215.20:6333"     >> /$HOME/.quixcore/quix.conf
echo "addnode=133.130.88.165:6333"   >> /$HOME/.quixcore/quix.conf
echo "addnode=91.121.209.225:6333"   >> /$HOME/.quixcore/quix.conf
echo "addnode=149.28.125.160:6333"   >> /$HOME/.quixcore/quix.conf
echo "addnode=185.205.210.16:6333"   >> /$HOME/.quixcore/quix.conf
echo "addnode=51.15.125.144:6333"    >> /$HOME/.quixcore/quix.conf
echo "addnode=144.202.68.62:6333"    >> /$HOME/.quixcore/quix.conf
echo "addnode=172.94.14.155:6333"    >> /$HOME/.quixcore/quix.conf

#start the client and make sure it's synced before confirming completion
quixd --daemon
sleep 30

echo "${RED}Waiting for your Quix client to fully sync with the network, this can take a while. ${NONE}";
block=1
while true
do
	realblock=`quix-cli getblockcount` 
	printf "\rBlock: $realblock" #write block
	if [ $realblock -eq $block ] #check block if is done
	then 
		sleep 60
		realblock=$((`quix-cli getblockcount`))
		if [ $realblock -eq $block ] #second check block if is done
		then 
			echo ""
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
