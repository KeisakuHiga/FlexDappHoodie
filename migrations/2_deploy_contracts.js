var SimpleStorage = artifacts.require("./SimpleStorage.sol");
var HoodieToken = artifacts.require("./HoodieToken.sol");

module.exports = function(deployer) {
  deployer.deploy(SimpleStorage);
  deployer.deploy(HoodieToken, 100);
};
