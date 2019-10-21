pragma solidity ^0.5.0;
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./IDai.sol";
import "./IRToken.sol";

contract HoodieToken is Ownable {
  using SafeMath for uint256;

  struct User {
    uint256 numOfHoodie;
    uint256 rNumber;
    uint256 depositedAmount;
    bool isWaiting;
    bool hasDeposited;
  }
  // Instantiate DAIContract with DAI address on rinkeby
  // Instantiate rDAIContract with rDAI address on rinkeby
  IDai public DAIContract;
  IRToken public rDAIContract;

  // Hat setting
  uint256 public hatID;
  address public recipient = owner();
  uint32 public proportion = 100;
  address[] public recipients = [recipient];
  uint32[] public proportions = [proportion];
  bool public doChangeHat = false;

  uint256 public minimumDepositAmount = 1 * 10 ** 18; // for test
  uint256 public hoodieCost = 20 * 10 ** 18;

  uint256 public roundNumber = 0;
  uint256 public hoodieReceivers = 0;
  uint256 public mostDeposited = 0;
  address public nextInLine = address(0);
  address[] public waitingList;
  mapping(address => User) public users;

  event UserPushedIntoWaitingList(address user, uint256 depositedAmount, uint256 roundNumber);
  event IssuedFDH(address recipientOfHoodie);
  event NewRoundStarted(uint256 newRountNumber);
  event IncreasedDeposit(address user, uint256 newDepositedAmount);
  event RedeemedRDai(address user, uint256 newDepositedAmount);

  constructor() public {
    DAIContract = IDai(0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa);
    rDAIContract = IRToken(0xb0C72645268E95696f5b6F40aa5b12E1eBdc8a5A);
    hatID = rDAIContract.createHat(recipients, proportions, doChangeHat);
  }

  function getWaitingList() public view returns(address[] memory) {
    return waitingList;
  }

  function mintRDaiAndPushUserToWaitingList(uint256 depositAmount) public returns(bool) {
    require(depositAmount >= minimumDepositAmount, "Deposit amount should be equal to / greater than 200DAI");
    // check whether or not the user is new
    require(!users[msg.sender].isWaiting, "This user is existing in the waiting list");
    // mint rDAI and transfer it to user
    require(_mintRDai(depositAmount), "mining rDAI failed");
    // add user to waitingList
    require(_addUserToWaitingList(msg.sender, depositAmount), "failded to add the user again to the waiting list");
    if (depositAmount > mostDeposited) {
      mostDeposited = depositAmount;
      nextInLine = msg.sender;
    }
    emit UserPushedIntoWaitingList(msg.sender, depositAmount, users[msg.sender].rNumber);
    return true;
  }

  function increaseDepositAmount(uint256 topUpAmount) public returns(bool) {
    // mint additional rDAI
    require(_mintRDai(topUpAmount),  "mining rDAI failed");
    // update user's deposited amount in User struct
    User storage user = users[msg.sender];
    user.depositedAmount = user.depositedAmount.add(topUpAmount);
    if(user.depositedAmount >= 200 * 10 ** 18 && !user.isWaiting) {
      user.isWaiting = true;
      if (user.depositedAmount > mostDeposited) {
        mostDeposited = user.depositedAmount;
        nextInLine = msg.sender;
      }
    }
    emit IncreasedDeposit(msg.sender, user.depositedAmount);
    return true;
  }

  function issueFDH() public returns(bool) {
    // test
    require(rDAIContract.interestPayableOf(owner()) > 0, "the interest amount has not reached 20 rDAI yet");

    // check whether or not the generated interest amount reached 20 rDAI
    // require(rDAIContract.interestPayableOf(owner()) >= hoodieCost, "the interest amount has not reached 20 rDAI yet");

    // user goes to the next round waiting list
    // add the user to the next round waiting list
    User storage user = users[nextInLine];
    user.numOfHoodie++;
    user.rNumber++;
    emit IssuedFDH(nextInLine);

    // OFF CHAIN BACKEND LOGIC
    // update nextInLine to be the person who has deposited the next most
    // update mostDeposited to be equal to the deposit of nextInLine
    // uint256 _max = 0;
    // address _next = address(0);

    // for (uint256 i = 0; i < waitingList.length; i++) {
    //   if (
    //       users[waitingList[i]].rNumber == roundNumber &&
    //       users[waitingList[i]].isWaiting &&
    //       _max < users[waitingList[i]].depositedAmount
    //     )
    //     {
    //       _max = users[waitingList[i]].depositedAmount;
    //       _next = waitingList[i];
    //     } else {
    //       _max = users[waitingList[i]].depositedAmount;
    //       _next = waitingList[i];
    //     }
    // }
    // mostDeposited = _max;
    // nextInLine = _next;
    // hoodieReceivers++;

    // update round number here
    if (hoodieReceivers == waitingList.length) {
      roundNumber++;
      hoodieReceivers = 0;
      emit NewRoundStarted(roundNumber);

    //   // find the next receiver in the new round
    //   for (uint i = 0; i < waitingList.length; i++) {
    //     if (
    //         users[waitingList[i]].rNumber == roundNumber &&
    //         users[waitingList[i]].isWaiting &&
    //         _max < users[waitingList[i]].depositedAmount
    //       )
    //       {
    //         _max = users[waitingList[i]].depositedAmount;
    //         _next = waitingList[i];
    //       } else {
    //         _max = users[waitingList[i]].depositedAmount;
    //         _next = waitingList[i];
    //       }
    //   }
    //   mostDeposited = _max;
    //   nextInLine = _next;
    //   hoodieReceivers++;
    }

    return true;
  }

  function redeemRDai(uint256 redeemAmount) public returns (bool) {
    User storage user = users[msg.sender];
    // check whether or not the user has enough rDAI to redeem
    require(user.depositedAmount >= redeemAmount, "insufficient amount of rDAI");
    // transfer rDAI from user's account to Hoodie contract
    require(rDAIContract.transferFrom(msg.sender, address(this), redeemAmount), "Transfer rDAI to Hoodie contract failed");
    // 1) use redeem()
    // 2) dapp transfer rDAI to user
    // 3) decrese the state of user.depositedAmount - redeemAmount
    require(rDAIContract.redeem(redeemAmount), "redeem() failed");
    require(DAIContract.transfer(msg.sender, redeemAmount), "Transfer DAI to user failed");
    user.depositedAmount = user.depositedAmount.sub(redeemAmount);
    // if user's depositedAmount become below than 200 rDAI, it will be removed from the waiting list
    if (user.depositedAmount < 200 * 10 ** 18) {
      user.isWaiting = false;
    }
    /// if this user was nextInLine, we may need to set a new nextInLine
    emit RedeemedRDai(msg.sender, user.depositedAmount);
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
    User memory _oldUser = users[userAddress];
    users[userAddress] = User({
      numOfHoodie: 0,
      depositedAmount: depositAmount,
      rNumber: roundNumber,
      isWaiting: true,
      hasDeposited: true
    });
    if (!_oldUser.hasDeposited) {
      waitingList.push(userAddress);
    }
    return true;
  }
}