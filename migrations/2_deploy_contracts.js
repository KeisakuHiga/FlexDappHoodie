const HoodieToken = artifacts.require("./HoodieToken.sol");

module.exports = function(deployer, network, accounts) {
  // account3 will be the owner
  deployer.deploy(HoodieToken, { from: accounts[0]});
};
