// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./CommunityProperties.sol";
import "./Marketplace.sol";

contract QualityLabel is ERC20 {
    CommunityProperties communityProperties;
    Marketplace marketplace;

    struct QualityCheckVote {
        bool initiated;
        uint256 positiveVotes;
        mapping(address => bool) hasVoted;
    }

    struct QualityCheckResult {
        bool result;
        uint256 dateOfCheck;
    }

    struct OrganizationInfo {
        address verificationWallet;
        string organizationName;
    }

    OrganizationInfo[] public organizations;

    QualityCheckVote public qualityCheckVote;
    mapping(address => QualityCheckResult) public qualityCheckResults;

    // Mapping between sharing wallet and verification wallet
    mapping(address => address) public verificationWallets;
    // Mapping to store the organization name associated with a verification wallet
    mapping(address => string) public organizationNames;
    // Mapping to store the date of token issuance for verification wallets
    mapping(address => uint256) public tokenIssuanceDate;
    // Mapping to store the date of the last successful QualityLabel check for each address
    mapping(address => uint256) public lastSuccessfulCheckDate;

    event QualityCheckInitiated(uint256 timestamp);
    event QualityCheckPerformed(address indexed participant, bool result, uint256 timestamp);

    constructor(address _communityPropertiesAddress, address _marketplaceAddress)
        ERC20("QualityToken", "QTK") 
    {
        communityProperties = CommunityProperties(_communityPropertiesAddress);
        marketplace = Marketplace(payable(_marketplaceAddress));
    }

    modifier onlyRegistered() {
        require(communityProperties.registeredAddresses(msg.sender), "Address is not registered");
        _;
    }

    function voteForQualityCheck() public onlyRegistered {
        require(!qualityCheckVote.hasVoted[msg.sender], "Already voted");
        qualityCheckVote.hasVoted[msg.sender] = true;
        qualityCheckVote.positiveVotes++;

        uint256 totalRegistered = communityProperties.totalAddressesCount();
        if (!qualityCheckVote.initiated && qualityCheckVote.positiveVotes * 2 > totalRegistered) {
            qualityCheckVote.initiated = true;
            emit QualityCheckInitiated(block.timestamp);
            performQualityCheckOnAll();
        }
    }

    function performQualityCheckOnAll() internal {
        uint256 totalRegistered = communityProperties.totalAddressesCount();
        for (uint256 i = 0; i < totalRegistered; i++) {
            address participant = communityProperties.getRegisteredAddressAtIndex(i);
            performQualityCheck(participant);
        }
        // Reset the voting state after performing the quality check
        resetVotingState();
    }

    function resetVotingState() internal {
        uint256 totalRegistered = communityProperties.totalAddressesCount();
        for (uint256 i = 0; i < totalRegistered; i++) {
            address participant = communityProperties.getRegisteredAddressAtIndex(i);
            delete qualityCheckVote.hasVoted[participant];
        }
        qualityCheckVote.initiated = false;
        qualityCheckVote.positiveVotes = 0;
    }

    function setVerificationWallet(address verificationWallet) public {
        verificationWallets[msg.sender] = verificationWallet;
    }

    function setOrganizationName(string memory organizationName) public {
        require(balanceOf(msg.sender) > 0, "QualityLabel: No tokens in wallet");
        organizationNames[msg.sender] = organizationName;
        organizations.push(OrganizationInfo(msg.sender, organizationName));
    }

    function getOrganizationDetails(string memory organizationName) public view returns (string memory, uint256) {
        for (uint i = 0; i < organizations.length; i++) {
            if (keccak256(abi.encodePacked(organizations[i].organizationName)) == keccak256(abi.encodePacked(organizationName))) {
                address verificationWallet = organizations[i].verificationWallet;
                require(balanceOf(verificationWallet) > 0, "QualityLabel: Verification wallet has no tokens");
                return (organizationName, tokenIssuanceDate[verificationWallet]);
            }
        }
        revert("QualityLabel: Organization not found");
    }


    function performQualityCheck(address participant) internal {
        bool qualityResult = checkQualityLabel(participant);
        uint256 currentTime = block.timestamp;

        if (qualityResult) {
            address verificationWallet = verificationWallets[participant];
            _mint(verificationWallet, getRewardAmount());
            lastSuccessfulCheckDate[verificationWallet] = currentTime; // Update the check date
            qualityCheckResults[verificationWallet] = QualityCheckResult({
                result: qualityResult,
                dateOfCheck: currentTime
            });
        }

        emit QualityCheckPerformed(participant, qualityResult, currentTime);
    }

    function isVerificationWalletValid(address verificationWallet) public view returns (bool) {
        uint256 tokens = balanceOf(verificationWallet);
        if (tokens > 0 && lastSuccessfulCheckDate[verificationWallet] >= tokenIssuanceDate[verificationWallet]) {
            return true;
        }
        return false;
    }
    function checkQualityLabel(address participant) public view returns (bool) {
        uint256 requiredSales = communityProperties.requiredSales();
        uint256 requiredPurchases = communityProperties.requiredPurchases();
        uint256 requiredTimePeriod = communityProperties.getRequiredQLTimePeriod() * 1 days;

        uint256 salesCount = marketplace.getSellerSalesCount(participant, requiredTimePeriod);
        uint256 purchasesCount = marketplace.getBuyerPurchaseCount(participant, requiredTimePeriod);

        return salesCount >= requiredSales && purchasesCount >= requiredPurchases;
    }

    function getRewardAmount() internal pure returns (uint256) {
        // Define logic to determine the reward amount
        return 1 * 10 ** 18; // Placeholder for 1 token (assuming 18 decimals)
    }
}