//DiaOracle.sol
                /*
                        TLOS/USD
                        DAI/USD
                        FRAX/USD
                        USDT/USD
                        USDC/USD
                        DIA/USD
                        ETH/USD
                        BTC/USD
                            */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IDIAOracleV2{
    function getValue(string memory) external returns (uint128, uint128);
}

contract DiaPriceOracle{
        
    address immutable ORACLE = 0x261cF410d0A83193D647E47c35178288D99E12Dd;
    uint128 public latestPrice; 
    uint128 public timestampOflatestPrice; 
   
    function getPriceInfo(string memory key) external {
        (latestPrice, timestampOflatestPrice) = IDIAOracleV2(ORACLE).getValue(key); 
    }
   
    function checkPriceAge(uint128 maxTimePassed) external view returns (bool inTime){
         if((block.timestamp - timestampOflatestPrice) < maxTimePassed){
             inTime = true;
         } else {
             inTime = false;
         }
    }
}