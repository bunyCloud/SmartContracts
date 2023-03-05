

pragma solidity ^0.6.2;

contract RandomNFT {
    // array to store the ids of the NFT tokens
    uint[] private tokenIds;

    // function to store the ids of the NFT tokens
    function storeTokenIds(uint[] memory _tokenIds) public {
        tokenIds = _tokenIds;
    }

    // function to select a random NFT token id from the array
    function randomTokenId() public view returns (uint) {
        uint randomIndex = uint(keccak256(abi.encodePacked(now, block.difficulty))) % tokenIds.length;
        return tokenIds[randomIndex];
    }
}