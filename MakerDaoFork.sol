pragma solidity ^0.8.0;

contract MakerDaoFork {
    // Global system parameters
    uint256 public totalCollateral;
    uint256 public totalDebt;
    uint256 public stabilityFee;
    uint256 public liquidationRatio;
    uint256 public collateralizationRatio;
    uint256 public ethPrice;

    // User balances
    mapping(address => uint256) public collateralBalances;
    mapping(address => uint256) public daiBalances;

    // Events
    event CollateralLocked(address indexed user, uint256 amount);
    event DaiGenerated(address indexed user, uint256 amount);
    event CollateralUnlocked(address indexed user, uint256 amount);
    event DaiRepaid(address indexed user, uint256 amount);
    event DaiMinted(address indexed user, uint256 amount);

    // Lock collateral and generate Dai
    function lockCollateral(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(collateralBalances[msg.sender] + amount >= daiBalances[msg.sender] * collateralizationRatio / 10000, "Collateralization ratio below minimum");
        require(totalCollateral + amount >= totalDebt * liquidationRatio / 10000, "Collateralization ratio below liquidation threshold");

        collateralBalances[msg.sender] += amount;
        totalCollateral += amount;

        uint256 daiAmount = amount * ethPrice / 100;  // Dai generated = collateral * ETH price / 100
        daiBalances[msg.sender] += daiAmount;
        totalDebt += daiAmount;

        emit CollateralLocked(msg.sender, amount);
        emit DaiGenerated(msg.sender, daiAmount);
    }

    // Unlock collateral and repay Dai
    function unlockCollateral(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= collateralBalances[msg.sender], "Insufficient collateral balance");

        uint256 daiAmount = amount * ethPrice / 100;  // Dai to be repaid = collateral * ETH price / 100
        require(daiAmount <= daiBalances[msg.sender], "Insufficient Dai balance");

        collateralBalances[msg.sender] -= amount;
        totalCollateral -= amount;

        daiBalances[msg.sender] -= daiAmount;
        totalDebt -= daiAmount;

        emit CollateralUnlocked(msg.sender, amount);
        emit DaiRepaid(msg.sender, daiAmount);
    }

    // Mint new Dai tokens
    function mintDai(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");

        daiBalances[msg.sender] += amount;
        totalDebt += amount;

        emit DaiMinted(msg.sender, amount);
    }

    // Set stability fee rate
    function setStabilityFee(uint256 rate) external {
        require(msg.sender == owner, "Only owner can set stability fee");
        stabilityFee = rate;
    }

    // Set liquidation ratio
    function setLiquidationRatio(uint256 ratio) external {
        require(msg.sender == owner, "Only owner can set liquidation ratio");
        liquidationRatio = ratio;
    }

    // Set collateralization ratio
    function setCollateralizationRatio(uint256 ratio) external {
        require(msg.sender == owner, "Only owner can set collateralization ratio");
        collateralizationRatio = ratio;
    }

    // Set ETH price
    function setEthPrice(uint256 price) external {
        require(msg.sender == owner, "Only owner can set ETH price");
       
  
