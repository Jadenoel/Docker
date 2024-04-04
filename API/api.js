const express = require('express');
const app = express();
const cors = require('cors');
const path = require('path');
const Web3 = require('web3');
const fs = require('fs');
const axios = require('axios');
const PrivateKeyProvider = require('@truffle/hdwallet-provider');

const privateKeys = [
    '0x8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63',
    '0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3',
    '0xae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f'
  ];

const privateKeyProvider = new PrivateKeyProvider(privateKeys, 'http://127.0.0.1:8545', 0, 3);
const web3 = new Web3(privateKeyProvider);

// Function to read config
function readConfig() {
  const configPath = path.join(__dirname, 'config.json');
  const configFile = fs.readFileSync(configPath);
  return JSON.parse(configFile);
}

const config = readConfig();

const MPaddress = config.MPaddress;
const QLaddress = config.QLaddress;
const CPaddress = config.CPaddress;

const abiPath = '/besu/besu-23.10.2/bin/IBFT-Network/build/contracts/Marketplace.json';
const QLabiPath = '/besu/besu-23.10.2/bin/IBFT-Network/build/contracts/QualityLabel.json';
const CPabiPath = '/besu/besu-23.10.2/bin/IBFT-Network/build/contracts/CommunityProperties.json';

const abiFile = fs.readFileSync(abiPath);
const QLabiFile = fs.readFileSync(QLabiPath);
const CPabiFile = fs.readFileSync(CPabiPath);

const MPabi = JSON.parse(abiFile).abi;
const QLabi = JSON.parse(QLabiFile).abi;
const CPabi = JSON.parse(CPabiFile).abi;

const MPContract = new web3.eth.Contract(MPabi, MPaddress);
const QLContract = new web3.eth.Contract(QLabi, QLaddress);
const CPContract = new web3.eth.Contract(CPabi, CPaddress);

app.use(cors());
app.use(express.json());

function serializeBigInts(obj) {
    return JSON.parse(JSON.stringify(obj, (key, value) =>
      typeof value === 'bigint' ? value.toString() : value
    ));
  }

// Util function to send transaction
const sendTransaction = async (from, to, value, gasLimit, gasPrice, nonce) => {
    return await web3.eth.sendTransaction({
      from,
      to,
      value: web3.utils.toWei(value.toString(), 'ether'),
      gas: gasLimit,
      gasPrice,
      nonce
    });
    return await web3.eth.getTransactionReceipt(transaction.transactionHash);
  };
  
  // Util function to send smart contract transaction
  const sendContractTransaction = async (method, from, gasLimit, gasPrice, nonce) => {
    return await method.send({
      from,
      gas: gasLimit,
      gasPrice,
      nonce
    });
  };

  function serializeBigInts(obj) {
    return JSON.parse(JSON.stringify(obj, (key, value) =>
      typeof value === 'bigint' ? value.toString() : value
    ));
  }
