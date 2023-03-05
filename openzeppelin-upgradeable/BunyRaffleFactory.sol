///bunyRaffle

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

import {ClonesUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./BunyRaffleNft.sol";


contract BunyRaffleFactory {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private atContract;
    address public implementation;
    string  _name = "Buny Raffle 2023";
    string  _symbol = "rBUNY";
    string  _animationUrl = "https://ipfs.io/ipfs/Qmd94YsrsK5jPbi675XiwyLwMhcM6HS6MULC7mqQGMnXtW";
    uint256  _prime = 432211379112113246928842014508850435796007;
    uint256  _iterations = 1337;
    uint256 public collectionCount = 0;
    event CreatedEdition(uint256 indexed editionId, address indexed creator, uint256 editionSize, address indexed editionContractAddress, uint256 minPlayers, uint256 salePrice);
    Collection[] public collection;



  struct Collection {
    string _name;
    address editionContractAddress;
    uint256 _editionSize;
    uint256 newId;
    uint256 _minPlayers;
    uint256 _salePrice;
    string _imageUrl;
  }



    /// Initializes factory with address of implementation logic
    constructor(address _implementation) {
        implementation = _implementation;
    }

 
   
    function createEdition(
        //string memory _name,
        //string memory _symbol,
        string memory _description,
        //string memory _animationUrl,
        string memory _imageUrl,
        uint256 _editionSize,
        uint256 _salePrice,
        uint256 _minPlayers
        //uint256 _royaltyBPS
    ) external returns (uint256) {
        uint256 newId = atContract.current();
        address newContract = ClonesUpgradeable.cloneDeterministic(
            implementation,
            bytes32(abi.encodePacked(newId))
        );
        BunyRaffleNft(newContract).initialize(
            msg.sender,
            _name,
            _symbol,
            _description,
            _animationUrl,
            _imageUrl,
            _editionSize,
            _salePrice,
            _minPlayers,
            //_royaltyBPS,
            _prime,
            _iterations
        );
        emit CreatedEdition(newId, msg.sender,  _editionSize, newContract, _minPlayers, _salePrice );
        // Returns the ID of the recently created minting contract
        // Also increments for the next contract creation call
        atContract.increment();
         Collection memory x = Collection(_name, newContract, _editionSize, newId,  _minPlayers, _salePrice, _imageUrl);
    collection.push(x);
    collectionCount ++;
        return newId;
    }

  function readAllCollections() public view  returns (Collection[] memory) {
    Collection[] memory result = new Collection[](collectionCount);
    for (uint256 i = 0; i < collectionCount; i++) {
      result[i] = collection[i];
    }
    return result;
  }

    function getRaffleAtId(uint256 raffleId)
        external
        view
        returns (BunyRaffleNft)
    {
        return
            BunyRaffleNft(
                ClonesUpgradeable.predictDeterministicAddress(
                    implementation,
                    bytes32(abi.encodePacked(raffleId)),
                    address(this)
                )
            );
    }


  
}
