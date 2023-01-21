//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import {ERC20} from "./ERC20.sol";

contract DepositorCoin is ERC20{ 

    constructor () ERC20("Depositorcoin","DPC") {
        owner = msg.sender;
    }
    address public owner;

    function mint(address to, address amount) external{
        require(msg.sender == owner,"DPC: Only owner");
    }
}