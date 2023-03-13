pragma solidity >=0.6.0 <0.7.0;

import "hardhat/console.sol";

import { FlashLoanReceiverBase } from "./FlashLoanReceiverBase.sol";
import { ILendingPool, ILendingPoolAddressesProvider, IERC20 } from "./Interfaces.sol";
import { SafeMath } from "./Libraries.sol";
import { Constants } from "./Constants.sol";
import { IUniswapV2Router02 } from "./IUniswapV2Router02.sol";

contract BunyFlashLoanQIWAVAX is FlashLoanReceiverBase {
  uint256 private loanSize = 1000 ether;

  using SafeMath for uint256;

  IUniswapV2Router02 public traderjoeRouter;
  IUniswapV2Router02 public pangolinRouter;

  IERC20 public WAVAX_ERC20;
  IERC20 public QI_ERC20;

  constructor(ILendingPoolAddressesProvider _addressProvider) FlashLoanReceiverBase(_addressProvider) public {
    pangolinRouter = IUniswapV2Router02(Constants.PANGOLIN_ROUTER_ADDRESS);
    traderjoeRouter = IUniswapV2Router02(Constants.TRADER_JOE_ROUTER_ADDRESS);
    WAVAX_ERC20 = IERC20(Constants.WAVAX_ADDRESS);
    QI_ERC20 = IERC20(Constants.QI_ADDRESS);
  }

  /**
    This is helper function to let us know how much WAVAX and QI we have at some moment
  */
  function printBalances() public {
    console.log("WAVAX: ", WAVAX_ERC20.balanceOf(address(this)));
    console.log("QI: ", QI_ERC20.balanceOf(address(this)));
  }

  /**
    This function is called after your contract has received the flash loaned amount
  */
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  )
    external
    override
    returns (bool)
  {
    printBalances();

    address[] memory path = new address[](2);
    path[0] = Constants.WAVAX_ADDRESS;
    path[1] = Constants.QI_ADDRESS;

    WAVAX_ERC20.approve(Constants.TRADER_JOE_ROUTER_ADDRESS, loanSize);
    traderjoeRouter.swapExactTokensForTokens(loanSize, 0, path, address(this), block.timestamp + 5);

    printBalances();

    address[] memory revPath = new address[](2);
    revPath[0] = Constants.QI_ADDRESS;
    revPath[1] = Constants.WAVAX_ADDRESS;

    uint256 QIBalance = QI_ERC20.balanceOf(address(this));

    QI_ERC20.approve(Constants.PANGOLIN_ROUTER_ADDRESS, QIBalance);
    pangolinRouter.swapExactTokensForTokens(QIBalance, 0, revPath, address(this), block.timestamp + 5);

    printBalances();

    for (uint i = 0; i < assets.length; i++) {
      uint256 amountOwing = amounts[i].add(premiums[i]);
      IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
    }

    return true;
  }

  function myFlashLoanCall() public {
    address receiverAddress = address(this);

    address[] memory assets = new address[](1);
    assets[0] = address(Constants.WAVAX_ADDRESS);

    uint256[] memory amounts = new uint256[](1);
    amounts[0] = loanSize;

    uint256[] memory modes = new uint256[](1);
    modes[0] = 0;

    address onBehalfOf = address(this);
    bytes memory params = "";
    uint16 referralCode = 0;

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
}
