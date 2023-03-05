// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import { ClonesUpgradeable } from '@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol';
import { CountersUpgradeable } from '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import './erc721Dynamic.sol';

contract dFactory {
  using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private atContract;
    address public implementation;
    uint256 public collectionCount = 0;
    event CreatedEdition(uint256 indexed editionId, address indexed creator, uint256 editionSize, address indexed editionContractAddress);
    Collection[] public collection;

 

  struct Collection {
    string _name;
    address editionContractAddress;

  }


  constructor(address _implementation) {
    implementation = _implementation;
  }



  function readAllCollections() public view  returns (Collection[] memory) {
    Collection[] memory result = new Collection[](collectionCount);
    for (uint256 i = 0; i < collectionCount; i++) {
      result[i] = collection[i];
    }
    return result;
  }


  function createEdition(
    string memory _baseURI,
    string memory _name,
    string memory _symbol,
    string memory _description,
    uint256 _editionSize,
    uint256 _royaltyBPS
  ) external returns (uint256) {
    uint256 newId = atContract.current();
    address newContract = ClonesUpgradeable.cloneDeterministic(implementation, bytes32(abi.encodePacked(newId)));
    erc721Dynamic(newContract).initialize(msg.sender, _baseURI, _name, _symbol, _description, _editionSize, _royaltyBPS);
    emit CreatedEdition(newId, msg.sender, _editionSize, newContract);
    atContract.increment();
    Collection memory x = Collection(_name, newContract);
    collection.push(x);
    collectionCount ++;
    return newId;
  }





  function getEditionAtId(uint256 editionId) external view returns (erc721Dynamic) {
    return erc721Dynamic(ClonesUpgradeable.predictDeterministicAddress(implementation, bytes32(abi.encodePacked(editionId)), address(this)));
  }
}
