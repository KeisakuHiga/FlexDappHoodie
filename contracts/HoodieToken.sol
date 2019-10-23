pragma solidity ^0.5.8;
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./IDai.sol";
import "./IRToken.sol";

contract HoodieToken {
  using SafeMath for uint256;

  struct User {
    uint256 waitingNumber;
    uint256 numOfHoodie;
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
  uint32[] public proportions;
  bool public doChangeHat = true;

  uint256 public minimumDepositAmount = 1 * 10 ** 18; // for test
  uint256 public hoodieCost = 20 * 10 ** 18;

  uint256 public hoodieReceivers = 0;
  uint256 public recipientNum = 0;
  address public nextInLine;
  address[] public waitingList;
  mapping(address => User) public users;

  event UserPushedIntoWaitingList(address user, uint256 depositedAmount);
  event IncreasedDeposit(address user, uint256 newDepositedAmount);
  event RedeemedRDai(address user, uint256 newDepositedAmount);
  event IssuedFDH(address recipient);

  constructor() public {
    owner = msg.sender;
    recipients.push(owner);
    proportions.push(100);
    DAIContract = IDai(0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa);
    rDAIContract = IRToken(0x6AA5c6aB94403Bdbbf74f21607D46Be631E6CcC5);
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

    emit UserPushedIntoWaitingList(msg.sender, depositAmount);
    return true;
  }

  function increaseDepositAmount(uint256 topUpAmount) public returns(bool) {
    // mint additional rDAI
    require(_mintRDai(topUpAmount),  "mining rDAI failed");
    // update user's deposited amount in User struct
    User storage user = users[msg.sender];
    user.depositedAmount = user.depositedAmount.add(topUpAmount);

    // user can be back to the waiting list when the depositedAmount is more
    // than the minimumDepositAmount and be given a new waiting number
    if(user.depositedAmount >= minimumDepositAmount && !user.isWaiting) {
      user.isWaiting = true;
      user.waitingNumber = waitingList.length;
      waitingList.push(msg.sender);
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
    // 0. user isWaiting ture?
    while(!user.isWaiting) {
      recipientNum++;
      // if there is no waiting user, just invoke payInterest()
      if(recipientNum == waitingList.length) {
        require(rDAIContract.payInterest(owner), "failded payInterest()");
        return true;
      }
      nextInLine = waitingList[recipientNum];
      user = users[nextInLine];
    }

    // 1. check whether or not a user has the hoodie hat
    uint256 userHatId;
    address[] memory recipientsFromUser;
    uint32[] memory proportionsFromUser;
    (userHatId, recipientsFromUser, proportionsFromUser) = rDAIContract.getHatByAddress(nextInLine);
    address recipientFromUser = recipientsFromUser[0];
    uint32 proportionFromUser = proportionsFromUser[0];

    require(userHatId == hatID, "user does not have the same hat as the hoodie contract's");
    require(recipientFromUser == owner, "No much with the owner address");
    require(proportionFromUser == 2 ** 32 - 1, "No much with the proportion");

    // 2. check whether or not a user's rDAI balance is the same as hoodie contract's
    uint256 rDaiBalanceOfUser = rDAIContract.balanceOf(nextInLine);
    require(rDaiBalanceOfUser >= user.depositedAmount, "user's rDAI balance is smaller than the hoodie contract's");

    // 3. invoke payInterest() to pay the rDAI(interest) to FlexDapps account
    require(rDAIContract.payInterest(owner), "failded payInterest()");

    // user gets a hoodie
    user.numOfHoodie++;
    hoodieReceivers++;
    user.waitingNumber = waitingList.length;
    emit IssuedFDH(nextInLine);

    // add the user to the waitingList as the last person
    waitingList.push(nextInLine);

    // update the nextInLine
    recipientNum++;
    nextInLine = waitingList[recipientNum];

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
    }
    emit RedeemedRDai(msg.sender, user.depositedAmount);
    return true;
  }

  function switchDaiContractAddress(address daiContractAddress) public returns(bool) {
    require(msg.sender == owner, "only owner can invoke this function");
    DAIContract = IDai(daiContractAddress);
    return true;
  }

  function switchRDaiContractAddress(address rDaiContractAddress) public returns(bool) {
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
    users[userAddress] = User({
      waitingNumber: waitingList.length,
      numOfHoodie: 0,
      depositedAmount: depositAmount,
      isWaiting: true,
      hasDeposited: true
    });
    waitingList.push(userAddress);
    if(users[userAddress].waitingNumber == recipientNum) {
      nextInLine = waitingList[recipientNum];
    }
    return true;
  }
}