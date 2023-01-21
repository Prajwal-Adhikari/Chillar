//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./ERC20.sol";
import "./DepositorCoin.sol";

contract StableCoin is ERC20{
    constructor() ERC20("StableCoin","STC") {}

}