#!/bin/bash

set -e

host="$1"
port="$2"
cmd="$3"

# Timeout in seconds
timeout=1200
wait_time=0
sleep_interval=30

echo "Waiting for Besu node at $host:$port to become available..."

while ! curl -s http://$host:$port; do
  if [ $wait_time -ge $timeout ]; then
    echo "Timeout waiting for Besu node at $host:$port"
    exit 1
  fi

  echo "Node not available yet, waiting $sleep_interval seconds..."
  sleep $sleep_interval
  wait_time=$(($wait_time+$sleep_interval))
done

echo "Besu node is up and running at $host:$port!"

# Execute the migration command
eval $cmd

