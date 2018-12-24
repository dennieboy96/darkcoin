#!/bin/bash
#sectie menu om te kiezen tussen het verwijderen of toevoegen van een omgeving.
PS3='Welkom terug, wat wilt u vandaag doen?: '
options=("Nieuwse server aanmaken" "Nieuwe Masternode Uitrollen" "Masternodes starten" "Masternodes updaten" "Turn SWAP on" "Turn SWAP off")
select opt in "${options[@]}"
do
V61=2
GATE=1
#het bekijken welke omgeving er weggegooit moet worden.
	case $opt in
		"Nieuwse server aanmaken")
			echo "Put in IPv6 address without the last digit. Like this: 2a01:7c8:d000:3cc::"
				read IPVNET
			echo "IPv6 netmask"
				read NETMASK
			echo "Masternode server genkey"
				read MNGENKEY
			echo "How many masternodes will be on this server?"
				read AMMAS
			wget https://raw.githubusercontent.com/DarkPayCoin/releases/master/dpc_mn_install.sh
			sed -i "s|read -e COINKEY|COINKEY=$MNGENKEY|g" dpc_mn_install.sh
			bash dpc_mn_install.sh
			sed -i '/iface ens3 inet6 auto/d' /etc/network/interfaces
			echo -e "\niface ens3 inet6 static \n \t address $IPVNET$V61 \n \t netmask $NETMASK \n \t gateway $IPVNET$GATE \n \t dns-nameservers 2001:19f0:300:1704::6" >> /etc/network/interfaces

			for (( i = 1; i <= $AMMAS; i++ ))
				do
				echo -e "\t \t up ip -6 addr add $IPVNET$i/$NETMASK dev ens3 \n \t \t down ip -6 addr add $IPVNET$i/$NETMASK dev ens3" >> /etc/network/interfaces
				done
					
			ifdown ens3
			ifup --ignore-errors ens3
			cd /root
			mkdir .darkpaycoin-template && chmod 775 .darkpaycoin-template
			cp .darkpaycoin/darkpaycoin.conf .darkpaycoin-template/
			sed -i '/rpcport=*/d; /masternodeaddr=/d; /masternodeprivkey=/d; /bind=/d;' /root/.darkpaycoin-template/darkpaycoin.conf
			sed -i "s/daemon=0/daemon=1/g" /root/.darkpaycoin-template/darkpaycoin.conf
			rm -rf /root/blocks /root/chainstate 
			rm /root/dpc_fastsync.zip
			rm /dpc_mn_install.sh
	break
exit
;;

		"Nieuwe Masternode Uitrollen")
			echo "nmmr"
				read MASTERNODE
			echo "Wat is het IPv6 adres van de masternode?"
				read IPADDRESS
			echo "Voer hier de genkey in van de masternode"
				read PRIVATEKEY

			cp /root/darkpaycoind /root/darkpaycoind$MASTERNODE
			cp -R /root/.darkpaycoin-template/ /root/.darkpaycoin$MASTERNODE
			chmod 775 /root/.darkpaycoin$MASTERNODE
			echo "bind=[$IPADDRESS]" >> /root/.darkpaycoin$MASTERNODE/darkpaycoin.conf
			echo "rpcport=100$MASTERNODE" >> /root/.darkpaycoin$MASTERNODE/darkpaycoin.conf
			echo "masternodeaddr=[$IPADDRESS:6667]" >> /root/.darkpaycoin$MASTERNODE/darkpaycoin.conf
			echo "masternodeprivkey=$PRIVATEKEY" >> /root/.darkpaycoin$MASTERNODE/darkpaycoin.conf
			rm -rf /root/.darkpaycoin$MASTERNODE/blocks
			rm -rf /root/.darkpaycoin$MASTERNODE/chainstate
			cp -R /root/.darkpaycoin/blocks/ /root/.darkpaycoin$MASTERNODE/blocks
			cp -R /root/.darkpaycoin/chainstate/ /root/.darkpaycoin$MASTERNODE/chainstate
			cp -R /root/.darkpaycoin/peers.dat /root/.darkpaycoin$MASTERNODE/peers.dat
			/root/./darkpaycoind$MASTERNODE --datadir=/root/.darkpaycoin$MASTERNODE/
			sleep 5
			tail -f /root/.darkpaycoin$MASTERNODE/debug.log
	break
exit
;;
		"Masternodes starten")
			echo "Masternode nummer van"
				read NMBR1
			echo "tot"
				read NMBR2
			 for (( i = $NMBR1; i <= $NMBR2; i++ ))			
			do
				echo "Starting node nr: $i"
				/root/darkpaycoind$i --datadir=/root/.darkpaycoin$i/
			done
	break
exit
;;
		"Masternodes updaten")
		       echo "Masternode nummer van"
                                read NMBRUP1
                        echo "tot"
                                read NMBRUP2

			if [ -d "/root/update" ]; then
				echo "download fastsync update"
				cd /root/update
				wget -N -q https://darkpaycoin.io/utils/dpc_fastsync.zip
				unzip -u dpc_fastsync.zip
				cd ..
			else
				echo "update directory maken"
				mkdir /root/update
				cd /root/update
				echo "download update"
				wget -N -q https://darkpaycoin.io/utils/dpc_fastsync.zip
				unzip -u dpc_fastsync.zip
				cd ..
			fi

			for (( i = $NMBRUP1; i <= $NMBRUP2; i++ ))
			do
				echo "Start updating daemon nr: $i"
			   systemctl stop darkpaycoin$i.service
			   rm -Rf /root/.darkpaycoin$i/blocks/
			   rm -Rf /root/.darkpaycoin$i/chainstate/
			   rm -Rf /root/.darkpaycoin$i/peers.dat
			   cp -R /root/update/blocks/ /root/.darkpaycoin$i/blocks/
			   cp -R /root/update/chainstate/ /root/.darkpaycoin$i/chainstate/
			   cp /root/update/peers.dat /root/.darkpaycoin$i/peers.dat
			   /root/darkpaycoind$i --datadir=/root/.darkpaycoin$i/
			   echo "Done updating masternode nr: $i, wait 60sec to start-up"
			   sleep 60
			done
	break
exit
;;
		"Turn SWAP on")
			echo "How big does the SWAP need to be give a number in GB?"
                                read SWAP1
			fallocate -l "$SWAP1"g /mnt/"$SWAP1"GiB.swap
			chmod 600 /mnt/"$SWAP1"GiB.swap
			mkswap /mnt/"$SWAP1"GiB.swap
			swapon /mnt/"$SWAP1"GiB.swap
			echo "/mnt/"$SWAP1"GiB.swap swap swap defaults 0 0" | sudo tee -a /etc/fstab
			echo "SWAP creation completed."
	break
exit
;;
                "Turn SWAP off")
                        echo "Are you sure to turn ALL the SWAP off? Y or N"
                                read SWAPOFF1
			case $SWAPOFF1 in
				Y|y)
			swapoff -a
			rm -f /mnt/*GiB.swap
			sed -i '/GiB.swap/d' /etc/fstab
			
;;
esac	
			case $SWAPOFF1 in
				N|n)
			exit
			;;
			esac


	break
exit
;;

esac
done

