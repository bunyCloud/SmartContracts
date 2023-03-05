//bunyNFt

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC721EnumerableUpgradeable} from "./token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

import {  IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {  IERC721EnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/interfaces/IERC721EnumerableUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { CountersUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { SharedNFTLogic } from "./SharedNFTLogic.sol";
import { IEditionSingleMintable } from "./IEditionSingleMintable.sol";
import "./SlothVDF.sol";

contract BunyRaffleNft is ERC721Upgradeable, IEditionSingleMintable,  OwnableUpgradeable {
  using CountersUpgradeable for CountersUpgradeable.Counter;
  SharedNFTLogic private immutable sharedNFTLogic;
  CountersUpgradeable.Counter private atEditionId;
  event Rafflestarted(address minter, uint256 startTime);
  event Editionsold(uint256 price, address owner, uint256 EntryCount, uint256 entryTime);
  event Winnerpicked(address winner, uint256 winningNumber);
  string public description;
  string public animationUrl;
  string public imageUrl;
  uint256 public editionSize;
  uint256 public salePrice;
  uint256 public minPlayers;
  bool public active = false;
  address payable public Winner;
  bool public winnerSelected = false;
  bool public isComplete = false;
  uint256 public startTime;
  uint256 public EntryCount = 0;
  uint256 public prime = 0;
  uint256 public iterations = 0;
  uint256 private nonce = 0;
  uint256 public randomNumber = 0;
  uint256 public winningNumber = 0;
  Entry[] private entry;
  RaffleWinner[] public raffleWinner;
 	uint256[] public nftTokenIds;
  mapping(address => bool) public mintedTokens;
  mapping(address => bool) public allowedMinters;
  mapping(address => uint256) public seed;

  struct Entry {
    address player;
    uint256 EntryNumber;
    uint256 entryTime;
  }

  struct RaffleWinner {
    address payable winner;
    uint256 winningTokenId;
    uint256 winningPrize;
  }

  constructor( SharedNFTLogic _sharedNFTLogic)  {
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

    function getOwner(uint _id) public view returns (address ) {
    return ownerOf(_id);
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
   

  function purchase() external payable returns (uint256) {
    require(!mintedTokens[msg.sender], "Only one token allowed per wallet address");
    require(active, "Raffle has not started. Owner must setApprovedMinter");
    require(msg.value == salePrice, "No soup for you!");
    address[] memory toMint = new address[](1);
    toMint[0] = msg.sender;
    mintedTokens[msg.sender] = true;
    EntryCount ++;
    nftTokenIds.push(EntryCount);
    uint256 entryTime = block.timestamp;
    Entry memory x = Entry(msg.sender, EntryCount, entryTime);
    entry.push(x);
      if (EntryCount == editionSize) {
            isComplete = true;
            active = false;
        }
    emit Editionsold(salePrice, msg.sender, EntryCount, entryTime);
    return _mintEditions(toMint);
  }


    function createSeed() external returns(uint256) {
      seed[msg.sender] = uint256(keccak256(abi.encodePacked(msg.sender, EntryCount, block.timestamp, blockhash(block.number - 1))));            
      
    }
 
    function prove(uint256 proof) external  {
   // see if the proof is valid for the seed associated with the address
      require(SlothVDF.verify(proof, seed[msg.sender], prime, iterations), "Invalid proof");
   // use the proof as a provable random number
          randomNumber = proof;
    }

  /*
    function pickWinner() external payable returns(uint256){
//        require (players.length >= minPlayers, "Define minimum player number");

        require (totalSupply() >= editionSize, "Raffle must complete before picking winner");
        address winner;
        address payable payWinner = payable(winner);
        //uint256 winningTokenId = getRandomTokenId();
        //winner = getOwner(winningTokenId); 
        //uint winnerPrize = getPrize();
        //RaffleWinner.push(winner, winnerPrize, winningNumber);
        //RaffleWinner memory x = RaffleWinner(payWinner, winnerPrize, winningNumber);
        //raffleWinner.push(x);
        //winningNumber = winningTokenId;
        //payWinner.transfer(getPrize());
        //withdraw();
 
        return winningNumber;

    }
    */

function getRandomTokenOwner() external  returns (uint256, address payable) {
  require (randomNumber > 0, "Generate provable random number first");
  require (totalSupply() >= editionSize, "Raffle must complete before picking winner");
  uint256 tokenId = uint256(keccak256(abi.encodePacked(block.timestamp, randomNumber, blockhash(block.number - 1)))) % totalSupply();
  winningNumber = tokenId;
  address _winner = ownerOf(winningNumber);
  Winner = payable(_winner);
  winnerSelected = true;
  uint256 winnerPrize = getPrize();
  RaffleWinner memory x = RaffleWinner(Winner, winningNumber, winnerPrize);
  raffleWinner.push(x);
  emit Winnerpicked(Winner, winningNumber);
  return (winningNumber,Winner);
}

    function claimPrize(uint256 tokenId) public {
    address payable tokenOwner = payable(ownerOf(tokenId));
    require(msg.sender == tokenOwner, "Only the owner of this token can withdraw the balance");
    uint256 balance = address(this).balance * 90/100;
    require(balance > 0, "The contract has no balance to withdraw");
    (bool success, ) = tokenOwner.call{value: balance}("");
    withdraw();
    require(success, "Withdrawal failed");
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
    require(_isAllowedToMint(), "Needs to be an allowed minter");
    address[] memory toMint = new address[](1);
    toMint[0] = to;
    return _mintEditions(toMint);
  }

  function mintEditions(address[] memory recipients) external override returns (uint256) {
    require(_isAllowedToMint(), "Needs to be an allowed minter");
    return _mintEditions(recipients);
  }

  function owner() public view override(OwnableUpgradeable, IEditionSingleMintable) returns (address) {
    return super.owner();
  }

  // helper function starts raffle once setApprovedMinter. 
  function enableRaffle() public onlyOwner {
      active = true;
    }

 
      function getWinnerTokenId() public view returns(uint256) {
        return winningNumber;
    }

      function getWinnerAddress() public view returns(address payable) {
        return Winner;
    }

     function readAllEntries() public view  returns (Entry[] memory) {
    Entry[] memory result = new Entry[](EntryCount);
    for (uint256 i = 0; i < EntryCount; i++) {
      result[i] = entry[i];
    }
    return result;
  }
  
  // set contract address as Approved minter
  // set active state to false
  // log and emit current time
  function setApprovedMinter(address minter, bool allowed) public onlyOwner {
    allowedMinters[minter] = allowed;
    enableRaffle();
    startTime = block.timestamp;
    emit Rafflestarted(minter, startTime);
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
    require(editionSize == 0 || endAt <= editionSize, "Sold out");
    while (atEditionId.current() <= endAt) {
      _mint(recipients[atEditionId.current() - startAt], atEditionId.current());
      atEditionId.increment();
    }
    return atEditionId.current();
  }

 
      function withdraw() internal {
    // No need for gas limit to trusted address.
    AddressUpgradeable.sendValue(payable(owner()), address(this).balance * 20 / 100);
  }


  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "No token");

    return sharedNFTLogic.createMetadataEdition(name(), description, imageUrl, animationUrl, tokenId, editionSize);
  }


}
