// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "./aave/FlashLoanReceiverBase.sol";
import "./interfaces/ILendingPoolAddressesProvider.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IERC20.sol";


contract BunyV1WethDai is FlashLoanReceiverBase {
    //--------------------------------------------------------------------
    // VARIABLES

    address public owner;
    address public wavaxAddress;
    address public daiAddress;
    address public traderjoeRouterAddress;
    address public pangolinRouterAddress;

    enum Exchange {
        JOE,
        PAN,
        NONE
    }

    //--------------------------------------------------------------------
    // MODIFIERS

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this");
        _;
    }

    //--------------------------------------------------------------------
    // CONSTRUCTOR

    constructor(
        address _addressProvider,
        address _traderjoeRouterAddress,
        address _pangolinRouterAddress,
        address _wavax,
        address _dai
    )
        public
        FlashLoanReceiverBase(ILendingPoolAddressesProvider(_addressProvider))
    {
        traderjoeRouterAddress = _traderjoeRouterAddress;
        pangolinRouterAddress = _pangolinRouterAddress;
        owner = msg.sender;
        wavaxAddress = _wavax;
        daiAddress = _dai;
    }

    //--------------------------------------------------------------------
    // ARBITRAGE FUNCTIONS/LOGIC

    function deposit(uint256 amount) public onlyOwner {
        require(amount > 0, "Deposit amount must be greater than 0");
        IERC20(wavaxAddress).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public onlyOwner {
        uint256 wavaxBalance = getERC20Balance(wavaxAddress);
        require(amount <= wavaxBalance, "Not enough amount deposited");
        IERC20(wavaxAddress).transferFrom(address(this), msg.sender, amount);
    }

    function makeArbitrage() public {
        uint256 amountIn = getERC20Balance(wavaxAddress);
        Exchange result = _comparePrice(amountIn);
        if (result == Exchange.JOE) {
            // sell WAVAX in traderjoe for DAI with high price and buy WAVAX from pangolin with lower price
            uint256 amountOut = _swap(
                amountIn,
                traderjoeRouterAddress,
                wavaxAddress,
                daiAddress
            );
            _swap(amountOut, pangolinRouterAddress, daiAddress, wavaxAddress);
        } else if (result == Exchange.PAN) {
            // sell WAVAX in pangolin for DAI with high price and buy WAVAX from traderjoe with lower price
            uint256 amountOut = _swap(
                amountIn,
                pangolinRouterAddress,
                wavaxAddress,
                daiAddress
            );
            _swap(amountOut, traderjoeRouterAddress, daiAddress, wavaxAddress);
        }
    }

    function _swap(
        uint256 amountIn,
        address routerAddress,
        address sell_token,
        address buy_token
    ) internal returns (uint256) {
        IERC20(sell_token).approve(routerAddress, amountIn);

        uint256 amountOutMin = (_getPrice(
            routerAddress,
            sell_token,
            buy_token,
            amountIn
        ) * 95) / 100;

        address[] memory path = new address[](2);
        path[0] = sell_token;
        path[1] = buy_token;

        uint256 amountOut = IUniswapV2Router02(routerAddress)
            .swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                address(this),
                block.timestamp
            )[1];
        return amountOut;
    }

    function _comparePrice(uint256 amount) internal view returns (Exchange) {
        uint256 traderjoePrice = _getPrice(
            traderjoeRouterAddress,
            wavaxAddress,
            daiAddress,
            amount
        );
        uint256 pangolinPrice = _getPrice(
            pangolinRouterAddress,
            wavaxAddress,
            daiAddress,
            amount
        );

        // we try to sell WAVAX with higher price and buy it back with low price to make profit
        if (traderjoePrice > pangolinPrice) {
            require(
                _checkIfArbitrageIsProfitable(
                    amount,
                    traderjoePrice,
                    pangolinPrice
                ),
                "Arbitrage not profitable"
            );
            return Exchange.JOE;
        } else if (traderjoePrice < pangolinPrice) {
            require(
                _checkIfArbitrageIsProfitable(
                    amount,
                    pangolinPrice,
                    traderjoePrice
                ),
                "Arbitrage not profitable"
            );
            return Exchange.PAN;
        } else {
            return Exchange.NONE;
        }
    }

    function _checkIfArbitrageIsProfitable(
        uint256 amountIn,
        uint256 higherPrice,
        uint256 lowerPrice
    ) internal pure returns (bool) {
        // traderjoe & pangolin have 0.3% fee for every exchange
        // so gain made must be greater than 2 * 0.3% * arbitrage_amount

        // difference in WAVAX
        uint256 difference = ((higherPrice - lowerPrice) * 10**18) /
            higherPrice;

        uint256 payed_fee = (2 * (amountIn * 3)) / 1000;

        if (difference > payed_fee) {
            return true;
        } else {
            return false;
        }
    }

    function _getPrice(
        address routerAddress,
        address sell_token,
        address buy_token,
        uint256 amount
    ) internal view returns (uint256) {
        address[] memory pairs = new address[](2);
        pairs[0] = sell_token;
        pairs[1] = buy_token;
        uint256 price = IUniswapV2Router02(routerAddress).getAmountsOut(
            amount,
            pairs
        )[1];
        return price;
    }

    //--------------------------------------------------------------------
    // FLASHLOAN FUNCTIONS

    /**
     * @dev This function must be called only be the LENDING_POOL and takes care of repaying
     * active debt positions, migrating collateral and incurring new V2 debt token debt.
     *
     * @param assets The array of flash loaned assets used to repay debts.
     * @param amounts The array of flash loaned asset amounts used to repay debts.
     * @param premiums The array of premiums incurred as additional debts.
     * @param initiator The address that initiated the flash loan, unused.
     * @param params The byte array containing, in this case, the arrays of aTokens and aTokenAmounts.
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        //
        // Try to do arbitrage with the flashloan amount.
        //
        makeArbitrage();
        // At the end of your logic above, this contract owes
        // the flashloaned amounts + premiums.
        // Therefore ensure your contract has enough to repay
        // these amounts.

        // Approve the LendingPool contract allowance to *pull* the owed amount
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
        }

        return true;
    }

    function _flashloan(address[] memory assets, uint256[] memory amounts)
        internal
    {
        address receiverAddress = address(this);

        address onBehalfOf = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;

        uint256[] memory modes = new uint256[](assets.length);

        // 0 = no debt (flash), 1 = stable, 2 = variable
        for (uint256 i = 0; i < assets.length; i++) {
            modes[i] = 0;
        }

        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }

    /*
     *  Flash multiple assets
     */
    function flashloan(address[] memory assets, uint256[] memory amounts)
        public
        onlyOwner
    {
        _flashloan(assets, amounts);
    }

    function flashloan(address _asset, uint256 _amount) public onlyOwner {
        bytes memory data = "";

        address[] memory assets = new address[](1);
        assets[0] = _asset;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amount;

        _flashloan(assets, amounts);
    }

    //--------------------------------------------------------------------
    // GETTER FUNCTIONS

    function getERC20Balance(address _erc20Address)
        public
        view
        returns (uint256)
    {
        return IERC20(_erc20Address).balanceOf(address(this));
    }
}
        
