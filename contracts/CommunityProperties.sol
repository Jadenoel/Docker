// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

contract CommunityProperties {
    address public owner;
    bool public ratingObligationEnabled;
    uint256 public ratingObligationTimePeriod;
    uint256 public requiredRatingPercentage;
    uint256 public requiredPurchases;
    uint256 public requiredQLTimePeriod;
    uint256 public requiredSales;
    string public CommunityName;

    struct ChangeRequestWithoutMapping {
        address requestor;
        uint256 requestId;
        bool status;
        bool newRatingObligationEnabled;
        uint256 newRatingObligationTimePeriod;
        uint256 newRequiredRatingPercentage;
        uint256 newRequiredPurchases;
        uint256 newRequiredQLTimePeriod;
        uint256 newRequiredSales;
        uint256 approvalCount;
        uint256 rejectionCount;
        mapping(address => bool) voted;
    }

    mapping(uint256 => ChangeRequestWithoutMapping) public changeRequests;
    uint256 public requestCount;
    uint256 public totalAddressesCount; // Track total addresses in the network
    mapping(address => bool) public registeredAddresses; // Mapping to track registered addresses
    address[] public registeredAddressesList; // Array to store a list of registered addresses

    event PropertiesUpdated(bool ratingObligationEnabled, uint256 ratingObligationTimePeriod, uint256 requiredRatingPercentage, uint256 requiredPurchases, uint256 requiredQLTimePeriod, uint256 requiredSales);
    event ChangeRequestSubmitted(uint256 requestId, address requestor);
    event VoteCasted(uint256 requestId, address voter, bool vote, uint256 approvalCount, uint256 rejectionCount);

    struct VoteData {
        bool vote;
        bool isApproval;
        uint256 requestId;
        uint256 approvalCount;
        uint256 rejectionCount;
        bool status;
    }

    constructor() {
        owner = msg.sender;
        ratingObligationEnabled = false;
        ratingObligationTimePeriod = 100;
        requiredRatingPercentage = 0;
        requiredPurchases = 20;
        requiredQLTimePeriod = 365;
        requiredSales = 5;
        totalAddressesCount = 0;
        CommunityName = "Automotive";
    }

     modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier notVoted(uint256 requestId) {
        ChangeRequestWithoutMapping storage currentRequest = changeRequests[requestId];
        require(!currentRequest.voted[msg.sender], "You have already voted");
        _;
    }

    modifier onlyRegistered() {
        require(registeredAddresses[msg.sender], "Address is not registered");
        _;
    }

    function registerAddress(address addr) external onlyOwner {
        require(!registeredAddresses[addr], "Address is already registered");
        registeredAddresses[addr] = true;
        registeredAddressesList.push(addr);
        totalAddressesCount++;
    }

    function unregisterAddress(address addr) external onlyOwner {
        require(registeredAddresses[addr], "Address is not registered");
        registeredAddresses[addr] = false;

        // Remove the address from the registeredAddressesList
        for (uint256 i = 0; i < registeredAddressesList.length; i++) {
            if (registeredAddressesList[i] == addr) {
                registeredAddressesList[i] = registeredAddressesList[registeredAddressesList.length - 1];
                registeredAddressesList.pop();
                break;
            }
        }

        totalAddressesCount--;
    }

    // New function to get a registered address by index
    function getRegisteredAddressAtIndex(uint256 index) external view returns (address) {
        require(index < registeredAddressesList.length, "Index out of bounds");
        return registeredAddressesList[index];
    }

    // New function to get the total number of registered addresses
    function getTotalRegisteredAddresses() external view returns (uint256) {
        return registeredAddressesList.length;
    }

    function updateProperties(bool _ratingObligationEnabled, uint256 _ratingObligationTimePeriod, uint256 _requiredRatingPercentage, uint256 _requiredPurchases, uint256 _requiredQLTimePeriod, uint256 _requiredSales) external onlyOwner {
        ratingObligationEnabled = _ratingObligationEnabled;
        ratingObligationTimePeriod = _ratingObligationTimePeriod;
        requiredRatingPercentage = _requiredRatingPercentage;
        requiredPurchases = _requiredPurchases;
        requiredQLTimePeriod = _requiredQLTimePeriod;
        requiredSales = _requiredSales;

        emit PropertiesUpdated(_ratingObligationEnabled, _ratingObligationTimePeriod, _requiredRatingPercentage, _requiredPurchases, _requiredQLTimePeriod, _requiredSales);
    }

    function submitChangeRequest(bool _newRatingObligationEnabled, uint256 _newRatingObligationTimePeriod, uint256 _newRequiredRatingPercentage, uint256 _newRequiredPurchases, uint256 _newRequiredQLTimePeriod, uint256 _newRequiredSales) external onlyRegistered {
        require(!changeRequests[requestCount].voted[msg.sender], "Address has already submitted a request");

        requestCount++;
        ChangeRequestWithoutMapping storage newRequest = changeRequests[requestCount];
        newRequest.requestor = msg.sender;
        newRequest.requestId = requestCount;
        newRequest.status = true;
        newRequest.newRatingObligationEnabled = _newRatingObligationEnabled;
        newRequest.newRatingObligationTimePeriod = _newRatingObligationTimePeriod;
        newRequest.newRequiredRatingPercentage = _newRequiredRatingPercentage;
        newRequest.newRequiredPurchases = _newRequiredPurchases;
        newRequest.newRequiredQLTimePeriod = _newRequiredQLTimePeriod;
        newRequest.newRequiredSales = _newRequiredSales;

        // Add the requester to the voted list with a positive vote
        newRequest.voted[msg.sender] = true;
        newRequest.approvalCount++;

        emit ChangeRequestSubmitted(requestCount, msg.sender);
        emit VoteCasted(requestCount, msg.sender, true, newRequest.approvalCount, newRequest.rejectionCount);
    }

    function castVote(uint256 requestId, bool vote) external notVoted(requestId) {
        ChangeRequestWithoutMapping storage currentRequest = changeRequests[requestId];
        require(currentRequest.status, "Request already closed");

        VoteData memory voteData;
        voteData.vote = vote;
        voteData.requestId = requestId;
        voteData.approvalCount = currentRequest.approvalCount;
        voteData.rejectionCount = currentRequest.rejectionCount;
        voteData.status = currentRequest.status;

        // Add the voter to the voted list
        currentRequest.voted[msg.sender] = true;

        // Determine if it's an approval or rejection
        if (vote) {
            voteData.isApproval = true;
            voteData.approvalCount++;
        } else {
            voteData.isApproval = false;
            voteData.rejectionCount++;
        }

        emit VoteCasted(
            voteData.requestId,
            msg.sender,
            voteData.vote,
            voteData.approvalCount,
            voteData.rejectionCount
        );

        // Check if the majority has voted
        if ((voteData.approvalCount * 100) / totalAddressesCount > 50) {
            // Apply the changes and close the request
            ratingObligationEnabled = currentRequest.newRatingObligationEnabled;
            ratingObligationTimePeriod = currentRequest.newRatingObligationTimePeriod;
            requiredRatingPercentage = currentRequest.newRequiredRatingPercentage;
            requiredPurchases = currentRequest.newRequiredPurchases;
            requiredQLTimePeriod = currentRequest.newRequiredQLTimePeriod;
            requiredSales = currentRequest.newRequiredSales;
            currentRequest.status = false;

            emit PropertiesUpdated(
                ratingObligationEnabled,
                ratingObligationTimePeriod,
                requiredRatingPercentage,
                requiredPurchases,
                requiredQLTimePeriod,
                requiredSales
            );
        } else if ((voteData.rejectionCount * 100) / totalAddressesCount > 50) {
            // Reject the changes and close the request
            currentRequest.status = false;
        }
    }

    function showActiveProposals() external view returns (
        uint256[] memory requestIds,
        address[] memory requestors,
        bool[] memory statuses,
        bool[] memory newRatingObligationEnabled,
        uint256[] memory newRatingObligationTimePeriod,
        uint256[] memory newRequiredRatingPercentage,
        uint256[] memory newRequiredPurchases,
        uint256[] memory newRequiredQLTimePeriod,
        uint256[] memory newRequiredSales,
        uint256[] memory approvalCounts,
        uint256[] memory rejectionCounts
    ) {
        uint256 count;
        for (uint256 i = 1; i <= requestCount; i++) {
            if (changeRequests[i].status) {
                count++;
            }
        }

        requestIds = new uint256[](count);
        requestors = new address[](count);
        statuses = new bool[](count);
        newRatingObligationEnabled = new bool[](count);
        newRatingObligationTimePeriod = new uint256[](count);
        newRequiredRatingPercentage = new uint256[](count);
        newRequiredPurchases = new uint256[](count);
        newRequiredQLTimePeriod = new uint256[](count);
        newRequiredSales = new uint256[](count);
        approvalCounts = new uint256[](count);
        rejectionCounts = new uint256[](count);

        count = 0;
        for (uint256 i = 1; i <= requestCount; i++) {
            if (changeRequests[i].status) {
                ChangeRequestWithoutMapping storage currentRequest = changeRequests[i];
                requestIds[count] = currentRequest.requestId;
                requestors[count] = currentRequest.requestor;
                statuses[count] = currentRequest.status;
                newRatingObligationEnabled[count] = currentRequest.newRatingObligationEnabled;
                newRatingObligationTimePeriod[count] = currentRequest.newRatingObligationTimePeriod;
                newRequiredRatingPercentage[count] = currentRequest.newRequiredRatingPercentage;
                newRequiredPurchases[count] = currentRequest.newRequiredPurchases;
                newRequiredQLTimePeriod[count] = currentRequest.newRequiredQLTimePeriod;
                newRequiredSales[count] = currentRequest.newRequiredSales;
                approvalCounts[count] = currentRequest.approvalCount;
                rejectionCounts[count] = currentRequest.rejectionCount;

                count++;
            }
        }

        return (
            requestIds,
            requestors,
            statuses,
            newRatingObligationEnabled,
            newRatingObligationTimePeriod,
            newRequiredRatingPercentage,
            newRequiredPurchases,
            newRequiredQLTimePeriod,
            newRequiredSales,
            approvalCounts,
            rejectionCounts
        );
    }

    function showAllActiveProperties() external view returns (bool, uint256, uint256, uint256, uint256, uint256) {
        return (ratingObligationEnabled, ratingObligationTimePeriod, requiredRatingPercentage, requiredPurchases, requiredQLTimePeriod, requiredSales);
    }

    function getRatingObligationEnabled() external view returns (bool) {
        return ratingObligationEnabled;
    }

    function getRatingObligationTimePeriod() external view returns (uint256) {
        return ratingObligationTimePeriod;
    }

    function getRequiredRatingPercentage() external view returns (uint256) {
        return requiredRatingPercentage;
    }

    // Additional getter functions for the new variables
    function getRequiredPurchases() external view returns (uint256) {
        return requiredPurchases;
    }

    function getRequiredQLTimePeriod() external view returns (uint256) {
        return requiredQLTimePeriod;
    }

    function getRequiredSales() external view returns (uint256) {
        return requiredSales;
    }
    function getCommunityName() external view returns (string memory) {
        return CommunityName;
    }
}