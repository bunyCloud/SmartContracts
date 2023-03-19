// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ERC20 {
function balanceOf(address account) external view returns (uint256);
function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract BunyBank {
address owner1;
address owner2;
mapping(address => uint256) tokenBalances1;
mapping(address => uint256) tokenBalances2;
string public ContractName = "Buny Bank Telos v1";

event Deposit(address indexed account, uint256 amount);
event Withdrawal(address indexed account, uint256 amount);

constructor() {
    owner1 = msg.sender;
    owner2 = address(0x1234567890123456789012345678901234567890); // Replace with the second owner's address
}

function deposit() public payable {
    // Split the deposited tokens 50/50 into separate balance slots for owner1 and owner2
    uint256 halfAmount = msg.value / 2;
    tokenBalances1[msg.sender] += halfAmount;
    tokenBalances2[msg.sender] += halfAmount;

    // Emit a Deposit event
    emit Deposit(msg.sender, msg.value);
}

receive() external payable {}

function withdraw(uint amount) public {
    require(msg.sender == owner1 || msg.sender == owner2, "Only the owners can withdraw funds.");
    require(amount <= address(this).balance, "Insufficient balance.");
    // Split the withdrawn amount equally between owner1 and owner2
    uint256 halfAmount = amount / 2;
    payable(owner1).transfer(halfAmount);
    payable(owner2).transfer(halfAmount);

    // Emit a Withdrawal event
    emit Withdrawal(msg.sender, amount);
}

function withdrawTo(address payable recipient, uint amount) public {
    require(msg.sender == owner1 || msg.sender == owner2, "Only the owners can withdraw funds.");
    require(amount <= address(this).balance, "Insufficient balance.");
    // Split the withdrawn amount equally between owner1 and owner2
    uint256 halfAmount = amount / 2;
    recipient.transfer(halfAmount);
    payable(owner1).transfer(halfAmount);
    payable(owner2).transfer(halfAmount);

    // Emit a Withdrawal event
    emit Withdrawal(msg.sender, amount);
}

function getBalance() public view returns(uint) {
    return address(this).balance;
}

function receive(address token, uint256 amount) public {
    require(msg.sender == token, "Only the token contract can call this function.");
    require(ERC20(token).transferFrom(msg.sender, address(this), amount), "Token transfer failed.");
    // Split the received tokens 50/50 into separate balance slots for owner1 and owner2
    uint256 halfAmount = amount / 2;
    tokenBalances1[token] += halfAmount;
    tokenBalances2[token] += halfAmount;

    // Emit a Deposit event
    emit Deposit(msg.sender, amount);
}

function getTokenBalance1(address token) public view returns (uint256) {
    return tokenBalances1[token];
}

function getTokenBalance2(address token) public view returns (uint256) {
    return tokenBalances2[token];
}
}
