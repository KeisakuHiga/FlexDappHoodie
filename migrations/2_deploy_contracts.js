var HoodieToken = artifacts.require("./HoodieToken.sol");
var IRToken = artifacts.require("./IRToken.sol");
var RTokenStructs = artifacts.require("./RTokenStructs.sol");
var IAllocationStrategy = artifacts.require("./IAllocationStrategy.sol");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(HoodieToken, 100, { from: accounts[0]});
  deployer.deploy(IRToken, { from: accounts[0]});
  deployer.deploy(RTokenStructs, { from: accounts[0]});
  deployer.deploy(IAllocationStrategy, { from: accounts[0]});
};
