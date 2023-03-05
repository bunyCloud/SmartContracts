// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/* Imports */
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';

contract NFT3D is ERC721URIStorage {
  /* State Variables */

  using Counters for Counters.Counter;
  Counters.Counter private s_tokenIds;
  address s_marketplaceAddress;

  event tokenMinted(uint256 indexed tokenId);

  constructor(address _marketplaceAddress) ERC721('The Buny Project 2023', 'aBUNY') {
    s_marketplaceAddress = _marketplaceAddress;
  }

  /*  Logics */

  function mintToken(string memory _tokenURI) external returns (uint) {
    s_tokenIds.increment();
    uint256 newTokenId = s_tokenIds.current();

    _mint(msg.sender, newTokenId);
    emit tokenMinted(newTokenId);
    _setTokenURI(newTokenId, _tokenURI);

    setApprovalForAll(s_marketplaceAddress, true);
    return newTokenId;
  }
}
