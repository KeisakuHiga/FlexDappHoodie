pragma solidity ^0.5.0;
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./IDai.sol"; 
import "./IRToken.sol";

contract HoodieToken is ERC20, ERC20Detailed, Ownable {
  struct User {
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
  uint256 public userWaitingNumber = 0;
  uint256 public nextRecipientNumber = 0;
  uint256 public hoodieCost;
  address[] public waitingList;
  mapping(address => User) public users;

  event UserPushedIntoWaitingList(address user, uint256 depositedAmount);
  event IssuedFDH(address recipientOfHoodie);

  constructor(uint256 initialSupply) ERC20Detailed("Flex Dapps Hoodie Token", "FDH", 18) public {
    DAIContract = IDai(0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa);
    rDAIContract = IRToken(0xb0C72645268E95696f5b6F40aa5b12E1eBdc8a5A);
    hatID = rDAIContract.createHat(recipients, proportions, doChangeHat);
    _mint(owner(), initialSupply * 10 ** 18);
    // minimumDepositAmount = 20 * 10 ** 18; // for production
    minimumDepositAmount = 1 * 10 ** 18; // for test
    hoodieCost = 20 * 10 ** 18;
  }

  function mintRDaiAndPushUserToWaitingList(uint256 depositAmount) public returns(bool) {
    // check whether or not the user is new
    require(!users[msg.sender].isWaiting, "This user is existing in the waiting list");
    // mint rDAI and transfer it to user
    require(_mintRDai(depositAmount), "mining rDAI failed");
    // add user to waitingList
    require(_addUserToWaitingList(msg.sender, depositAmount), "failded to add the user again to the waiting list");
    return true;
  }

  function increaseDepositAmount(uint256 topUpAmount) public returns(bool) {
    // check whether or not the user is the existing one
    require(users[msg.sender].isWaiting, "this user is a new one");
    // mint additional rDAI
    require(_mintRDai(topUpAmount),  "mining rDAI failed");
    // update user's deposited amount in User struct
    User storage user = users[msg.sender];
    user.depositedAmount += topUpAmount;
    return true;
  }

  function issueFDH() public onlyOwner returns(bool) {
    // test
    require(rDAIContract.interestPayableOf(owner()) > 0, "the interest amount has not reached 20 rDAI yet");
    
    // check whether or not the generated interest amount reached 20 rDAI
    // require(rDAIContract.interestPayableOf(owner()) >= hoodieCost, "the interest amount has not reached 20 rDAI yet");

    // check wheter or not the user is in the waiting list
    address userAddress = waitingList[nextRecipientNumber];
    // get user struct
    User storage waitingUser = users[userAddress];
    while(!waitingUser.isWaiting) {
      nextRecipientNumber++;
      userAddress = waitingList[nextRecipientNumber];
      waitingUser = users[userAddress];
    }
    // issue 1 FDH to the first user in the waiting list and update the nextRecipientNumber+1
    require(transfer(userAddress, 1 * 10 ** 18), "Issuing FDH failed");
    // once the user receive a FDH, they are removed from the waiting list
    waitingUser.isWaiting = false;
    // update the next waitingUser in the waiting list by incrementing the waiting counter
    nextRecipientNumber++;
    emit IssuedFDH(userAddress);
    // add the user to the waiting list again
    require(_addUserToWaitingList(userAddress, waitingUser.depositedAmount), "failded to add the user again to the waiting list");
    
    return true;
  }

  function redeemRDai(uint256 redeemAmount) public returns (bool) {
    // get user struct
    User storage user = users[msg.sender];
    // check whether or not the user is in the waiting list
    require(user.isWaiting, "this user is not in the waiting list");
    // A. if the deposited amount will be below than 200rDAI after redeeming
    // if(user.depositedAmount.sub(redeemAmount) < 200 * 10 ** 18) {
    //   // 1) use redeemAndTransferAll()
    //   require(rDAIContract.redeemAndTransferAll(msg.sender), "redeemAndTransferAll() failed");
    //   // 2) update the state of user.isWaiting to false
    //   user.isWaiting = false;
    //   // 3) update the state of user.depositedAmount to zero
    //   user.depositedAmount = 0;
    // } else { // B. if not
    //   // 1) use redeemAndTransfer()
    //   require(rDAIContract.redeemAndTransfer(msg.sender, redeemAmount), "redeemAndTransfer() failed");
    //   // 2) decrese the state of user.depositedAmount - redeemAmount
    //   user.depositedAmount = user.depositedAmount.sub(redeemAmount);
    // }
    return true;
  }

  // identifier isWaiting()

  function switchDaiContractInstance(address daiContractAddress) public onlyOwner returns(bool) {
    DAIContract = IDai(daiContractAddress);
    return true;
  }

  function switchRDaiContractInstance(address rDaiContractAddress) public onlyOwner returns(bool) {
    rDAIContract = IRToken(rDaiContractAddress);
    return true;
  }


  ////////////////////////
  // internal functions //
  ////////////////////////

  function _mintRDai(uint256 depositAmount) internal returns(bool) {
    // dapp transfer user's DAI to itself
    require(depositAmount >= minimumDepositAmount, "Deposit amount should be equal to / greater than 200DAI");
    require(DAIContract.transferFrom(msg.sender, address(this), depositAmount), "Transfer DAI to Hoodie contract failed");
    // dapp approves rDAI contract to transfer dapp's DAI
    require(DAIContract.approve(address(rDAIContract), depositAmount), "approve() invalid");
    // dapp invoke mint() and get rDAI
    require(rDAIContract.mintWithSelectedHat(depositAmount, hatID), "minting failed");
    // dapp transfer rDAI to user
    require(rDAIContract.transferFrom(address(this), msg.sender, depositAmount), "Transfer rDAI to user failed");
    return true;
  }

  function _addUserToWaitingList(address userAddress, uint256 depositAmount) internal returns(bool) {
    // add user to waitingList
    users[userAddress] = User({
      userNumber: userWaitingNumber,
      depositedAmount: depositAmount,
      isWaiting: true
    });
    waitingList.push(userAddress);
    userWaitingNumber++;
    emit UserPushedIntoWaitingList(userAddress, depositAmount);
    return true;
  }
}