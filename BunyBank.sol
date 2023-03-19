pragma solidity ^0.8.0;

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract BunyBank {
    address public owner1;
    address public owner2;
    mapping(address => uint256) tokenBalances;
    mapping(address => uint256) public owner1Balance;
    mapping(address => uint256) public owner2Balance;
    string public ContractName = "Buny Bank v1";

    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed owner, uint256 amount);

    constructor(address _owner1, address _owner2) {
        owner1 = _owner1;
        owner2 = _owner2;
    }

    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0.");
        uint256 depositAmount = msg.value;
        uint256 ownerShare = depositAmount / 2;

        owner1Balance[owner1] += ownerShare;
        owner2Balance[owner2] += ownerShare;

        emit Deposit(msg.sender, depositAmount);
    }

    receive() external payable {
        deposit();
    }

    function withdraw(uint256 amount) public {
        require(msg.sender == owner1 || msg.sender == owner2, "Only the owner can withdraw funds.");
        require(amount <= address(this).balance, "Insufficient balance.");
        require(owner1Balance[owner1] >= amount / 2 && owner2Balance[owner2] >= amount / 2, "Insufficient owner balance.");

        owner1Balance[owner1] -= amount / 2;
        owner2Balance[owner2] -= amount / 2;

        emit Withdrawal(msg.sender, amount);

        payable(msg.sender).transfer(amount);
    }

    function withdrawTo(address payable recipient, uint256 amount) public {
        require(msg.sender == owner1 || msg.sender == owner2, "Only the owner can withdraw funds.");
        require(amount <= address(this).balance, "Insufficient balance.");
        require(owner1Balance[owner1] >= amount / 2 && owner2Balance[owner2] >= amount / 2, "Insufficient owner balance.");

        owner1Balance[owner1] -= amount / 2;
        owner2Balance[owner2] -= amount / 2;

        emit Withdrawal(msg.sender, amount);

        recipient.transfer(amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function receive(address token, uint256 amount) public {
        require(msg.sender == token, "Only the token contract can call this function.");
        require(ERC20(token).transferFrom(msg.sender, address(this), amount), "Token transfer failed.");
        tokenBalances[token] += amount;
    }

    function getTokenBalance(address token) public view returns (uint256) {
        return ERC20(token).balanceOf(address(this));
    }

    function getOwner1Balance() public view returns (uint256) {
        return owner1Balance[owner1];
    }

    function getOwner2Balance() public view returns (uint256) {
        return owner2Balance[owner2];
    }
}
