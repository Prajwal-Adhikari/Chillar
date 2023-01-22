//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC20} from "./ERC20.sol";
import {DepositorCoin} from "./DepositorCoin.sol";
import {Oracle} from "./Oracle.sol";

contract StableCoin is ERC20 {

    DepositorCoin public depositorCoin;
    Oracle public oracle;

    uint256 public feeRatePercentage;
    uint256  public constant INITIAL_COLLATERAL_RATIO_PERCENTAGE  = 10;
    constructor(uint256 _feeRatePercentage, Oracle _oracle) ERC20("StableCoin", "STC") {
        feeRatePercentage = _feeRatePercentage;
        oracle = _oracle;
    }

    //send ether to the contract and get the actual stablecoin      --mint
    function mint() external payable {
        uint256 fee = _getfee(msg.value);
        uint256 remainingEth = msg.value - fee;
         
        uint256 mintStableCoinAmount = msg.value * oracle.getPrice();    //wtf 
        _mint(msg.sender, mintStableCoinAmount);
    }


    //burn stableCoins
    function burn(uint256 burnStableCoinAmount) external{
        int256 deficitOrSurplusInUsd = _getDeficitOrSurplusInContractInUsd();
        require(deficitOrSurplusInUsd >= 0,"STC: Cannot burn while in deficit");
        _burn(msg.sender,burnStableCoinAmount);
        //calculating how much ETH the burner will get
        uint256 refundingEth = burnStableCoinAmount / oracle.getPrice();
        uint256 fee = _getfee(refundingEth);
        uint256 remainingRefundingEth = refundingEth - fee;
        
        (bool success,) = msg.sender.call{value:remainingRefundingEth}("");
        require(success,"STC: Burn refund transaction failed");
    }

    function _getfee(uint256 ethAmount) private view returns(uint256){
        bool hasDepositors = address(depositorCoin) != address(0) && depositorCoin.totalSupply() > 0;
        if(!hasDepositors){
            return 0;
        }
        return (feeRatePercentage * ethAmount) / 100;
    }


    function depositCollateralBuffer() external payable{
        int256 deficitOrSurplusInUsd = _getDeficitOrSurplusInContractInUsd();
        if(deficitOrSurplusInUsd <= 0){
            uint256 deficitInUsd = uint(deficitOrSurplusInUsd * -1);
            uint256 usdPriceInEth = oracle.getPrice();
            uint256 deficitInEth = deficitInUsd / usdPriceInEth ;

            uint256 requiredInitialSurplusInUsd = (INITIAL_COLLATERAL_RATIO_PERCENTAGE * ERC20.totalSupply()) / 100;

            uint256 requiredInitialSurplusInEth = requiredInitialSurplusInUsd / usdPriceInEth;

            require(msg.value >= deficitInEth + requiredInitialSurplusInEth,"STC: Initial collateral ratio not met");

            uint256 newInitialSurplusInEth = msg.value - deficitInEth;
            uint256 newInitialSurplusInUsd = newInitialSurplusInEth * usdPriceInEth;


            depositorCoin  = new DepositorCoin();
            uint256 mintDepositorCoinAmount = newInitialSurplusInUsd;
            depositorCoin.mint(msg.sender,mintDepositorCoinAmount);
 
            return;
        }
        uint256 surplusInUsd = uint256(deficitOrSurplusInUsd);
        uint256 dpcInUsdPrice = _getDPCinUsdPrice(surplusInUsd);
        uint256 mintDepositorCoinAmount = (msg.value * dpcInUsdPrice) / oracle.getPrice();
        depositorCoin.mint(msg.sender,mintDepositorCoinAmount);
    }


    function withdrawCollateralBuffer(uint256 burnDepositorCoinAmount) external {
        require(depositorCoin.balanceOf(msg.sender) >= burnDepositorCoinAmount,"STC: Sender has insufficient DPC funds");
        depositorCoin.burn(msg.sender,burnDepositorCoinAmount);
        int256 deficitOrSurplusInUsd = _getDeficitOrSurplusInContractInUsd();
        require(deficitOrSurplusInUsd > 0,"STC: No funds to withdraw");
        uint256 surplusInUsd = uint256(deficitOrSurplusInUsd);
        uint dpcInUsdPrice = _getDPCinUsdPrice(surplusInUsd);
        uint256 refundingInUsd = burnDepositorCoinAmount / dpcInUsdPrice;   //again wtf
        uint256 refundingEth = refundingInUsd / oracle.getPrice();  
        (bool success,) = msg.sender.call{value:refundingEth}("");
        require(success,"STC: Withdraw refund transaction failed");

    }



    function _getDeficitOrSurplusInContractInUsd() private view returns(int256){
        uint256 ethContractBalanceInUsd = (address(this).balance - msg.value) * oracle.getPrice();
        uint256 totalStableCoinBalanceInUsd = ERC20.totalSupply(); 
        int256 deficitOrSurplus = int256(ethContractBalanceInUsd - totalStableCoinBalanceInUsd); 
        return deficitOrSurplus;
    }

    function _getDPCinUsdPrice(uint256 surplusInUsd) private view returns(uint256){
        return( depositorCoin.totalSupply() / surplusInUsd);
    }

}
