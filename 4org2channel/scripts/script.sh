#!/bin/bash

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Build your first network (BYFN) end-to-end test"
echo
CHANNEL_NAME12="$1"
CHANNEL_NAME34="$2"
DELAY="$3"
LANGUAGE="$4"
TIMEOUT="$5"
: ${CHANNEL_NAME12:="channel12"}
: ${CHANNEL_NAME34:="channel34"}
: ${DELAY:="3"}
: ${LANGUAGE:="golang"}
: ${TIMEOUT:="10"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=5
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

#CC_SRC_PATH="github.com/chaincode/chaincode_example02/go/"
CC_SRC_PATH="github.com/chaincode/chaincode_example02/go/"
if [ "$LANGUAGE" = "node" ]; then
	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/node/"
fi

echo "Channel name : "${CHANNEL_NAME12} " and " ${CHANNEL_NAME34}

# import utils
. scripts/utils.sh

createChannel12() {
	setGlobals 0 1

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME12 -f ./channel-artifacts/channel12.tx >&log.txt
		res=$?
                set +x
	else
				set -x
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME12 -f ./channel-artifacts/channel12.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
				set +x
	fi
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel \"$CHANNEL_NAME12\" is created successfully ===================== "
	echo
}

createChannel34() {
	setGlobals 0 3 

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME34 -f ./channel-artifacts/channel34.tx >&log.txt
		res=$?
                set +x
	else
				set -x
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME34 -f ./channel-artifacts/channel34.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
				set +x
	fi
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel \"$CHANNEL_NAME34\" is created successfully ===================== "
	echo
}

joinChannel12 () {
	for org in 1 2; do
	    for peer in 0 1; do
		joinChannelWithRetry12 $peer $org
		echo "===================== peer${peer}.org${org} joined on the channel \"$CHANNEL_NAME12\" ===================== "
		sleep $DELAY
		echo
	    done
	done
}

joinChannel34 () {
	for org in 3 4; do
	    for peer in 0 1; do
		joinChannelWithRetry34 $peer $org
		echo "===================== peer${peer}.org${org} joined on the channel \"$CHANNEL_NAME34\" ===================== "
		sleep $DELAY
		echo
	    done
	done
}

## Create channel
echo "Creating channel..."
createChannel12
createChannel34

## Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel12
joinChannel34

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for org1..."
updateAnchorPeers12 0 1
echo "Updating anchor peers for org2..."
updateAnchorPeers12 0 2
echo "Updating anchor peers for org3..."
updateAnchorPeers34 0 3
echo "Updating anchor peers for org4..."
updateAnchorPeers34 0 4

## Install chaincode on peer0.org1 and peer0.org2
echo "Installing chaincode on peer0.org1..."
installChaincode12 0 1
echo "Install chaincode on peer1.org1..."
installChaincode12 1 1
echo "Installing chaincode on peer0.org2..."
installChaincode12 0 2
echo "Install chaincode on peer1.org2..."
installChaincode12 1 2
echo "Installing chaincode on peer0.org3..."
installChaincode34 0 3
echo "Install chaincode on peer1.org3..."
installChaincode34 1 3
echo "Installing chaincode on peer0.org4..."
installChaincode34 0 4
echo "Install chaincode on peer1.org4..."
installChaincode34 1 4

# Instantiate chaincode on peer0.org2
echo "Instantiating chaincode on peer0.org2..."
instantiateChaincode12 0 2

# Instantiate chaincode on peer0.org4
echo "Instantiating chaincode on peer0.org4..."
instantiateChaincode34 0 4

# Query chaincode on peer0.org1
echo "Querying chaincode on peer0.org1..."
chaincodeQuery12 0 1 100

# Invoke chaincode on peer0.org1
echo "Sending invoke transaction on peer0.org1..."
chaincodeInvoke12 0 1

# Query on chaincode on peer1.org2, check if the result is 90
echo "Querying chaincode on peer1.org2..."
chaincodeQuery12 1 2 90


# Query chaincode on peer0.org3
echo "Querying chaincode on peer0.org3..."
chaincodeQuery34 0 3 500

echo "Sending invoke transaction on peer0.org3..."
chaincodeInvoke34 0 3

# Query on chaincode on peer1.org4, check if the result is 450
echo "Querying chaincode on peer1.org4..."
chaincodeQuery34 1 4 450


echo
echo "========= All GOOD, BYFN execution completed =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
