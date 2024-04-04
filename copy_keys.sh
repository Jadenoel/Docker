#!/bin/bash

# Initialize a counter
counter=1

# Loop through each subdirectory in networkFiles/keys
for keydir in /besu/besu-23.10.2/bin/IBFT-Network/networkFiles/keys/*; do
  # Check if the counter is less than or equal to 4
  if [ $counter -le 4 ]; then
    # Copy the key and key.pub to the respective node's data directory
    cp "${keydir}/key" "/besu/besu-23.10.2/bin/IBFT-Network/node${counter}/data/"
    cp "${keydir}/key.pub" "/besu/besu-23.10.2/bin/IBFT-Network/node${counter}/data/"
  fi
  # Increment the counter
  ((counter++))
done