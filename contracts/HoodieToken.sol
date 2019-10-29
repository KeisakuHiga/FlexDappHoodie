pragma solidity ^0.5.8;
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./IDai.sol";
import "./IRToken.sol";

contract HoodieToken {
  using SafeMath for uint256;

  address public admin;

  struct User {
    address userAddress;
    uint256 daiDeposited;
    bool isWaiting;
    bool hasDeposited;
    uint256 hoodiesReceived;
  }

  // Instantiate DAIContract with DAI address on rinkeby
  // Instantiate rDAIContract with rDAI address on rinkeby
  IDai public DAIContract;
  IRToken public rDAIContract;

  // Hat setting (rDAI settings)
  struct Hat {
    uint256 id;
    address owner;
    address[] recipients;
    uint32[] proportions;
    bool allowChange;
  }
  Hat rDaiHat;

  uint256 public totalDaiDeposited = 0;
  uint256 public totalHoodiesIssued = 0;
  uint256 public minimumDaiDepositAmount = 1 * 10 ** 18; // for test
  uint256 public interestRequiredForHoodie = 20 * 10 ** 18;

  uint256 public totalWaitingUsers = 0;
  uint256 public nextRecipientIndex = 1;
  uint256 public nextQueuePosition = 1;
  mapping(address => uint256) public userQueuePositions;
  mapping(uint256 => User) public users;

  event Deposit(address user, uint256 daiDeposited);
  event Redeem(address user, uint256 newDaiDeposited);
  event IssueHoodie(address recipient);

  constructor(address _daiAddress, address _rDaiAddress) public {
    admin = msg.sender;
    DAIContract = IDai(_daiAddress);
    rDAIContract = IRToken(_rDaiAddress);

    rDaiHat.owner = admin;
    rDaiHat.recipients.push(admin);
    rDaiHat.proportions.push(100);
    rDaiHat.allowChange = false;
    rDaiHat.id = rDAIContract.createHat(rDaiHat.recipients, rDaiHat.proportions, rDaiHat.allowChange);
  }

  function depositDai(uint256 depositAmount) public returns (bool) {
    uint256 userPosition = userQueuePositions[msg.sender];
    User memory user = users[userPosition];
    if(!user.hasDeposited) {
      // new user
      require(depositAmount >= minimumDaiDepositAmount, "Deposit amount should be equal to / greater than 200DAI");
      require(_mintRDai(depositAmount), "mining rDAI failed");
      require(_addNewUserToQueue(depositAmount), "failded to add the user again to the waiting list");
    } else {
      // existing user
      require(_mintRDai(depositAmount), "failed to mint rDAI");
      require(_topUpDai(depositAmount), "failed to top up DAI");
    }
    emit Deposit(msg.sender, depositAmount);
    return true;
  }

  function redeemRDai(uint256 redeemAmount) public returns (bool) {
    uint256 userPosition = userQueuePositions[msg.sender];
    User storage user = users[userPosition];
    // check whether or not the user has enough rDAI to redeem
    require(user.daiDeposited >= redeemAmount, "insufficient amount of rDAI");
    // transfer rDAI from user's account to Hoodie contract
    require(rDAIContract.transferFrom(msg.sender, address(this), redeemAmount), "Transfer rDAI to Hoodie contract failed");
    // use redeem => transfer rDAI to user => update user info
    require(rDAIContract.redeem(redeemAmount), "redeem() failed");
    require(DAIContract.transfer(msg.sender, redeemAmount), "Transfer DAI to user failed");
    user.daiDeposited = user.daiDeposited.sub(redeemAmount);
    totalDaiDeposited = totalDaiDeposited.sub(redeemAmount);

    // if user's daiDeposited become below than the minimumDaiDepositAmount, it will be removed from the waiting list
    if (user.daiDeposited < minimumDaiDepositAmount) {
      user.isWaiting = false;
      totalWaitingUsers--;
    }
    emit Redeem(msg.sender, user.daiDeposited);
    return true;
  }

  function issueHoodie() public returns (bool) {
    // check the user is waiting and if not, the next user will become the recipient
    bool nextRecipientExists = _setNextRecipient();
    if (!nextRecipientExists) {
      require(rDAIContract.payInterest(admin), "failded payInterest()");
      return true;
    } else {
      User storage recipient = users[nextRecipientIndex];
      // test
      require(rDAIContract.interestPayableOf(admin) > 0, "the interest amount has not reached 20 rDAI yet");
      // check whether or not the generated interest amount reached 20 rDAI
      // require(rDAIContract.interestPayableOf(admin) >= interestRequiredForHoodie, "the interest amount has not reached 20 rDAI yet");

      require(_validateUserHatAndRDaiBalance(recipient.userAddress), "user does not have the hoodie hat");
      require(rDAIContract.payInterest(admin), "failded payInterest()");

      // give a hoodie to the recipient and increment the global variables
      recipient.hoodiesReceived++;
      totalHoodiesIssued++;
      nextRecipientIndex++;

      // set user as the last position of the waiting list
      require(_moveUserToBackOfQueue(recipient), "failed to update user info");

      emit IssueHoodie(recipient.userAddress);
      return true;
    }
  }

  function updateDaiContractAddress(address daiContractAddress) public returns (bool) {
    require(msg.sender == admin, "only owner can invoke this function");
    DAIContract = IDai(daiContractAddress);
    return true;
  }

  function updateRDaiContractAddress(address rDaiContractAddress) public returns (bool) {
    require(msg.sender == admin, "only owner can invoke this function");
    rDAIContract = IRToken(rDaiContractAddress);
    return true;
  }

  function getNextRecipientAddress() public view returns (address) {
    return users[nextRecipientIndex].userAddress;
  }

  ////////////////////////
  // internal functions //
  ////////////////////////

  function _mintRDai(uint256 _depositAmount) internal returns (bool) {
    // dapp transfer user's DAI to itself
    require(DAIContract.transferFrom(msg.sender, address(this), _depositAmount), "Transfer DAI to Hoodie contract failed");
    // dapp approves rDAI contract to transfer dapp's DAI
    require(DAIContract.approve(address(rDAIContract), _depositAmount), "approve() invalid");
    // dapp invoke mint() and get rDAI
    require(rDAIContract.mintWithSelectedHat(_depositAmount, rDaiHat.id), "minting failed");
    // dapp transfer rDAI to user
    require(rDAIContract.transferFrom(address(this), msg.sender, _depositAmount), "Transfer rDAI to user failed");
    return true;
  }

  function _addNewUserToQueue(uint256 _depositAmount) internal returns (bool) {
    userQueuePositions[msg.sender] = nextQueuePosition;
    users[nextQueuePosition] = User({
      userAddress: msg.sender,
      daiDeposited: _depositAmount,
      isWaiting: true,
      hasDeposited: true,
      hoodiesReceived: 0
    });
    totalDaiDeposited = totalDaiDeposited.add(_depositAmount);
    totalWaitingUsers++;
    nextQueuePosition++;
    return true;
  }

  function _topUpDai(uint256 _depositAmount) internal returns (bool) {
    uint256 userNumber = userQueuePositions[msg.sender];
    User storage _user = users[userNumber];
    _user.daiDeposited = _user.daiDeposited.add(_depositAmount);

    if(_user.daiDeposited >= minimumDaiDepositAmount && !_user.isWaiting) {
      require(_moveUserToBackOfQueue(_user), "failed to update user info");
      totalWaitingUsers++;
    }
    totalDaiDeposited = totalDaiDeposited.add(_depositAmount);
    return true;
  }

  function _moveUserToBackOfQueue(User memory _user) internal returns (bool) {
    userQueuePositions[_user.userAddress] = nextQueuePosition;
    users[nextQueuePosition] = User({
      userAddress: _user.userAddress,
      daiDeposited: _user.daiDeposited,
      isWaiting: true,
      hasDeposited: true,
      hoodiesReceived: _user.hoodiesReceived
    });
    nextQueuePosition++;
    return true;
  }

  function _validateUserHatAndRDaiBalance(address _userAddress) internal view returns (bool) {
    uint256 _userPosition = userQueuePositions[_userAddress];
    User memory _user = users[_userPosition];

    // 1. check whether or not a user has the hoodie hat
    uint256 _userHatId;
    address[] memory _userHatRecipients;
    uint32[] memory _userHatProportions;

    (_userHatId, _userHatRecipients, _userHatProportions) = rDAIContract.getHatByAddress(_userAddress);

    address _firstUserHatRecipient = _userHatRecipients[0];
    uint32 _firstUserHatProportion = _userHatProportions[0];

    require(_userHatId == rDaiHat.id, "user does not have the same hat as the hoodie contract's");
    require(_firstUserHatRecipient == rDaiHat.owner, "No much with the owner address");
    require(_firstUserHatProportion == 2 ** 32 - 1, "No much with the proportion");

    // 2. check whether or not a user's rDAI balance is the same as hoodie contract's
    uint256 _userRDaiBalance = rDAIContract.balanceOf(_userAddress);
    require(_userRDaiBalance >= _user.daiDeposited, "user's rDAI balance is smaller than the hoodie contract's");

    return true;
  }

  function _setNextRecipient() internal returns (bool) {
    uint256 i = nextRecipientIndex;
    for (i; i <= nextQueuePosition; i++) {
      User memory user = users[i];
      if (user.isWaiting && i == nextRecipientIndex) {
        return true;
      } else if (user.isWaiting && i != nextRecipientIndex) {
        nextRecipientIndex = i;
        return true;
      }
    }
    nextRecipientIndex = nextQueuePosition;
    return false;
  }
}