pragma solidity ^0.5.0;
import "./IRToken.sol";

contract HoodieToken {
  // RToken address on rinkeby
  address RTokenAddress = 0x4f3E18CEAbe50E64B37142c9655b3baB44eFF578;
  IRToken rTokenContract = IRToken(RTokenAddress);

  // Basic set up for FDH
  string public name = "Flex Dapps Hoodie Token";
  string public symbol = "FDH";
  string public standard = "FDH Token v1.0";
  uint public totalSupply;

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint _value
  );

  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint _value
  );

  mapping(address => uint) public balanceOf;
  mapping(address => mapping(address => uint)) public allowance;

  constructor(uint _initialSupply) public {
    balanceOf[msg.sender] = _initialSupply;
    totalSupply = _initialSupply;
  }

  function transfer(address _to, uint _value) public returns (bool success) {
    require(balanceOf[msg.sender] >= _value, "The value should be smaller than or equal to the balance");

    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;

    emit Transfer(msg.sender, _to, _value);

    return true;
  }

  function approve(address _spender, uint _value) public returns (bool success) {
    allowance[msg.sender][_spender] = _value;

    emit Approval(msg.sender, _spender, _value);

    return true;
  }

  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    require(_value <= balanceOf[_from], "The value should be smaller than or equal to the owner's balance");
    require(_value <= allowance[_from][msg.sender], "The value should be smaller than or equal to the balance that the owner allowed");
    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;

    allowance[_from][msg.sender] -= _value;

    emit Transfer(_from, _to, _value);

    return true;
  }
}