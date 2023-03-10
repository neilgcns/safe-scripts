#!/usr/bin/env bash

if [[ $SAFE_PORT == "" ]]; then
SAFE_PORT=1200
fi
GB_ALLOCATED=5
CLI_TIMEOUT=500

COMPILE_FROM_SOURCE=1

declare -i NODE_NUMBER
NODE_NUMBER=15

LOCAL_NODE=0

export NEWT_COLORS='
window=,white
border=black,white
textbox=black,white
button=black,white
'
PATH=$PATH:/$HOME/.safe/cli:/$HOME/.cargo/bin:/$HOME/.cargo

####################################################### first time the sript is run install dependancys and exit so as to update env
if [ -e $HOME/.cargo/bin/installed ]
then
    echo "script previously run"

else

########## welcome message
whiptail --title "********************** SAFE NODE INSTALLER  *****************************************" --msgbox "\n
This script will install everything needed to join the SAFE network testnets for Ubuntu like machines\n
The programs lised below will be installed if required. Your root password will be required.\n
 - git                    -protocal for pulling source code
 - curl                   -fetches the SAFE applications
 - sn_cli                 -the SAFE client program
 - safe_network           -the SAFE network functionality
 - moreutils              -to idenntify your network settings
 - build-essential        -required to build vdash on top of rust
 - rust                   -Rust is a systems programming lanuage
 - vdash                  -vdash is a to monitor your SAFE node
                                                 by @happybeing\n
Any existing SAFE installation will be DELETED" 25 70

if [[ $? -eq 255 ]]; then
exit 0
fi

fi

############################################## select test net provider

TEST_NET_SELECTION=$(whiptail --title "Testnet Selection" --radiolist \
"Testnet providers" 20 70 10 \
"1" "Official test" OFF \
"2" "Local Baby Fleming" OFF \
"3" "Comnet by           @josh             " ON \
"4" "Custom Testnet" OFF  3>&1 1>&2 2>&3)

if [[ $? -eq 255 ]]; then
exit 0
fi
if [[ $? -eq 255 ]]; then
exit 0
fi

if [[ "$TEST_NET_SELECTION" == "1" ]]; then
SAFENET=officialtestnet
CONFIG_URL=place_holder
elif [[ "$TEST_NET_SELECTION" == "2" ]]; then
SAFENET=baby-fleming
CONFIG_URL=n/a
elif [[ "$TEST_NET_SELECTION" == "3" ]]; then
SAFENET=comnet
CONFIG_URL=https://sn-comnet.s3.eu-west-2.amazonaws.com/comnet-network-contacts
elif [[ "$TEST_NET_SELECTION" == "4" ]]; then
SAFENET=Custom
CONFIG_URL=$(whiptail --title "Custom Testnet" --inputbox "Enter test network name" 8 40 3>&1 1>&2 2>&3)
fi

############################################## Add OFFICIAL Test net name

if [[ $SAFENET == "officialtestnet"  ]]; then
SAFENET=$(whiptail --title "Test Net Name" --inputbox "Enter test name" 8 40 3>&1 1>&2 2>&3)
CONFIG_URL=https://sn-node.s3.eu-west-2.amazonaws.com/testnet_tool/$SAFENET/network-contacts

if [[ $? -eq 255 ]]; then
exit 0
fi
fi


############################################## select if node should be started

if [[ $SAFENET != "baby-fleming"  ]]; then
LOCAL_NODE=$(whiptail --title "Local Node" --radiolist \
"Testnet providers" 20 70 10 \
"1" "Dont start Local node     " ON \
"2" "Start local node" OFF 3>&1 1>&2 2>&3)

if [[ $? -eq 255 ]]; then
exit 0
fi
fi

############################################## if live testnet set size and port

if [[ $LOCAL_NODE == "2" ]]; then
if [[ "$SAFENET" != "baby-fleming"  ]]; then
whiptail --title "Node Settings/n" --yesno "Procede with node defaults ?\n
Port $SAFE_PORT
Size $GB_ALLOCATED Gb\n\n
Press Enter to procede or Esc for custom values" 16 70 

