const CommunityProperties = artifacts.require("CommunityProperties");
const Marketplace = artifacts.require("Marketplace");

module.exports = function(deployer) {
    deployer.deploy(CommunityProperties).then(function() {
        return deployer.deploy(Marketplace, CommunityProperties.address);
    });
};