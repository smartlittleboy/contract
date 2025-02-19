
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
// import "contracts/IERC20.sol";
import "./IERC20.sol";

contract Valut {
  IERC20 public immutable token;
  uint public totalSupply;
  mapping(address => uint) public balanceOf;

  constructor(address _token){
    token = IERC20(_token);
  }

  //内部函数，把金额增加到totalSupply上，记录用户share的增加
  function _mint(address _to, uint _amount) private{
     totalSupply += _amount;
     balanceOf[_to] += _amount;
  }

   //用户提款的时候
  function _burn(address _from, uint _amount) private{
     totalSupply -= _amount;
     balanceOf[_from] -= _amount;
  }

  function deposit(uint _amount) external {
    /*
      a = amount
      B = balance of token before deposit
      T = total supply
      s = shares to mit

      (T + s) / T = (a + B) / B
       s = aT / B
    */

    uint shares;
    if(totalSupply == 0){
        shares = _amount;
    }else {
       shares = (_amount * totalSupply) / token.balanceOf(address(this));
    }
    _mint(msg.sender, shares);
    //把token转到合约上面来
    token.transferFrom(msg.sender, address(this), _amount);
  }

  function withdraw(uint _shares) external {
    /*
      a = amount
      B = balance of token before deposit
      T = total supply
      s = shares to mit

      (T - s) / T = (B - a) / B
       a = sB / T
    */
    uint amount = _shares * token.balanceOf(address(this)) / totalSupply;
    _burn(msg.sender, _shares);
    token.transfer(msg.sender, amount);
  } 





}

