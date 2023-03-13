// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Treasury {
    address[] private wallets;
    mapping(address => uint256) private balances;
    mapping(address => bool) private depositors;
    
    event Deposit(address indexed depositor, uint256 amount);
    event WalletAdded(address indexed wallet);
    event WalletRemoved(address indexed wallet);
    
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        address depositor = msg.sender;
        balances[depositor] += msg.value;
        depositors[depositor] = true;
        
        emit Deposit(depositor, msg.value);
    }
    
    function withdraw(uint256 amount) external {
        address payable owner = payable(msg.sender);
        require(balances[owner] >= amount, "Insufficient balance");
        
        balances[owner] -= amount;
        owner.transfer(amount);
    }
    
    function addWallet(address wallet) external {
        require(wallet != address(0), "Wallet address cannot be zero");
        require(!isWalletAdded(wallet), "Wallet address already added");
        
        wallets.push(wallet);
        
        emit WalletAdded(wallet);
    }
    
    function removeWallet(address wallet) external {
        require(isWalletAdded(wallet), "Wallet address not found");
        
        uint256 index = 0;
        for (; index < wallets.length; index++) {
            if (wallets[index] == wallet) {
                break;
            }
        }
        
        for (uint256 i = index; i < wallets.length - 1; i++) {
            wallets[i] = wallets[i + 1];
        }
        wallets.pop();
        
        emit WalletRemoved(wallet);
    }
    
    function isWalletAdded(address wallet) public view returns(bool) {
        for (uint256 i = 0; i < wallets.length; i++) {
            if (wallets[i] == wallet) {
                return true;
            }
        }
        
        return false;
    }
    
    function getAllDeposits() external view returns(uint256[] memory) {
        uint256[] memory allDeposits = new uint256[](wallets.length);
        for (uint256 i = 0; i < wallets.length; i++) {
            allDeposits[i] = balances[wallets[i]];
        }
        
        return allDeposits;
    }
    
    function getAllDepositors() external view returns(address[] memory) {
        address[] memory allDepositors = new address[](wallets.length);
        uint256 count = 0;
        for (uint256 i = 0; i < wallets.length; i++) {
            if (depositors[wallets[i]]) {
                allDepositors[count++] = wallets[i];
            }
        }
        
        address[] memory result = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = allDepositors[i];
        }
        
        return result;
    }
}
