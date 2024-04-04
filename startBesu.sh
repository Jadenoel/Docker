#!/bin/bash

# Start node 1
/besu/besu-23.10.2/bin/besu --data-path=node1/data --genesis-file=/besu/besu-23.10.2/bin/IBFT-Network/genesis.json --rpc-http-enabled \
  --rpc-http-api=ADMIN,ETH,NET,IBFT,WEB3,TXPOOL --host-allowlist="*" \
  --rpc-http-cors-origins="all" --rpc-http-host=0.0.0.0 --rpc-http-port=8545 \
  --min-gas-price=0 &


# Wait for the node to start by checking if port 8545 is open
echo "Waiting for Besu node to start..."
while ! nc -z localhost 8545; do   
  sleep 1 # wait for 1 second before checking again
done
echo "Besu node started."


# Get enode url and export it for other nodes to use
# Initialize ENODE_URL
ENODE_URL=""

# Attempt to fetch ENODE_URL with retries
MAX_RETRIES=5
RETRY_COUNT=0
while [[ -z "$ENODE_URL" && $RETRY_COUNT -lt $MAX_RETRIES ]]; do
  echo "Attempting to fetch ENODE URL (Attempt $((RETRY_COUNT+1))/$MAX_RETRIES)..."
  ENODE_URL=$(curl -s -X POST --data '{"jsonrpc":"2.0","method":"admin_nodeInfo","params":[],"id":1}' -H "Content-Type: application/json" http://127.0.0.1:8545 | jq -r '.result.enode')
  if [[ "$ENODE_URL" == "null" || -z "$ENODE_URL" ]]; then
    ENODE_URL=""
    echo "Failed to fetch ENODE URL, retrying in 5 seconds..."
    sleep 5
  fi
  RETRY_COUNT=$((RETRY_COUNT+1))
done

if [[ -z "$ENODE_URL" ]]; then
  echo "Failed to fetch ENODE URL after $MAX_RETRIES attempts, exiting."
  exit 1
fi

echo "ENODE URL fetched successfully: $ENODE_URL"

# Start other nodes with the enode url of the first node
/besu/besu-23.10.2/bin/besu --data-path=node2/data --genesis-file=/besu/besu-23.10.2/bin/IBFT-Network/genesis.json --bootnodes=$ENODE_URL \
  --p2p-port=30304 --rpc-http-enabled \
  --rpc-http-api=ADMIN,ETH,NET,IBFT,WEB3,TXPOOL --host-allowlist="*" \
  --rpc-http-cors-origins="all" --rpc-http-host=0.0.0.0 --rpc-http-port=8546 \
  --min-gas-price=0 &

/besu/besu-23.10.2/bin/besu --data-path=node3/data --genesis-file=/besu/besu-23.10.2/bin/IBFT-Network/genesis.json --bootnodes=$ENODE_URL \
  --p2p-port=30305 --rpc-http-enabled \
  --rpc-http-api=ADMIN,ETH,NET,IBFT,WEB3,TXPOOL --host-allowlist="*" \
  --rpc-http-cors-origins="all" --rpc-http-host=0.0.0.0 --rpc-http-port=8547 \
  --min-gas-price=0 &


# Keep the script running
wait
