pragma solidity ^0.5.0;
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./IDai.sol"; 
import "./IRToken.sol";

contract HoodieToken is ERC20, ERC20Detailed, Ownable {
  // Instantiate DAIContract with DAI address on rinkeby
  address DAIAddress = 0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa;
  IDai public DAIContract = IDai(DAIAddress);

  //  Instantiate rDAIContract with rDAI address on rinkeby
  address rDAIAddress = 0xb0C72645268E95696f5b6F40aa5b12E1eBdc8a5A;
  IRToken public rDAIContract = IRToken(rDAIAddress);

  // Hat setting
  uint256 public hatID;
  address public recipient = owner();
  uint32 public proportion = 100;
  address[] public recipients = [recipient];
  uint32[] public proportions = [proportion];
  bool public doChangeHat = false;

  uint256 public minimumDepositAmount;
  uint256 public waitingNumCounter;
  address[] public waitingList;

  event UserPushedIntoWaitingList(address user, uint256 depositedAmount)

  constructor(uint256 initialSupply) ERC20Detailed("Flex Dapps Hoodie Token", "FDH", 18) public {
    _mint(msg.sender, initialSupply * 10 ** 18);
    minimumDepositAmount = 1 * 10 ** 18;
    hatID = rDAIContract.createHat(recipients, proportions, doChangeHat);
  }

  function mintRDaiAndPushUserToWaitingList(uint256 depositAmount) public returns(bool) {
  // dapp transfer user's DAI to itself
    require(depositAmount >= minimumDepositAmount, "Deposit amount should be equal to / greater than 200DAI");

    require(DAIContract.transferFrom(msg.sender, address(this), depositAmount), "Transfer DAI from user to Hoodie contract failed");

  // dapp approves rDAI contract to transfer dapp's DAI
    require(DAIContract.approve(address(rDAIContract), depositAmount), "approve() invalid");

  // dapp invoke mint() and get rDAI
    require(rDAIContract.mintWithSelectedHat(depositAmount, hatID), "minting failed");

  // dapp transfer rDAI to user
    rDAIContract.transferFrom(address(this), msg.sender, depositAmount);
  
  // add user address to waitingList
    waitingList.push(msg.sender);
    emit UserPushedIntoWaitingList(msg.sender, depositAmount);

    return true;
  }

  function getWaitingList() public view returns(address[] memory) {
    return waitingList;
  }
}