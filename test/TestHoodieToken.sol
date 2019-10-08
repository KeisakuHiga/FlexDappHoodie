pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/HoodieToken.sol";

contract TestHoodieToken {

  function testTotalSupplyOfTheToken() public {
    HoodieToken tokenInstance = HoodieToken(DeployedAddresses.HoodieToken());
    uint expected = 100;
    Assert.equal(tokenInstance.totalSupply(), expected, "The total supply amount should be 100.");
  }

}
