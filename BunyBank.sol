// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract BunyBank {
    address owner;
    mapping(address => uint256) tokenBalances;
    string public ContractName = "Buny Bank Telos";
    
constructor() {
    owner1 = msg.sender;
    owner2 = address(0x1234567890123456789012345678901234567890); // Replace with the second owner's address
}

function deposit() public payable {
}

receive() external payable {}

function withdraw(uint amount) public {
    require(msg.sender == owner1 || msg.sender == owner2, "Only the owners can withdraw funds.");
    require(amount <= address(this).balance, "Insufficient balance.");
    uint256 halfAmount = address(this).balance / 2;
    payable(msg.sender).transfer(halfAmount);
}

function withdrawTo(address payable recipient, uint amount) public {
    require(msg.sender == owner1 || msg.sender == owner2, "Only the owners can withdraw funds.");
    require(amount <= address(this).balance, "Insufficient balance.");
    uint256 halfAmount = address(this).balance / 2;
    recipient.transfer(halfAmount);
}

function getBalance() public view returns(uint) {
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
