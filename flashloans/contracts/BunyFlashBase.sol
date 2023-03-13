// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./FlashLoanSimpleReceiverBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


// FlashLoanSimpleReceiverBase is a contract from Aave which we use to setup our contract as the receiver for the flash loan.

contract FlashLoanExample is FlashLoanSimpleReceiverBase {

    event Log(address asset, uint256 val);


// it takes in a provider of type IPoolAddressesProvider 
// which is essentially the address of the Pool Contract we talked about in the example above wrapped around an interface of type IPoolAddressesProvider
// FlashLoanSimpleReceiverBase requires this provider in its constructor.

    constructor(IPoolAddressesProvider provider)FlashLoanSimpleReceiverBase(provider) {

    } 

    function createFlashLoan(address asset, uint256 amount) external {
// https://docs.aave.com/developers/core-contracts/pool  - read more

        address receiver = address(this);                                      //address of the FlashLoanExample Contract
        bytes memory params = "";
        uint16 referralCode = 0;                                               //0 because this transaction was executed by user directly without any middle man.

        POOL.flashLoanSimple(receiver, asset, amount, params, referralCode);
    }



// After making a flashLoanSimple call, 
// Pool Contract will perform some checks and will send the asset in the amount that was requested to the FlashLoanExample Contract 
// and will call the executeOperation method.

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns(bool) {

// do things like arbitrage here
// abi.decode(params) to decode params

        uint256 amountOwing = amount + premium;

// you can do anything with this asset 
// but in this contract we just give approval to the Pool Contract to withdraw the amount that we owe along with some premium. 
// Then we emit a log and return from the function.   

        IERC20(asset).approve(address(POOL), amountOwing);

        emit Log(asset, amountOwing);
        return true;
    }

}