const CommunityProperties = artifacts.require("CommunityProperties");
const Marketplace = artifacts.require("Marketplace");
const QualityLabel = artifacts.require("QualityLabel");

module.exports = function(deployer) {
    var communityPropertiesAddress, marketplaceAddress;

    deployer.then(function() {
        return CommunityProperties.deployed();
    }).then(function(instance) {
        communityPropertiesAddress = instance.address;
        return Marketplace.deployed();
    }).then(function(instance) {
        marketplaceAddress = instance.address;
        return deployer.deploy(QualityLabel, communityPropertiesAddress, marketplaceAddress);
    });
};