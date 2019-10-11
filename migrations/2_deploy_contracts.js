const HoodieToken = artifacts.require("./HoodieToken.sol");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(HoodieToken, { from: accounts[0]});
};
