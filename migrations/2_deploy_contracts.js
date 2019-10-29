const HoodieToken = artifacts.require("./HoodieToken.sol");

module.exports = function(deployer, network, accounts) {
  // account3 will be the owner
  const daiAddress = '0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa';
  const rDaiAddress = '0x6AA5c6aB94403Bdbbf74f21607D46Be631E6CcC5';
  deployer.deploy(HoodieToken, daiAddress, rDaiAddress, { from: accounts[0] });
};
