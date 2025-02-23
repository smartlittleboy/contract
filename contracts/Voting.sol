// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 
import "hardhat/console.sol";
import "../tool/Counters.sol";

contract Voting {
    using Counters for Counters.Counter;

    Counters.Counter public _voterId;
    Counters.Counter public _candidateId;
    
}








