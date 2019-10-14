pragma solidity ^0.5.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./IDai.sol"; 
import "./ICErc20.sol"; 
import "./IRToken.sol";

contract HoodieToken {
  // Basic set up for FDH
  string public name = "Flex Dapps Hoodie Token";
  string public symbol = "FDH";
  string public standard = "FDH Token v1.0";
  uint256 public totalSupply;
  address public owner;
  uint256 public balanceOfDai;

  // Instantiate DAIContract with DAI address on rinkeby
  address DAIAddress = 0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa;
  IDai public DAIContract = IDai(DAIAddress);
  
  // Instantiate cDAIContract with cDAI address on rinkeby
  address cDAIAddress = 0x6D7F0754FFeb405d23C51CE938289d4835bE3b14;
  ICErc20 public cDAIContract = ICErc20(cDAIAddress);

  //  Instantiate rDAIContract with rDAI address on rinkeby
  address rDAIAddress = 0xb0C72645268E95696f5b6F40aa5b12E1eBdc8a5A;
  IRToken public rDAIContract = IRToken(rDAIAddress);

  // events
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  event Depositted(address indexed sender, uint256 depositedAmount);

  // number of FDH
  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;
  mapping(address => uint256) depositedAmount;

  // Hat variables
  uint256 public hatID;
  address public recipient = 0x2471e35F51CF54265B20cCFAc3857c2DceEf7349;
  uint32 public proportion = 100;
  address[] public recipients = [recipient];
  uint32[] public proportions = [proportion];
  bool public doChangeHat = false;

  constructor(uint256 _initialSupply) public {
    owner = msg.sender;
    totalSupply = _initialSupply;
    balanceOf[msg.sender] = _initialSupply;
    balanceOfDai = DAIContract.balanceOf(msg.sender);
    hatID = rDAIContract.createHat(recipients, proportions, doChangeHat);
  }

  function transfer(address _to, uint256 _value) public payable returns (bool success) {
    require(balanceOf[msg.sender] >= _value, "The value should be smaller than or equal to the balance");
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public payable returns (bool success) {
    require(_value <= balanceOf[_from], "The value should be smaller than or equal to the owner's balance");
    require(_value <= allowance[_from][msg.sender], "The value should be smaller than or equal to the balance that the owner allowed");
    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
    allowance[_from][msg.sender] -= _value;
    emit Transfer(_from, _to, _value);
    return true;
  }
}