if [[ $? -eq 255 ]]; then 
SAFE_PORT=$(whiptail --title "Custom Port" --inputbox "\nEnter Port Number" 8 40 $SAFE_PORT 3>&1 1>&2 2>&3)
GB_ALLOCATED=$(whiptail --title "Custom Size" --inputbox "\nEnter Size in GB" 8 40 $GB_ALLOCATED 3>&1 1>&2 2>&3)
fi 
fi
fi

############################################## if local baby fleming set size and node count

if [[ "$SAFENET" == "baby-fleming" ]]; then
whiptail --title "Node Settings/n" --yesno "Procede with node defaults ?\n
Size $GB_ALLOCATED Gb
Number of Nodes $NODE_NUMBER\n\n
when vdash launches use left and right to cycle through nodes\n\n
Press Enter to procede or Esc for custom values" 16 70

if [[ $? -eq 255 ]]; then
NODE_NUMBER=$(whiptail --title "Number of Nodes" --inputbox "\nEnter number of nodes" 8 40 $NODE_NUMBER 3>&1 1>&2 2>&3)
GB_ALLOCATED=$(whiptail --title "Custom Size" --inputbox "\nEnter Size in GB" 8 40 $GB_ALLOCATED 3>&1 1>&2 2>&3)
fi
fi

############################################## select if use release from git hub or compile from source

COMPILE_FROM_SOURCE=$(whiptail --title "Binary selection" --radiolist \
"Testnet providers" 20 70 10 \
"1" "Latest release from Github     " ON \
"2" "Compile from Source" OFF 3>&1 1>&2 2>&3)

if [[ $? -eq 255 ]]; then
exit 0
fi

############################################## set up variables

ACTIVE_IF=$( ( cd /sys/class/net || exit; echo *)|awk '{print $1;}')
LOCAL_IP=$(echo $(ifdata -pa "$ACTIVE_IF"))
PUBLIC_IP=$(echo $(curl -s ifconfig.me))
SAFE_PORT=$SAFE_PORT
VAULT_SIZE=$((1024*1024*1024*$GB_ALLOCATED))
LOG_DIR=$HOME/.safe/node/local_node
export SN_CLI_QUERY_TIMEOUT=$CLI_TIMEOUT

############################################## install dependancys and rust if this is first time script has been run

if [ -e $HOME/.cargo/bin/installed ]
then
    echo "script previously run"

else

clear
sudo apt -qq update
sudo apt -qq install -y snapd build-essential moreutils
sudo apt -qq install curl -y
sudo apt -qq install git -y
sudo snap remove rustup
curl https://sh.rustup.rs -sSf | sh -s -- -y
sudo apt -qq install cargo -y
clear

touch $HOME/.cargo/bin/installed

fi

##### upgrade already installed

sudo apt update
sudo apt upgrade -y
rustup update

############################################## stop any running nodes and clear out old files
/usr/local/bin/safe node killall &> /dev/null
sudo systemctl stop sn_node.service
rm -rf "$HOME"/.safe

############################################## install safe network and node
curl -so- https://raw.githubusercontent.com/maidsafe/safe_network/main/resources/scripts/install.sh | sudo bash
safe node install

cargo install vdash
############################################## compile from sourse if selected
if [[ "$COMPILE_FROM_SOURCE" == "2" ]]; then

mkdir -p $HOME/.safe/github-tmp
mkdir -p $HOME/.safe/node
git clone https://github.com/maidsafe/safe_network.git $HOME/.safe/github-tmp/
#git clone --branch Handover https://github.com/maidsafe/safe_network $HOME/.safe/github-tmp/

cd $HOME/.safe/github-tmp
source $HOME/.cargo/env
cargo build --release
sudo rm /usr/local/bin/safe
sudo cp $HOME/.safe/github-tmp/target/release/safe /usr/local/bin/
rm $HOME/.safe/node/sn_node
cp $HOME/.safe/github-tmp/target/release/sn_node $HOME/.safe/node/
fi

