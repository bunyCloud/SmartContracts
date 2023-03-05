//bunyNFt

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

import { ERC721Upgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import {  IERC165Upgradeable } from '@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol';
import { OwnableUpgradeable } from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import { CountersUpgradeable } from '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import { AddressUpgradeable } from '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import { SharedNFTLogic } from './SharedNFTLogic.sol';
import { IEditionSingleMintable } from './IEditionSingleMintable.sol';
import "./SlothVDF.sol";

contract RaffleNft is ERC721Upgradeable, IEditionSingleMintable,  OwnableUpgradeable {
  using CountersUpgradeable for CountersUpgradeable.Counter;
  SharedNFTLogic private immutable sharedNFTLogic;
  CountersUpgradeable.Counter private atEditionId;
  event RaffleStarted(address minter, uint256 startTime);
  event EditionSold(uint256 price, address owner);
  event WinnerPicked(address payable winner, uint256 prize, uint256 winningNumber);
  string public description;
  string public animationUrl;
  string public imageUrl;
  uint256 public editionSize;
  mapping(address => bool) allowedMinters;
  uint256 public salePrice;
  uint256 public minPlayers;
  bool public active = false;
  uint256 public startTime;
  uint256 public EntryCount = 0;
  address payable[] public players;
  address payable[] public RaffleWinner;
  uint256 public prime = 0;
  uint256 public iterations = 0;
  uint256 private nonce = 0;
  uint256 public randomNumber = 0;
  uint256 public winningNumber = 0;
    Entry[] private entry;

  // Mapping to retrieve Array index from address or name
  mapping(address => uint256) private addressToIndex;
  mapping(string => uint256) private playerToIndex;

  // address -> random number seed
  mapping(address => uint256) public seed;

  struct Entry {
    address player;
    uint256 EntryNumber;
  }

  constructor( SharedNFTLogic _sharedNFTLogic) {
    sharedNFTLogic = _sharedNFTLogic;
      
       }

  function initialize(
    address _owner,
    string memory _name,
    string memory _symbol,
    string memory _description,
    string memory _animationUrl,
    string memory _imageUrl,
    uint256 _editionSize,
    uint256 _salePrice,
    uint256 _minPlayers,
    uint256 _prime,
    uint256 _iterations

  ) public initializer {
    __ERC721_init(_name, _symbol);
    __Ownable_init();
    // Set ownership to original sender of contract call
    transferOwnership(_owner);
    description = _description;
    animationUrl = _animationUrl;
    imageUrl = _imageUrl;
    editionSize = _editionSize;
    salePrice = _salePrice;
    minPlayers = _minPlayers;
    prime = _prime;
    iterations = _iterations;
    atEditionId.increment();
  }

  /// @dev returns the number of minted tokens within the edition
  function totalSupply() public view returns (uint256) {
    return atEditionId.current() - 1;
  }

  
 // return balance in wei
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    // return prize balance
     function getPrize() public view returns(uint){
        return address(this).balance * 90 / 100;
    }

    function houseFee() public view returns(uint) {
        return address(this).balance * 10 / 100;
    }



        //seed is generated using sender address
    function createSeed() external payable returns(uint256) {
        // commit funds
                seed[msg.sender] = uint256(keccak256(abi.encodePacked(msg.sender, nonce++, block.timestamp, blockhash(block.number - 1))));
                
    }
 
    function prove(uint256 proof) external returns(uint) {
        // see if the proof is valid for the seed associated with the address
        require(SlothVDF.verify(proof, seed[msg.sender], prime, iterations), 'Invalid proof');
 
        // use the proof as a provable random number
         randomNumber = proof;
    }

    // provable random number used as seed to generate additional random number
    function random() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, randomNumber)));
    }
    // array of player addresses
     function getPlayers() public view returns(address payable[] memory) {
        return players;
    }

     function readAllEntries() public view  returns (Entry[] memory) {
    Entry[] memory result = new Entry[](EntryCount);
    for (uint256 i = 0; i < EntryCount; i++) {
      result[i] = entry[i];
    }
    return result;
  }
  

    function pickWinner() external payable returns(uint256){
        require (players.length >= minPlayers, "Define minimum player number");
        require (totalSupply() >= editionSize, "Raffle must complete before picking winner");
        uint r = random();
        address payable winner;
        uint index = r % editionSize;
        winner = players[index]; 
        uint winnerPrize = getPrize();
        winner.transfer(getPrize());
        players = new address payable[](0);
        withdraw();
        RaffleWinner.push(payable(winner));
        winningNumber = index;
        emit WinnerPicked(winner, winnerPrize, winningNumber);
        return winningNumber;

    }


  function getWinner() public view returns(address payable[] memory) {
        return RaffleWinner;
    }



  function purchase() external payable returns (uint256) {
    require(active, "Raffle has not started. Owner must setApprovedMinter");
    require(msg.value == salePrice, "No soup for you!");
    address[] memory toMint = new address[](1);
    toMint[0] = msg.sender;
    players.push(payable(msg.sender));
    EntryCount ++;
    Entry memory x = Entry(msg.sender, EntryCount);
    entry.push(x);
    emit EditionSold(salePrice, msg.sender);
    return _mintEditions(toMint);
  }


  function _isAllowedToMint() internal view returns (bool) {
    if (owner() == msg.sender) {
      return true;
    }
    if (allowedMinters[address(0x0)]) {
      return true;
    }
    return allowedMinters[msg.sender];
  }

  function mintEdition(address to) external override returns (uint256) {
    require(_isAllowedToMint(), 'Needs to be an allowed minter');
    address[] memory toMint = new address[](1);
    toMint[0] = to;
    return _mintEditions(toMint);
  }

  function mintEditions(address[] memory recipients) external override returns (uint256) {
    require(_isAllowedToMint(), 'Needs to be an allowed minter');
    return _mintEditions(recipients);
  }

  function owner() public view override(OwnableUpgradeable, IEditionSingleMintable) returns (address) {
    return super.owner();
  }
  // enable/disable raffle
  function disableRaffle() public onlyOwner {
     active = false;
  }
  // helper function starts raffle once setApprovedMinter. 
  function enableRaffle() public onlyOwner {
      active = true;
    }
  // set contract address as Approved minter
  // set active state to false
  // log and emit current time
  function setApprovedMinter(address minter, bool allowed) public onlyOwner {
    allowedMinters[minter] = allowed;
    enableRaffle();
    startTime = block.timestamp;
    emit RaffleStarted(minter, startTime);
  }

  /// Returns the number of editions allowed to mint (max_uint256 when open edition)
  function numberCanMint() public view override returns (uint256) {
    // Return max int if open edition
    if (editionSize == 0) {
      return type(uint256).max;
    }
    // atEditionId is one-indexed hence the need to remove one here
    return editionSize + 1 - atEditionId.current();
  }

  /**
      @dev Private function to mint als without any access checks.
           Called by the public edition minting functions.
     */
  function _mintEditions(address[] memory recipients) internal returns (uint256) {
    uint256 startAt = atEditionId.current();
    uint256 endAt = startAt + recipients.length - 1;
    require(editionSize == 0 || endAt <= editionSize, 'Sold out');
    while (atEditionId.current() <= endAt) {
      _mint(recipients[atEditionId.current() - startAt], atEditionId.current());
      atEditionId.increment();
    }
    return atEditionId.current();
  }

 
      function withdraw() internal onlyOwner {
    // No need for gas limit to trusted address.
    AddressUpgradeable.sendValue(payable(owner()), address(this).balance * 20 / 100);
  }


  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), 'No token');

    return sharedNFTLogic.createMetadataEdition(name(), description, imageUrl, animationUrl, tokenId, editionSize);
  }


}
