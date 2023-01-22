//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Oracle{
    address public owner;   //this owner can only update the price of the ether
    uint256 private price;

    constructor(){
        owner = msg.sender;
    }
    //Oracle tell me the price
    function getPrice() external view returns(uint256){
        return price;
    }

    //Oracle set this price
    function setPrice(uint256 newEthPrice) external{
        require(msg.sender == owner,"Oracle: Only owner");
        price = newEthPrice;
    }
    
}