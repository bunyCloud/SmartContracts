// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IDIAOracleV2{
    function getValue(string memory) external returns (uint256, uint256);
}

contract DiaOracle{

    address immutable ORACLE = 0x261cF410d0A83193D647E47c35178288D99E12Dd; // Telos Testnet 
    //address immutable ORACLE = 0x7512fb605c45cEDfF8552eAcA2a020c13A04A5Ef; // Telos Mainnet
    uint256 public tlosPrice; 
    uint256 public btcPrice;
    uint256 public ethPrice;
    uint256 public timestampOflatestPrice; 
   
    function getTelosPrice() external returns(uint256) {
        (tlosPrice, timestampOflatestPrice) = IDIAOracleV2(ORACLE).getValue("TLOS/USD"); 
        return tlosPrice;
    }

     function getBTCPrice() external returns(uint256) {
        (btcPrice, timestampOflatestPrice) = IDIAOracleV2(ORACLE).getValue("BTC/USD"); 
        return btcPrice;
    }

     function getETHPrice() external returns(uint256) {
        (ethPrice, timestampOflatestPrice) = IDIAOracleV2(ORACLE).getValue("ETH/USD"); 
        return ethPrice;
    }

    function checkPriceAge(uint256 maxTimePassed) external view returns (bool inTime){
         if((block.timestamp - timestampOflatestPrice) < maxTimePassed){
             inTime = true;
         } else {
             inTime = false;
         }
    }
}
