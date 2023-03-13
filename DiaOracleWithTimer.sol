//DiaOracleWithTimer.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IDIAOracleV2 {
    function getValue(string memory) external returns (uint128, uint128);
}

contract PriceOracle {
    address immutable ORACLE = 0x261cF410d0A83193D647E47c35178288D99E12Dd;
    uint128 public latestPrice;
    uint128 public timestampOfLatestPrice;

    // Token pairs to be monitored
    string[] public tokenPairs = ["TLOS/USD", "DAI/USD", "FRAX/USD", "USDT/USD", "USDC/USD", "DIA/USD", "ETH/USD", "BTC/USD"];

    // Mapping to keep track of last price update time for each token pair
    mapping(string => uint128) public lastPriceUpdate;

    // Timer variables
    uint256 public lastUpdateTime;
    uint256 public updateInterval = 30 minutes;

    // Function to get the price of a given token pair
    function getPrice(string memory tokenPair) external {
        (latestPrice, timestampOfLatestPrice) = IDIAOracleV2(ORACLE).getValue(tokenPair);
        lastPriceUpdate[tokenPair] = timestampOfLatestPrice;
    }

    // Function to check if a given token pair has been updated within a given time
    function isPriceRecent(string memory tokenPair, uint128 maxTimePassed) external view returns (bool) {
        return (block.timestamp - lastPriceUpdate[tokenPair] < maxTimePassed);
    }

    // Function to get the price and last update time for all monitored token pairs
    function getAllPrices() external {
        for (uint i = 0; i < tokenPairs.length; i++) {
            (latestPrice, timestampOfLatestPrice) = IDIAOracleV2(ORACLE).getValue(tokenPairs[i]);
            lastPriceUpdate[tokenPairs[i]] = timestampOfLatestPrice;
        }
    }

    // Timer function to call getAllPrices every 30 minutes
    function updatePrices() external {
        require(block.timestamp >= lastUpdateTime + updateInterval, "Update interval has not passed yet.");
        getAllPrices();
        lastUpdateTime = block.timestamp;
    }
}
