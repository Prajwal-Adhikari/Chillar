//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import {ERC20} from "./ERC20.sol";

contract DepositorCoin is ERC20 {
    constructor() ERC20("Depositorcoin", "DPC") {
        owner = msg.sender;
    }

    address public owner;

    function mint(address to, uint256 amount) external {
        require(msg.sender == owner, "DPC: Only owner can mint");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external{
        require(msg.sender == owner,"DPC: Only owner can burn");
        _burn(from,amount);
    }
}
