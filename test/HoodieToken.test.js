const HoodieToken = artifacts.require("./HoodieToken.sol");

contract("HoodieToken", accounts => {
  it("The totalSupply should be 100", async () => {
    const hoodieTokenInstance = await HoodieToken.deployed();
    const totalSupply = await hoodieTokenInstance.totalSupply.call();

    assert.equal(totalSupply, 100, "The total supply amount should be 100.");
  });
});