app.post('/callSmartContract', async (req, res) => {
    const fromAddress = '0x627306090abaB3A6e1400e9345bC60c78a8BEf57'
    const { key, parameters } = req.body;

    try {
        const gasPrice = await web3.eth.getGasPrice();
        const gasPriceString = gasPrice.toString();
        const gasLimit = 3000000;
        let nonce = await web3.eth.getTransactionCount(fromAddress);
        let nonceString = nonce.toString();
        if (key == "offerData") {
            var eventName = "DataItemCreated";
            const method = MPContract.methods.offerData(
                parameters[0], // _description
                parameters[1], // _hash
                Number(parameters[2]), // _priceInEther
                parameters[3], // _db_name
                parameters[4], // _doc_id
                parameters[5], // _title
                parameters[6], // _type
                parameters[7]  // _category
            );
            const result = await sendContractTransaction(method, fromAddress, gasLimit, gasPrice, nonce);
            console.log("result:", serializeBigInts(result));
            res.json({ result: serializeBigInts(result) });
        } else if (key == "purchaseData") {
            var eventName = "DataItemPurchased";
            console.log(fromAddress, MPaddress, parameters[2], gasLimit, gasPriceString, nonceString);
            console.log("Es werden jetzt " + Number(parameters[2]) + " Ether an den Smart Contract gesendet");
            
            // First, send ethers to the contract
            await sendTransaction(fromAddress, MPaddress, Number(parameters[2]), gasLimit, gasPriceString, nonceString);
            console.log("Ether was sent to smart contract succesfully!");
            
            console.log("Now the purchaseData function is called.");
            
            const purchaseMethod = MPContract.methods.purchaseData(
                Number(parameters[0]), // _itemId
                parameters[1]  // destination_db
            );

            nonce = nonce + BigInt(1);
            nonceString = nonce.toString();

            const result = await sendContractTransaction(purchaseMethod, fromAddress, gasLimit, gasPriceString, nonceString);
            console.log("Result:", serializeBigInts(result));
            res.json({ result: serializeBigInts(result) });
            
        } else if (key == "editDataItem") {
          var eventName = "DataItemUpdated"
          const method = MPContract.methods.editDataItem(
            parameters[0], //_itemId
            parameters[1], // _description
            parameters[2], // _hash
            Number(parameters[3]), // _priceInEther
            parameters[4], // _title
            parameters[5], // _type
            parameters[6]  // _category
          );
          const result = await sendContractTransaction(method, fromAddress, gasLimit, gasPrice, nonce);
          console.log("Result:", serializeBigInts(result));
          res.json({ result: serializeBigInts(result) });
        } else if (key == "deleteDataItem") {
            var eventName = "DataItemDeleted"
            const method = MPContract.methods.deleteDataItem(
                Number(parameters[0])
            );
            const result = await sendContractTransaction(method, fromAddress, gasLimit, gasPrice, nonce);
            console.log("Result:", serializeBigInts(result));
            res.json({ result: serializeBigInts(result) });

        } else if(key == "setOrganizationName") {
            let fromVerifyAddress = "0xf17f52151EbEF6C7334FAD080c5704D77216b732"  
            let nonce = await web3.eth.getTransactionCount(fromVerifyAddress);
            const method = QLContract.methods.setOrganizationName(
              parameters[0]
            );
            const result = await sendContractTransaction(method, fromVerifyAddress, gasLimit, gasPrice, nonce);
            console.log("Receipt:", serializeBigInts(result));
            res.json({ result: serializeBigInts(result) });

        } else if(key == "voteForQualityCheck") {
            const method = QLContract.methods.voteForQualityCheck();
            const result = await sendContractTransaction(method, fromAddress, gasLimit, gasPrice, nonce);
            console.log("Result:", serializeBigInts(result));
            res.json({ result: serializeBigInts(result) });

        } else if (key == "addReview") {
            var eventName = "ReviewAdded"
            const method = MPContract.methods.addReview(
                Number(parameters[0]),
                Number(parameters[1]),
                parameters[2]
            );
            const result = await sendContractTransaction(method, fromAddress, gasLimit, gasPrice, nonce);
            console.log("Receipt:", serializeBigInts(result));
            res.json({ result: serializeBigInts(result) });
        } else if (key === "seeAllAvailableDataItems") {
            const result = await MPContract.methods[key](...parameters).call({ from: fromAddress });
            // Convert BigInt values to strings before serialization
            const serializedResult = JSON.parse(JSON.stringify(result, (key, value) =>
                typeof value === 'bigint' ? value.toString() : value
            ));
            console.log("Data Items: ", serializedResult);
            
            res.json({ result: serializedResult });
        } else if ( key === "getReviewsForDataItem") {
              console.log(parameters[0]);
              const result = await MPContract.methods[key](Number(parameters[0])).call({ from: fromAddress });
              // Convert BigInt values to strings before serialization
              const serializedResult = JSON.parse(JSON.stringify(result, (key, value) =>
                  typeof value === 'bigint' ? value.toString() : value
              ));
              console.log("ReviewsForDataItem: ", serializedResult);

              res.json({ result: serializedResult });
        } else {
            throw new Error("Invalid key value");
        }
    } catch (error) {
        console.error('Error:', error);
        if (!res.headersSent) {
          res.status(500).json({ error: error.message });
        }
      }
    });


