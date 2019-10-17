pragma solidity ^0.5.0;
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./IDai.sol"; 
import "./IRToken.sol";

contract HoodieToken is ERC20, ERC20Detailed, Ownable {
  // Instantiate DAIContract with DAI address on rinkeby
  //  Instantiate rDAIContract with rDAI address on rinkeby
  IDai public DAIContract;
  IRToken public rDAIContract;

  // Hat setting
  uint256 public hatID;
  address public recipient = owner();
  uint32 public proportion = 100;
  address[] public recipients = [recipient];
  uint32[] public proportions = [proportion];
  bool public doChangeHat = false;

  uint256 public minimumDepositAmount;
  uint256 public waitingCounter = 0;
  address[] public waitingList;
  uint256 public hoodieCost;

  event UserPushedIntoWaitingList(address user, uint256 depositedAmount);
  event IssuedFDH(address recipientOfHoodie);

  constructor(uint256 initialSupply) ERC20Detailed("Flex Dapps Hoodie Token", "FDH", 18) public {
    DAIContract = IDai(0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa);
    rDAIContract = IRToken(0xb0C72645268E95696f5b6F40aa5b12E1eBdc8a5A);
    hatID = rDAIContract.createHat(recipients, proportions, doChangeHat);
    _mint(address(this), initialSupply * 10 ** 18);
    // minimumDepositAmount = 20 * 10 ** 18;
    minimumDepositAmount = 1 * 10 ** 18; // for test
    hoodieCost = 20 * 10 ** 18;
  }

  function mintRDaiAndPushUserToWaitingList(uint256 depositAmount) public returns(bool) {
  // dapp transfer user's DAI to itself
    require(depositAmount >= minimumDepositAmount, "Deposit amount should be equal to / greater than 200DAI");
    require(DAIContract.transferFrom(msg.sender, address(this), depositAmount), "Transfer DAI to Hoodie contract failed");

  // dapp approves rDAI contract to transfer dapp's DAI
    require(DAIContract.approve(address(rDAIContract), depositAmount), "approve() invalid");

  // dapp invoke mint() and get rDAI
    require(rDAIContract.mintWithSelectedHat(depositAmount, hatID), "minting failed");

  // dapp transfer rDAI to user
    require(rDAIContract.transferFrom(address(this), msg.sender, depositAmount), "Transfer rDAI to user failed");
  
  // add user address to waitingList
    waitingList.push(msg.sender);
    emit UserPushedIntoWaitingList(msg.sender, depositAmount);

    return true;
  }

  function getWaitingList() public view returns(address[] memory) {
    return waitingList;
  }

  function issueFDH() public returns(bool) {
    // check whether or not the generated interest amount reached 20 rDAI
    // require(rDAIContract.interestPayableOf(owner()) >= hoodieCost, "the interest amount has not reached 20 rDAI yet");
    
    // test
    require(rDAIContract.interestPayableOf(owner()) > 0, "the interest amount has not reached 20 rDAI yet");

    // issue 1 FDH to the first user in the waiting list and update the waitingCounter+1
    require(approve(msg.sender, 1 * 10 ** 18), "Approval failed");
    address recipientOfHoodie = waitingList[waitingCounter];
    require(transferFrom(address(this), recipientOfHoodie, 1 * 10 ** 18), "Issuing FDH failed");

    // update the next recipient in the waiting list by incrementing the waiting counter
    waitingCounter++;
    emit IssuedFDH(recipientOfHoodie);

    return true;
  }

  function _setNewDaiContractInstance(address _daiContractAddress) public onlyOwner returns(bool) {
    DAIContract = IDai(_daiContractAddress);
    return true;
  }

  function _setNewRDaiContractInstance(address _rDaiContractAddress) public onlyOwner returns(bool) {
    rDAIContract = IRToken(_rDaiContractAddress);
    return true;
  }
}