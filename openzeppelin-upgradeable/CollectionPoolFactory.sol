// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import './CollectionPool.sol';

contract CollectionPoolFactory {
  uint256 public accountOpenCost;
  uint256 public txCost;
  address public owner;

  mapping(address => CollectionPool) private collectionPools;

  event CollectionAdded(address contractAddress);

  constructor() {
    owner = msg.sender;
    accountOpenCost = 0.2 ether; // in ETH
    txCost = 0.001 ether; // in ETH
  }

  modifier onlyOwner() {
    require(msg.sender == owner, 'Only the contract owner may call this function');
    _;
  }

  // COLLECTION POOL MANAGEMENT

  // Return this user's COLLECTION POOL contract address
  function fetchCollectionPool() public view returns (CollectionPool userData) {
    userData = collectionPools[msg.sender];
    return userData;
  }

  // Create a new CollectionPool struct for this user
  function createCollectionPool() public payable returns (address contractAddress) {
    require(msg.value >= accountOpenCost, 'Not enough ETH');
    CollectionPool newPool = new CollectionPool(msg.sender);
    collectionPools[msg.sender] = newPool;
    contractAddress = address(newPool);
    emit CollectionAdded(contractAddress);

    return contractAddress;
  }

  // UPDATE VARIABLE FUNCTIONS

  // Update the price to open an account here
  function updateAccountOpenCost(uint256 _accountOpenCost) public onlyOwner {
    accountOpenCost = _accountOpenCost;
  }

  // Update the price to interact with this contract
  function updateTransactionCost(uint256 _txCost) public onlyOwner {
    txCost = _txCost;
  }

  // PAYMENT FUNCTIONS

  function checkBalance() public view onlyOwner returns (uint256 amount) {
    amount = address(this).balance;
    return amount;
  }

  function withdraw() public onlyOwner {
    (bool sent, ) = msg.sender.call{ value: checkBalance() }('');
    require(sent, 'There was a problem while withdrawing');
  }
}
