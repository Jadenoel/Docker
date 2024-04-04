FROM ubuntu:20.04

# Set environment variables to non-interactive (to avoid timezone prompt)
ENV DEBIAN_FRONTEND=noninteractive

# Install prerequisites for adding NodeSource repository
RUN apt-get update && apt-get install -y ca-certificates curl gnupg \
  && mkdir -p /etc/apt/keyrings \
  && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

# Add the NodeSource repository for Node.js 20.x
RUN NODE_MAJOR=20 \
  && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
  && apt-get update

# Install Node.js from NodeSource
RUN apt-get install -y nodejs



# Install necessary packages
RUN apt-get install -y wget unzip software-properties-common
 
RUN npm install -g solc truffle 

# Add the Eclipse Temurin (Adoptium) repository
RUN wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | apt-key add - && \
    echo "deb https://packages.adoptium.net/artifactory/deb $(. /etc/os-release; echo "$UBUNTU_CODENAME") main" | tee /etc/apt/sources.list.d/adoptium.list

# Install Eclipse Temurin JDK 17
RUN apt-get update && apt-get install -y temurin-17-jdk

# Dynamically find the JDK installation directory and set JAVA_HOME
RUN echo "JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))" >> /etc/environment && \
    . /etc/environment

# Verify Java Installation
RUN java -version

# Download and unzip Besu
RUN wget https://hyperledger.jfrog.io/artifactory/besu-binaries/besu/23.10.2/besu-23.10.2.zip \
  && unzip besu-23.10.2.zip -d /besu \
  && rm besu-23.10.2.zip

RUN apt-get update && apt-get install -y jq netcat

# Set the working directory to where the besu binary is located
WORKDIR /besu/besu-23.10.2/bin

RUN chmod +x besu

RUN npm install @openzeppelin/contracts

# Create the directories for the IBFT network and individual nodes
RUN mkdir -p /besu/besu-23.10.2/bin/IBFT-Network/node1/data
RUN mkdir -p /besu/besu-23.10.2/bin/IBFT-Network/node2/data
RUN mkdir -p /besu/besu-23.10.2/bin/IBFT-Network/node3/data
RUN mkdir -p /besu/besu-23.10.2/bin/IBFT-Network/node4/data

# Copy the configuration files to the container
COPY ibftConfigFile.json /besu/besu-23.10.2/bin/IBFT-Network/
COPY truffle_config.js /besu/besu-23.10.2/bin/IBFT-Network/
COPY ./API/api.js . /besu/besu-23.10.2/bin/IBFT-Network/

# Initialize the blockchain configuration
RUN ./besu operator generate-blockchain-config --config-file=/besu/besu-23.10.2/bin/IBFT-Network/ibftConfigFile.json --to=/besu/besu-23.10.2/bin/IBFT-Network/networkFiles --private-key-file-name=key

# Copy the script to copy keys to the container
COPY copy_keys.sh /besu/copy_keys.sh
RUN chmod +x /besu/copy_keys.sh

# Execute the script to dynamically copy the keys to the corresponding node directories
RUN /besu/copy_keys.sh

WORKDIR /besu/besu-23.10.2/bin/IBFT-Network

RUN npm install @truffle/hdwallet-provider web3 cors express axios

# Copy the genesis file to the IBFT-Network directory
RUN cp ./networkFiles/genesis.json .

# Copy the startup script to the container
COPY startBesu.sh /usr/local/bin/startBesu.sh
RUN chmod +x /usr/local/bin/startBesu.sh

# Copy the startup script into the image
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh

# Copy the wait-for-network script 
COPY wait-for-network.sh /usr/local/bin/wait-for-network.sh
RUN chmod +x /usr/local/bin/wait-for-network.sh

# Truffle initialization and contract deployment
RUN truffle init
COPY ./contracts /besu/besu-23.10.2/bin/IBFT-Network/contracts
COPY ./migrations /besu/besu-23.10.2/bin/IBFT-Network/migrations

# Expose ports for the nodes
EXPOSE 8545-8548 30303-30306 20100


# Set the startup script as the entry point or command
ENTRYPOINT ["/usr/local/bin/startup.sh"] 
