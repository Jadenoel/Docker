#!/bin/bash

# Start your Besu network
/usr/local/bin/startBesu.sh &

# Wait for the network to be ready
/usr/local/bin/wait-for-network.sh "127.0.0.1" "8545" ""

# Wait for an additional 1 minute to ensure the Besu blockchain is fully booted up
echo "Waiting for 2 minutes to ensure the Besu blockchain is fully booted up..."
sleep 120

# Perform the contract migration
cd /besu/besu-23.10.2/bin/IBFT-Network/
echo "Starting contract migration..."
npx truffle migrate --reset --network besu --config truffle_config.js

# Make the contract addresses available for the API 
node -e "
const fs = require('fs');
const path = require('path');
const MPContract = require('/besu/besu-23.10.2/bin/IBFT-Network/build/contracts/Marketplace.json');
const QLContract = require('/besu/besu-23.10.2/bin/IBFT-Network/build/contracts/QualityLabel.json');
const CPContract = require('/besu/besu-23.10.2/bin/IBFT-Network/build/contracts/CommunityProperties.json');
const networkId = Object.keys(MPContract.networks)[0]; // Assumes all contracts are deployed on the same network
const config = {
  MPaddress: MPContract.networks[1337].address,
  QLaddress: QLContract.networks[1337].address,
  CPaddress: CPContract.networks[1337].address
};
fs.writeFileSync('./config.json', JSON.stringify(config, null, 2), 'utf8');
"

node api.js &

# Keep the container running (if needed)
tail -f /dev/null
