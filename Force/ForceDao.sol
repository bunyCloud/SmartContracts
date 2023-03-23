// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./fusd.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IDIAOracleV2{
    function getValue(string memory) external returns (uint256, uint256);
}

contract ForceDao is Ownable {
    // Oracle config
    address immutable ORACLE = 0x261cF410d0A83193D647E47c35178288D99E12Dd;
    uint256 public tlosUSD; 
    uint256 public btcUSD;
    uint256 public ethUSD;
    uint256 public eosUSD;
    uint256 public paxgUSD;
    uint256 public xautUSD;
    uint256 public timestampOflatestUSD; 
    // Global system parameters
    uint256 public totalTelosCollateral;
    uint256 public totalBTCCollateral;
    uint256 public totalEOSCollateral;
    uint256 public totalETHCollateral;
    uint256 public totalXAUTCollateral;
    uint256 public totalPAXGCollateral;
    uint256 public totalDebt;
    uint256 public stabilityFee;
    uint256 public liquidationRatio;
    uint256 public collateralizationRatio;
    address payable public admin;
    // User balances
    mapping(address => uint256) public collateralBalances;
    mapping(address => uint256) public fusdBalances;

    // Events
    event TelosCollateralLocked(address indexed user, uint256 amount);
    event BTCCollateralLocked(address indexed user, uint256 amount);
    event EOSCollateralLocked(address indexed user, uint256 amount);
    event ETHCollateralLocked(address indexed user, uint256 amount);
    event XAUTCollateralLocked(address indexed user, uint256 amount);
    event PAXGCollateralLocked(address indexed user, uint256 amount);



    event FUSDGenerated(address indexed user, uint256 amount);
    event TelosCollateralUnlocked(address indexed user, uint256 amount);
    event BTCCollateralUnlocked(address indexed user, uint256 amount);
    event EOSCollateralUnlocked(address indexed user, uint256 amount);
    event ETHCollateralUnlocked(address indexed user, uint256 amount);
    event XAUTCollateralUnlocked(address indexed user, uint256 amount);
    event PAXGCollateralUnlocked(address indexed user, uint256 amount);
    event FUSDRepaid(address indexed user, uint256 amount);


  constructor() public {
    admin = payable(msg.sender);
    stabilityFee = 150;
    liquidationRatio = 15000; //150%
    collateralizationRatio = 14000; // 140%
}

    // Oracle token price check

     
    function getTLOSUSD() internal returns(uint256) {
        (tlosUSD, timestampOflatestUSD) = IDIAOracleV2(ORACLE).getValue("TLOS/USD"); 
        return tlosUSD;
    }

     function getBTCUSD() internal returns(uint256) {
        (btcUSD, timestampOflatestUSD) = IDIAOracleV2(ORACLE).getValue("BTC/USD"); 
        return btcUSD;
    }

     function getETHUSD() internal returns(uint256) {
        (ethUSD, timestampOflatestUSD) = IDIAOracleV2(ORACLE).getValue("ETH/USD"); 
        return ethUSD;
    }

     function getEOSUSD() internal returns(uint256) {
        (eosUSD, timestampOflatestUSD) = IDIAOracleV2(ORACLE).getValue("EOS/USD"); 
        return eosUSD;
    }

     function getPAXGUSD() internal returns(uint256) {
        (paxgUSD, timestampOflatestUSD) = IDIAOracleV2(ORACLE).getValue("PAXG/USD"); 
        return paxgUSD;
    }

     function getXAUTUSD() internal returns(uint256) {
        (xautUSD, timestampOflatestUSD) = IDIAOracleV2(ORACLE).getValue("XAUT/USD"); 
        return xautUSD;
    }


    function checkUSDAge(uint256 maxTimePassed) internal view returns (bool inTime){
         if((block.timestamp - timestampOflatestUSD) < maxTimePassed){
             inTime = true;
         } else {
             inTime = false;
         }
    }

    function lockTelosCollateral(uint256 amount) external {
    require(amount > 0, "Amount must be greater than zero");
    require(collateralBalances[msg.sender] + amount >= fusdBalances[msg.sender] * collateralizationRatio / 10000, "Collateralization ratio below minimum");
    require(totalTelosCollateral + amount >= totalDebt * liquidationRatio / 10000, "Collateralization ratio below liquidation threshold");  
    // Check TLOS price
    uint256 tlosPrice = getTLOSUSD();
    require(checkUSDAge(3600), "Price data too old");
    collateralBalances[msg.sender] += amount;
    totalTelosCollateral += amount;
        uint256 fusdAmount = (amount * tlosPrice) / 100;  // FUSD generated = (collateral * ETH price + collateral * BTC price + collateral * TLOS price) / 300
    fusdBalances[msg.sender] += fusdAmount;
    totalDebt += fusdAmount;
    emit TelosCollateralLocked(msg.sender, amount);
    emit FUSDGenerated(msg.sender, fusdAmount);
}

    // Unlock collateral and repay FUSD
    function unlockTelosCollateral(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= collateralBalances[msg.sender], "Insufficient collateral balance");

        uint256 fusdAmount = amount * ethUSD / 100;  // FUSD to be repaid = collateral * ETH price / 100
        require(fusdAmount <= fusdBalances[msg.sender], "Insufficient FUSD balance");

        collateralBalances[msg.sender] -= amount;
        totalTelosCollateral -= amount;

        fusdBalances[msg.sender] -= fusdAmount;
        totalDebt -= fusdAmount;

        emit TelosCollateralUnlocked(msg.sender, amount);
        emit FUSDRepaid(msg.sender, fusdAmount);
    }







    // Set stability fee rate
    function setStabilityFee(uint256 rate) external onlyOwner {
        stabilityFee = rate;
    }

    // Set collateralization ratio
    function setCollateralizationRatio(uint256 ratio) public onlyOwner {
        collateralizationRatio = ratio;
    }

    function setLiquidationRatio() public onlyOwner {
    liquidationRatio = 15000;
}

    // Set ETH price
    function setethUSD(uint256 price) external onlyOwner {
        ethUSD = price;
    }

}
