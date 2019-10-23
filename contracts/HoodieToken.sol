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

  uint256 public hoodieReceivers = 0;
  uint256 public minimumDepositAmount = 1 * 10 ** 18; // for test
  uint256 public hoodieCost = 20 * 10 ** 18;

  uint256 public recipientNum = 0;
  address public nextInLine;
  address[] public waitingList;
  mapping(address => User) public users;

  event Deposited(address user, uint256 depositedAmount);
  event Redeemed(address user, uint256 newDepositedAmount);
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

  function depositDAI(uint256 depositAmount) public returns (bool) {
    User storage user = users[msg.sender];
    if(!user.hasDeposited) {
      // new user
      require(depositAmount >= minimumDepositAmount, "Deposit amount should be equal to / greater than 200DAI");
      require(_mintRDai(depositAmount), "mining rDAI failed");
      require(_addUserToWaitingList(msg.sender, depositAmount), "failded to add the user again to the waiting list");
    } else {
      // existing user
      require(_mintRDai(depositAmount), "mining rDAI failed");
      require(_topUpDAI(depositAmount), "failed to top up DAI");
    }
    if(user.waitingNumber == 0) nextInLine = msg.sender;
    emit Deposited(msg.sender, user.depositedAmount);
    return true;
  }

  function issueFDH() public returns (bool) {
    User storage user = users[nextInLine];
    // test
    require(rDAIContract.interestPayableOf(owner) > 0, "the interest amount has not reached 20 rDAI yet");

    // check whether or not the generated interest amount reached 20 rDAI
    // require(rDAIContract.interestPayableOf(owner) >= hoodieCost, "the interest amount has not reached 20 rDAI yet");

    // 0. check if a user is waiting or update the next in line
    require(_checkUserIsWaiting(nextInLine), "user is not in the waiting list");
    // 1. check whether or not a user has the hoodie hat
    require(_checkUserHat(nextInLine), "user does not have the hoodie hat");
    // 2. check whether or not a user's rDAI balance is the same as hoodie contract's
    uint256 rDaiBalanceOfUser = rDAIContract.balanceOf(nextInLine);
    require(rDaiBalanceOfUser >= user.depositedAmount, "user's rDAI balance is smaller than the hoodie contract's");
    // 3. invoke payInterest() to pay the rDAI(interest) to FlexDapps account
    require(rDAIContract.payInterest(owner), "failded payInterest()");
    // 4. update user's struct information
    require(_giveHoodieTo(nextInLine), "falied to give hoodie to the nextInLine");
    // 5. update the nextInLine
    require(_updateNextInLine(), "failded to update the next in line");
    emit IssuedFDH(nextInLine);
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
    emit Redeemed(msg.sender, user.depositedAmount);
    return true;
  }

  function switchDaiContractAddress(address daiContractAddress) public returns (bool) {
    require(msg.sender == owner, "only owner can invoke this function");
    DAIContract = IDai(daiContractAddress);
    return true;
  }

  function switchRDaiContractAddress(address rDaiContractAddress) public returns (bool) {
    require(msg.sender == owner, "only owner can invoke this function");
    rDAIContract = IRToken(rDaiContractAddress);
    return true;
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
    require(rDAIContract.mintWithSelectedHat(_depositAmount, hatID), "minting failed");
    // dapp transfer rDAI to user
    require(rDAIContract.transferFrom(address(this), msg.sender, _depositAmount), "Transfer rDAI to user failed");
    return true;
  }

  function _addUserToWaitingList(address _userAddress, uint256 _depositAmount) internal returns (bool) {
    users[_userAddress] = User({
      waitingNumber: _getNumberOfWaitingUsers(),
      numOfHoodie: 0,
      depositedAmount: _depositAmount,
      isWaiting: true,
      hasDeposited: true
    });
    waitingList.push(_userAddress);
    return true;
  }

  function _getNumberOfWaitingUsers() internal view returns (uint256) {
    uint256 i = 0;
    User memory _user;
    uint256 _waitingNumber = 0;
    for (i; i < waitingList.length; i++) {
      _user = users[waitingList[i]];
      if (_user.isWaiting) _waitingNumber++;
    }
    return _waitingNumber;
  }

  function _checkUserIsWaiting(address _userAddress) internal returns (bool) {
    User memory _user = users[_userAddress];
    while(!_user.isWaiting) {
      require(_updateNextInLine(), "failed to update the next in line");
      // if there is no waiting user, just invoke payInterest()
      if(recipientNum == waitingList.length) {
        require(rDAIContract.payInterest(owner), "failded payInterest()");
        return true;
      }
    }
    return true;
  }

  function _checkUserHat(address _userAddress) internal returns (bool) {
    uint256 _userHatId;
    address[] memory _recipientsFromUser;
    uint32[] memory _proportionsFromUser;

    (_userHatId, _recipientsFromUser, _proportionsFromUser) = rDAIContract.getHatByAddress(_userAddress);
    
    address _recipientFromUser = _recipientsFromUser[0];
    uint32 _proportionFromUser = _proportionsFromUser[0];

    require(_userHatId == hatID, "user does not have the same hat as the hoodie contract's");
    require(_recipientFromUser == owner, "No much with the owner address");
    require(_proportionFromUser == 2 ** 32 - 1, "No much with the proportion");

    return true;
  }

  function _topUpDAI(uint256 _depositAmount) internal returns (bool) {
    User storage _user = users[msg.sender];
    _user.depositedAmount = _user.depositedAmount.add(_depositAmount);
    if(_user.depositedAmount >= minimumDepositAmount && !_user.isWaiting) {
      _user.waitingNumber = _getNumberOfWaitingUsers();
      _user.isWaiting = true;
    }
    return true;
  }

  function _giveHoodieTo(address _userAddress) internal returns (bool) {
    User storage _user = users[_userAddress];
    _user.waitingNumber = _getNumberOfWaitingUsers();
    _user.numOfHoodie++;
    hoodieReceivers++;
    return true;
  }

  function _updateNextInLine() internal returns (bool) {
    uint256 i = 0;
    User memory _user;
    uint256 _min = waitingList.length;
    for (i; i < waitingList.length; i++) {
      _user = users[waitingList[i]];

      if (_user.isWaiting && _user.waitingNumber < _min) {
        _min = _user.waitingNumber;
        nextInLine = waitingList[i];
      }
    }
    return true;
  }
}