function minBigInt(bigInt1, bigInt2) {
  return (bigInt1 < bigInt2) ? bigInt1 : bigInt2;
}

app.post('/getPurchaseTimestamp', async (req, res) => {
  const { itemId, buyerAddress } = req.body;
  console.log(itemId);
  console.log(buyerAddress);
  let fromBlock = BigInt(0); // Start block, adjust accordingly
  let toBlock; // Will be set to the latest block number
  const batchSize = BigInt(5000); // Define a suitable batch size

  try {
    // Fetch the current latest block number and convert to BigInt
    toBlock = BigInt(await web3.eth.getBlockNumber());

    let eventLogs = [];
    while (fromBlock <= toBlock) {
      const batchToBlock = minBigInt(fromBlock + batchSize, toBlock);
      const batchEventLogs = await MPContract.getPastEvents('DataItemPurchased', {
        filter: { itemId: itemId, buyer: buyerAddress },
        fromBlock: fromBlock,
        toBlock: batchToBlock
      });

      eventLogs = [...eventLogs, ...batchEventLogs];
      fromBlock = batchToBlock + BigInt(1);
    }

    if (eventLogs.length === 0) {
      return res.status(404).json({ error: 'Purchase record not found' });
    }

    // Assuming the latest purchase is what you want
    const latestPurchaseLog = eventLogs[eventLogs.length - 1];
    const block = await web3.eth.getBlock(latestPurchaseLog.blockNumber);
    const timestamp = block.timestamp;

    res.json({ timestamp: serializeBigInts(timestamp) });
  } catch (error) {
    console.error('Error:', error);
    if (!res.headersSent) {
      res.status(500).json({ error: error.message });
    }
  }
});

// Endpoint to get sales and purchases count since the last successful QualityLabel check
app.get('/activitySinceLastCheck', async (req, res) => {
  const walletAddress = '0x627306090abaB3A6e1400e9345bC60c78a8BEf57';
  
  try {
      // Retrieve the last successful check date for the wallet
      const lastCheckDateResult = await QLContract.methods.lastSuccessfulCheckDate(walletAddress).call();
      const lastCheckDate = lastCheckDateResult.toString();
      console.log("lastCheckDate:" + serializeBigInts(lastCheckDate));

      // Use the last successful check date as the starting point to count sales and purchases
      const currentTime = Math.floor(Date.now() / 1000); // Current time in seconds since epoch
      const timePeriod = currentTime - lastCheckDate; // Calculate time period since last check

      // Get the sales count since the last successful QualityLabel check
      const salesCount = await MPContract.methods.getSellerSalesCount(walletAddress, timePeriod).call();
      // Get the purchases count since the last successful QualityLabel check
      const purchasesCount = await MPContract.methods.getBuyerPurchaseCount(walletAddress, timePeriod).call();

      console.log("purchasesCount:" + serializeBigInts(purchasesCount));
      console.log("salesCount: " + serializeBigInts(salesCount));
      console.log("timePeriod:" + serializeBigInts(timePeriod));

      // Send the response with sales and purchases count
      res.json({
          walletAddress: walletAddress,
          sinceLastCheck: serializeBigInts(lastCheckDate),
          salesCount: serializeBigInts(salesCount),
          purchasesCount: serializeBigInts(purchasesCount)
      });
  } catch (error) {
      console.error('Error:', error);
      res.status(500).json({ error: error.message });
  }
});

