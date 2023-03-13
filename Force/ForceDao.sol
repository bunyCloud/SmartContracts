// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./fusd.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ForceDao is Ownable {
    // Global system parameters
    uint256 public totalCollateral;
    uint256 public totalDebt;
    uint256 public stabilityFee;
    uint256 public liquidationRatio;
    uint256 public collateralizationRatio;
    uint256 public ethPrice;
    address payable public admin;
    // User balances
    mapping(address => uint256) public collateralBalances;
    mapping(address => uint256) public fusdBalances;

    // Events
    event CollateralLocked(address indexed user, uint256 amount);
    event FUSDGenerated(address indexed user, uint256 amount);
    event CollateralUnlocked(address indexed user, uint256 amount);
    event FUSDRepaid(address indexed user, uint256 amount);


    constructor(uint256 _stabilityFee, uint256 _liquidationRatio, uint256 _collateralizationRatio, uint256 _ethPrice) public {
            admin = payable(msg.sender);
        stabilityFee = _stabilityFee;
        liquidationRatio = _liquidationRatio;
        collateralizationRatio = _collateralizationRatio;
        ethPrice = _ethPrice;
    }


    // Lock collateral and generate FUSD
    function lockCollateral(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(collateralBalances[msg.sender] + amount >= fusdBalances[msg.sender] * collateralizationRatio / 10000, "Collateralization ratio below minimum");
        require(totalCollateral + amount >= totalDebt * liquidationRatio / 10000, "Collateralization ratio below liquidation threshold");

        collateralBalances[msg.sender] += amount;
        totalCollateral += amount;

        uint256 fusdAmount = amount * ethPrice / 100;  // FUSD generated = collateral * ETH price / 100
        fusdBalances[msg.sender] += fusdAmount;
        totalDebt += fusdAmount;

        emit CollateralLocked(msg.sender, amount);
        emit FUSDGenerated(msg.sender, fusdAmount);
    }

    // Unlock collateral and repay FUSD
    function unlockCollateral(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= collateralBalances[msg.sender], "Insufficient collateral balance");

        uint256 fusdAmount = amount * ethPrice / 100;  // FUSD to be repaid = collateral * ETH price / 100
        require(fusdAmount <= fusdBalances[msg.sender], "Insufficient FUSD balance");

        collateralBalances[msg.sender] -= amount;
        totalCollateral -= amount;

        fusdBalances[msg.sender] -= fusdAmount;
        totalDebt -= fusdAmount;

        emit CollateralUnlocked(msg.sender, amount);
        emit FUSDRepaid(msg.sender, fusdAmount);
    }

    // Set stability fee rate
    function setStabilityFee(uint256 rate) external onlyOwner {
        stabilityFee = rate;
    }

    // Set liquidation ratio
    function setLiquidationRatio(uint256 ratio) external onlyOwner {
        liquidationRatio = ratio;
    }

    // Set collateralization ratio
    function setCollateralizationRatio(uint256 ratio) public onlyOwner {
        collateralizationRatio = ratio;
    }

    // Set ETH price
    function setEthPrice(uint256 price) external onlyOwner {
        ethPrice = price;
    }

}
