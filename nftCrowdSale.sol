//nftCrowdsale.sol

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTCrowdsale is ERC721Holder, Ownable {
    IERC721 public nft;
    uint256 public price;
    uint256 public maxSupply;
    uint256 public sold;
    mapping(address => uint256) public balances;
    bool public isComplete;

    event NFTPurchased(address indexed buyer, uint256 amount);

    constructor(IERC721 _nft, uint256 _price, uint256 _maxSupply) {
        nft = _nft;
        price = _price;
        maxSupply = _maxSupply;
        isComplete = false;
    }

    function buyNFT(uint256 _amount) external payable {
        require(!isComplete, "Sale is complete");
        require(_amount > 0, "Invalid amount");
        require(sold + _amount <= maxSupply, "Exceeds max supply");
        require(msg.value == price * _amount, "Incorrect Ether value");

        sold += _amount;
        balances[msg.sender] += _amount;

        for (uint256 i = 0; i < _amount; i++) {
            nft.safeTransferFrom(address(this), msg.sender, sold - i - 1);
        }

        if (sold == maxSupply) {
            isComplete = true;
        }

        emit NFTPurchased(msg.sender, _amount);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