############################################## start safe network without local node
if [[ $LOCAL_NODE == 1 ]]; then

sleep 1
safe networks add $SAFENET $CONFIG_URL
sleep 1
safe networks switch $SAFENET
sleep 1
6

# generate keys for cli
/usr/local/bin/safe keys create --for-cli

############################################## start safe network local babay fleming

elif [[ "$SAFENET" == "baby-fleming" ]]; then

mkdir -p $HOME/.safe/node/baby-fleming-nodes

# --skip-auto-port-forwarding\

RUST_LOG=sn_node=trace,qp2p=info\
 nohup $HOME/.safe/node/sn_node -vv\
 --local-addr 127.0.0.1:0\
 --first\
 --root-dir $HOME/.safe/node/baby-fleming-nodes/sn-node-genesis\
 --log-dir $HOME/.safe/node/baby-fleming-nodes/sn-node-genesis 2>&1 > /dev/null & disown

echo Genesis node started

sleep 10
/usr/local/bin/safe networks add baby-fleming $HOME/.safe/node/baby-fleming-nodes/sn-node-genesis/section_tree
sleep 1
/usr/local/bin/safe networks switch baby-fleming
sleep 1

# generate keys for cli
/usr/local/bin/safe keys create --for-cli

LOG_FILES="$HOME/.safe/node/baby-fleming-nodes/sn-node-genesis/sn_node.log "


for (( c=1; c<=$NODE_NUMBER; c++ ))
do

# --skip-auto-port-forwarding \

RUST_LOG=sn_node=trace,qp2p=info\
 nohup $HOME/.safe/node/sn_node -vv \
 --local-addr 127.0.0.1:0 \
 --root-dir $HOME/.safe/node/baby-fleming-nodes/sn-node-$c \
 --log-dir $HOME/.safe/node/baby-fleming-nodes/sn-node-$c \
 --network-contacts-file $HOME/.safe/network_contacts/default 2>&1 > /dev/null & disown

export LOG_FILES="$LOG_FILES $HOME/.safe/node/baby-fleming-nodes/sn-node-$c/sn_node.log "
echo Node $c started
sleep 10

done

# generate wallet
WALLET=$(safe wallet create | grep -o -P '(?<=").*(?=\")')
echo $WALLET > ~/.safe/wallet
echo wallet generated
sleep 2

############################################## start safe network with node live network

else

sleep 1
wget $CONFIG_URL -O $HOME/.safe/$SAFENET
safe networks add $SAFENET $HOME/.safe/$SAFENET
sleep 1
safe networks switch $SAFENET
sleep 5

# generate keys for cli
/usr/local/bin/safe keys create --for-cli


# generate wallet
WALLET=$(safe wallet create | grep -o -P '(?<=").*(?=\")')
echo $WALLET > ~/.safe/wallet
echo wallet generated
sleep 2

# RUST_LOG=sn_node=trace,qp2p=info \
# --public-addr "$PUBLIC_IP":$SAFE_PORT \
# --skip-auto-port-forwarding \


echo -n "#!/bin/bash

	$HOME/.safe/node/sn_node \
	--local-addr "$LOCAL_IP":$SAFE_PORT \
	--log-dir "$LOG_DIR" \
	--network-contacts-file "$HOME/.safe/$SAFENET" & disown" \
	--wallet-id $WALLET \
| tee $HOME/.safe/node/start-node.sh &> /dev/null

chmod u+x $HOME/.safe/node/start-node.sh

echo -n "[Unit]
Description=Safe Node
[Service]
User=$USER
ExecStart=/home/$USER/.safe/node/start-node.sh
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target"\
|sudo tee /etc/systemd/system/sn_node.service &> /dev/null

sudo systemctl start sn_node.service

export LOG_FILES=$LOG_DIR/sn_node.log

sleep 3

fi


# make script to start vdash with relavant log files
echo -n "#!/bin/bash
vdash $LOG_FILES" \
| tee $HOME/.cargo/bin/vdash.sh &> /dev/null

chmod u+x $HOME/.cargo/bin/vdash.sh

vdash.sh
