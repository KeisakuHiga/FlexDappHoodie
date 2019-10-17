pragma solidity ^0.5.0;
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./IDai.sol"; 
import "./IRToken.sol";

contract HoodieToken is ERC20, ERC20Detailed, Ownable {
  struct User {
    address userAddress;
    uint256 userNumber;
    uint256 depositedAmount;
    bool isWaiting;
  }
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
  uint256 public waitingUserNumber = 0;
  uint256 public nextRecipientNumber = 0;
  uint256 public hoodieCost;
  mapping(uint256 => User) public waitingList;

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
  
  // add user to waitingList
    // waitingList.push(msg.sender);
    waitingList[nextRecipientNumber] = User({
      userAddress: msg.sender,
      userNumber: waitingUserNumber,
      depositedAmount: depositAmount,
      isWaiting: true
    });
    waitingUserNumber++;
    emit UserPushedIntoWaitingList(msg.sender, depositAmount);
    return true;
  }

  function issueFDH() public returns(bool) {
    // test
    require(rDAIContract.interestPayableOf(owner()) > 0, "the interest amount has not reached 20 rDAI yet");
    
    // check whether or not the generated interest amount reached 20 rDAI
    // require(rDAIContract.interestPayableOf(owner()) >= hoodieCost, "the interest amount has not reached 20 rDAI yet");

    //
    require(approve(msg.sender, 1 * 10 ** 18), "Approval failed");

    // check wheter or not the user is in the waiting list
    User memory nextRecipient = waitingList[nextRecipientNumber];
    while(!nextRecipient.isWaiting) {
      nextRecipientNumber++;
      nextRecipient = waitingList[nextRecipientNumber];
    }
    // issue 1 FDH to the first user in the waiting list and update the nextRecipientNumber+1
    require(transferFrom(address(this), nextRecipient.userAddress, 1 * 10 ** 18), "Issuing FDH failed");

    // update the next recipient in the waiting list by incrementing the waiting counter
    nextRecipientNumber++;
    emit IssuedFDH(nextRecipient.userAddress);
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