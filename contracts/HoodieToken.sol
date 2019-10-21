pragma solidity ^0.5.0;
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
// import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./IDai.sol";
import "./IRToken.sol";

contract HoodieToken {
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
  address public owner;
  address[] public recipients;
  uint32[] public proportions = [100];
  bool public doChangeHat = false;

  uint256 public minimumDepositAmount = 1 * 10 ** 18; // for test
  uint256 public hoodieCost = 20 * 10 ** 18;

  uint256 public waitingUserNumber = 0;
  uint256 public nextWaitingUserNum = 0;
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
    owner = msg.sender;
    recipients.push(owner);
    DAIContract = IDai(0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa);
    rDAIContract = IRToken(0xb0C72645268E95696f5b6F40aa5b12E1eBdc8a5A); // before
    // rDAIContract = IRToken(0x4f3E18CEAbe50E64B37142c9655b3baB44eFF578); // latest
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

    // update the mostDeposted
    if (user.depositedAmount > mostDeposited) {
      mostDeposited = user.depositedAmount;
      nextInLine = msg.sender;
    }

    // user can be back to the waiting list when the depositedAmount is more than the minimumDepositAmount
    if(user.depositedAmount >= minimumDepositAmount && !user.isWaiting) {
      user.isWaiting = true;
      if (user.depositedAmount > mostDeposited) {
        mostDeposited = user.depositedAmount;
        nextInLine = msg.sender;
      }

      // if the round number was updated while a user was away from the waiting list,
      // the user's rNumber and the waitingUserNumber should be updated as well
      if(user.rNumber < roundNumber) {
        user.rNumber = roundNumber;
        waitingUserNumber++;
      } else if (user.rNumber == roundNumber) {
        waitingUserNumber++;
      } else {
        nextWaitingUserNum++;
      }
    }
    emit IncreasedDeposit(msg.sender, user.depositedAmount);
    return true;
  }

  function issueFDH() public returns(bool) {
    // test
    require(rDAIContract.interestPayableOf(owner) > 0, "the interest amount has not reached 20 rDAI yet");

    // check whether or not the generated interest amount reached 20 rDAI
    // require(rDAIContract.interestPayableOf(owner) >= hoodieCost, "the interest amount has not reached 20 rDAI yet");

    User storage user = users[nextInLine];
    // 1. check whether or not a user has the hoodie hat
    uint256 userHatId;
    (userHatId,,) = rDAIContract.getHatByAddress(nextInLine);
    require(userHatId == hatID, "user does not have the same hat as the hoodie contract's");

    // 2. check whether or not a user's rDAI balance is the same as hoodie contract's
    uint256 rDaiBalanceOfUser = rDAIContract.balanceOf(nextInLine);
    require(rDaiBalanceOfUser >= user.depositedAmount, "user's rDAI balance is smaller than the hoodie contract's");

    // 3. invoke payInterest() to pay the rDAI(interest) to FlexDapps account
    require(rDAIContract.payInterest(owner), "failded payInterest()");

    // user goes to the next round waiting list and is added to the next round waiting list
    user.numOfHoodie++;
    user.rNumber++;
    nextWaitingUserNum++;
    hoodieReceivers++;
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

    // update round number when the number of hoodie receivers is equal to the waiting user number
    if (hoodieReceivers == waitingUserNumber) {
      roundNumber++;
      hoodieReceivers = 0;
      waitingUserNumber = nextWaitingUserNum;
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

    // if user's depositedAmount become below than the minimumDepositAmount, it will be removed from the waiting list
    if (user.depositedAmount < minimumDepositAmount) {
      user.isWaiting = false;

      if(user.rNumber == roundNumber) {
      // update the waiting user number of the current waiting list
        waitingUserNumber--;
      } else if (user.rNumber > roundNumber) {
      // update the waiting user number of the next waiting list
        nextWaitingUserNum--;
      }
    }
    /// if this user was nextInLine, we may need to set a new nextInLine
    emit RedeemedRDai(msg.sender, user.depositedAmount);
    return true;
  }

  // function updateNextInLine() public returns (bool) {
  //   if(

  //   )
  // }

  function switchDaiContractInstance(address daiContractAddress) public returns(bool) {
    require(msg.sender == owner, "only owner can invoke this function");
    DAIContract = IDai(daiContractAddress);
    return true;
  }

  function switchRDaiContractInstance(address rDaiContractAddress) public returns(bool) {
    require(msg.sender == owner, "only owner can invoke this function");
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
    waitingUserNumber++;
    return true;
  }
}