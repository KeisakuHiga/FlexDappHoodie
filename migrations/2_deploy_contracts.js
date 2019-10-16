const HoodieToken = artifacts.require("./HoodieToken.sol");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(HoodieToken, 99, { from: accounts[0]});
};
