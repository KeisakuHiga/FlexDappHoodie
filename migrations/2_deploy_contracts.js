<<<<<<< HEAD
const HoodieToken = artifacts.require("./HoodieToken.sol");

module.exports = function(deployer, network, accounts) {
  // account3 will be the owner
  deployer.deploy(HoodieToken, { from: accounts[0]});
=======
var HoodieToken = artifacts.require("./HoodieToken.sol");
var IRToken = artifacts.require("./IRToken.sol");
// var RTokenStructs = artifacts.require("./RTokenStructs.sol");
// var IAllocationStrategy = artifacts.require("./IAllocationStrategy.sol");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(HoodieToken, 100, { from: accounts[0]});
  deployer.deploy(IRToken, { from: accounts[0]});
  // deployer.deploy(RTokenStructs, { from: accounts[0]});
  // deployer.deploy(IAllocationStrategy, { from: accounts[0]});
>>>>>>> bf147e043672d0b5d50bbb437bc1fd1a9aba59da
};