app.get('/communityRequirements', async (req, res) => {
  try {
      // Fetch the requiredPurchases and requiredSales 
      const requiredPurchases = await CPContract.methods.requiredPurchases().call();
      const requiredSales = await CPContract.methods.requiredSales().call();

      console.log("requiredPurchases: " + serializeBigInts(requiredPurchases));
      console.log("requiredSales:" + serializeBigInts(requiredSales));
      
      // Send the response with the requiredPurchases and requiredSales
      res.json({
          requiredPurchases: serializeBigInts(requiredPurchases),
          requiredSales: serializeBigInts(requiredSales)
      });
  } catch (error) {
      console.error('Error:', error);
      res.status(500).json({ error: error.message });
  }
});

app.get('/verifyWallet/:walletAddress', async (req, res) => {
  const { walletAddress } = req.params;

  try {
      const isValid = await QLContract.methods.isVerificationWalletValid(walletAddress).call();
      res.json({ isValid });
  } catch (error) {
      console.error('Error:', error);
      res.status(500).json({ error: error.message });
  }
});

app.get('/getCompletionDates/:walletAddress', async (req, res) => {
  const { walletAddress } = req.params;

  try {
      console.log("Wallet Address: " + walletAddress);
      // Get the sales and purchases completion dates from the contract
      const salesCompletionDate = await MPContract.methods.salesCompletionDate(walletAddress).call();
      const purchasesCompletionDate = await MPContract.methods.purchasesCompletionDate(walletAddress).call();


      console.log("salesCompletionDate: " + serializeBigInts(salesCompletionDate));
      console.log("purchasesCompletionDate: " + serializeBigInts(purchasesCompletionDate));

      let salesDate = 'Not Available';
      let purchasesDate = 'Not Available';

      // Convert the timestamps to readable dates
      if (salesCompletionDate > 0) {
        salesDate = new Date(Number(salesCompletionDate) * 1000).toLocaleDateString('en-GB');
      }

      if (purchasesCompletionDate > 0) {
        purchasesDate = new Date(Number(purchasesCompletionDate) * 1000).toLocaleDateString('en-GB');
      }
        
      console.log("salesCompletionDate: " + salesDate);
      console.log("purchasesCompletionDate: " + purchasesDate);

      res.json({
          salesCompletionDate: salesDate,
          purchasesCompletionDate: purchasesDate
      });
  } catch (error) {
      console.error('Error:', error);
      res.status(500).json({ error: error.message });
  }
});

app.get('/getOrganizationDetails/:organizationName', async (req, res) => {
  const { organizationName } = req.params;

  try {
      // Decode the organization name from URI component
      const decodedOrganizationName = decodeURIComponent(organizationName);

      // Call the smart contract function
      const details = await QLContract.methods.getOrganizationDetails(decodedOrganizationName).call();

      // details is an array [organizationName, tokenIssuanceDate]
      // Convert tokenIssuanceDate from Unix timestamp to readable date
      const issuanceDate = new Date(details[1] * 1000).toLocaleDateString('en-GB', {
          day: '2-digit',
          month: '2-digit',
          year: 'numeric',
      });
      console.log("organizationName: " + details[0]);
      console.log("tokenIssuanceDate: " + issuanceDate);

      res.json({
          organizationName: details[0],
          tokenIssuanceDate: issuanceDate,
      });
  } catch (error) {
      console.error('Error:', error);
      res.status(500).json({ error: error.message });
  }
});

app.get('/getCommunityName', async (req, res) => {
  try {
      const communityName = await CPContract.methods.CommunityName().call();
      console.log(communityName);
      res.json({ communityName });
  } catch (error) {
      console.error('Error:', error);
      res.status(500).json({ error: error.message });
  }
});

app.get('/calculateSellerRating/:sellerAddress', async (req, res) => {
  const { sellerAddress } = req.params;

  try {
      const rating = await MPContract.methods.calculateSellerRating(sellerAddress).call();

      res.json({ 
        seller: sellerAddress, 
        sellerRating: serializeBigInts(rating) 
      });
  } catch (error) {
      console.error('Error:', error);
      res.status(500).json({ error: error.message });
  }
});

const PORT = 20100;
app.listen(PORT, () => {
    console.log(`Node.js server is running on port ${PORT}`);
});    
