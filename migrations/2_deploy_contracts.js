const HoodieToken = artifacts.require("./HoodieToken.sol");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(HoodieToken, 100, { from: accounts[0]});
};
