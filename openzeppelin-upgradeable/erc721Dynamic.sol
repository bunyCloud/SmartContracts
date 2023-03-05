// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import { ERC721Upgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC721/presets/ERC721PresetMinterPauserAutoIdUpgradeable.sol';
import { IERC2981Upgradeable, IERC165Upgradeable } from '@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol';
import { OwnableUpgradeable } from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import { CountersUpgradeable } from '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import { AddressUpgradeable } from '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import { SharedNFTLogic } from './SharedNFTLogic.sol';
import { IEditionSingleMintable } from './IEditionSingleMintable.sol';


contract erc721Dynamic is ERC721Upgradeable, IEditionSingleMintable, IERC2981Upgradeable, OwnableUpgradeable {
  using CountersUpgradeable for CountersUpgradeable.Counter;
  event PriceChanged(uint256 amount);
  event BunyMint(uint256 indexed tokenId);
  event EditionSold(uint256 price, address owner);
  event TimeOut(bool paused, uint time);  
  event PublicMint(bool paused, uint time);  
  event MaxMintChanged(uint256 maxMint);
  CountersUpgradeable.Counter private atTokenId;
  string public baseURI;
  string public description;
  uint256 public editionSize;
  uint256 public currentSupply;
  bool public paused = false;
  bool public publicMint = false; 
  uint256 royaltyBPS;
  uint256 public salePrice;
  uint256 public preSalePrice;
  uint256 public maxMint;
  address payable[] public holders;
  address payable [] public whitelistWallets;
  mapping(address => bool) allowedMinters;
  mapping(address => bool) public whitelist;



  
  SharedNFTLogic private immutable sharedNFTLogic;


constructor(
    SharedNFTLogic _sharedNFTLogic) {
    sharedNFTLogic = _sharedNFTLogic;
  }


  
  function initialize(
    address _owner,
    string memory _baseURI,
    string memory _name,
    string memory _symbol,
    string memory _description,
    uint256 _editionSize,
    uint256 _royaltyBPS
  ) public initializer {
    __ERC721_init(_name, _symbol);
    __Ownable_init();
    transferOwnership(_owner);
    baseURI = _baseURI;
    description = _description;
    editionSize = _editionSize;
    royaltyBPS = _royaltyBPS;
    atTokenId.increment();
  }

  
function totalSupply() public view returns (uint256) {
    return atTokenId.current() - 1;
  }


   modifier isWhitelisted(address _address) {
      require(whitelist[_address], "Whitelist: You need to be whitelisted");
      _;
    }

function addUser(address _addressToWhitelist) public onlyOwner {
      whitelist[_addressToWhitelist] = true;
          whitelistWallets.push(payable(_addressToWhitelist));
         }

function verifyUser(address _whitelistedAddress) public view returns(bool) {
      bool userIsWhitelisted = whitelist[_whitelistedAddress];
      return userIsWhitelisted;
    }


function addManyToWhitelist(address[] memory _beneficiaries) public onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
                 whitelistWallets.push(payable(_beneficiaries[i]));

    }

  }


function setPaused(bool _state) public onlyOwner {
    paused = _state;
    emit TimeOut(paused, block.timestamp);
  }

  function setMaxMint(uint256 _maxMint) external onlyOwner {
    maxMint = _maxMint;
    emit MaxMintChanged(maxMint);
  }
   
function getHolders() public view returns(address payable[] memory) {
        return holders;
    }

function getWhitelistWallets() public view returns(address payable[] memory) {
        return whitelistWallets;
    }


function publicMintActive(bool _publicMint) public onlyOwner {
    publicMint = _publicMint;
    emit PublicMint(publicMint, block.timestamp);
  }


function presale() external payable returns (uint256) {
    require(!paused, "Down the rabbit hole. Contract is paused!");
    require(whitelist[msg.sender], "Requires user is whitelisted");  
    require(atTokenId.current() <= (editionSize - maxMint), "Max mint limit per wallet reached!");
    require(preSalePrice > 0, 'Not for sale');
    require(msg.value == preSalePrice, 'Wrong price');
    address[] memory toMint = new address[](1);
    toMint[0] = msg.sender;
    holders.push(payable(msg.sender));
    emit EditionSold(preSalePrice, msg.sender);
    return _mintEditions(toMint);
  }

function purchase() external payable returns (uint256) {
    require(!paused, "Down the rabbit hole. Contract is paused!");
    require(publicMint,"Public mint not enabled" );
    require(atTokenId.current() <= (editionSize - maxMint), "Max mint limit per wallet reached!");
    require(salePrice > 0, 'Not for sale');
    require(msg.value == salePrice, 'Wrong price');
    address[] memory toMint = new address[](1);
    toMint[0] = msg.sender;
    holders.push(payable(msg.sender));
    emit EditionSold(salePrice, msg.sender);
    return _mintEditions(toMint);
  }


function setSalePrice(uint256 _salePrice) external onlyOwner {
    salePrice = _salePrice;
    emit PriceChanged(salePrice);
  }

function setPreSalePrice(uint256 _preSalePrice) external onlyOwner {
    preSalePrice = _preSalePrice;
    emit PriceChanged(salePrice);
  }

 

 function withdraw() external onlyOwner {
        AddressUpgradeable.sendValue(payable(owner()), address(this).balance);
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
    require(!paused, "Down the rabbit hole. Contract is paused!");
    require(_isAllowedToMint(), 'Needs to be an allowed minter');
    address[] memory toMint = new address[](1);
    toMint[0] = to;
    return _mintEditions(toMint);
  }

function mintEditions(address[] memory recipients) external override returns (uint256) {
    require(!paused, "Down the rabbit hole. Contract is paused!");
    require(_isAllowedToMint(), 'Needs to be an allowed minter');
    return _mintEditions(recipients);
  }

function owner() public view override(OwnableUpgradeable, IEditionSingleMintable) returns (address) {
    return super.owner();
  }

function setApprovedMinter(address minter, bool allowed) public onlyOwner {
    allowedMinters[minter] = allowed;
  }

function updateEditionURLs(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

  
function numberCanMint() public view override returns (uint256) {
    if (editionSize == 0) {
      return type(uint256).max;
    }
    return editionSize + 1 - atTokenId.current();
  }



function _mintEditions(address[] memory recipients) internal returns (uint256) {
    require(!paused, "Down the rabbit hole. Contract is paused!");
    uint256 startAt = atTokenId.current();
    uint256 endAt = startAt + recipients.length - 1;
    require(editionSize == 0 || endAt <= editionSize, 'Sold out');
    while (atTokenId.current() <= endAt) {
      _mint(recipients[atTokenId.current() - startAt], atTokenId.current());
      atTokenId.increment();
      emit BunyMint(atTokenId.current());
    }
    return atTokenId.current();
  }

function getURIs() public view returns (string memory) {
    return (baseURI);
  }

function royaltyInfo(uint256, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
    if (owner() == address(0x0)) {
      return (owner(), 0);
    }
    return (owner(), (_salePrice * royaltyBPS) / 10_000);
  }

function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    bytes32 tokenIdBytes;
    if (tokenId == 0) {
      tokenIdBytes = '0';
    } else {
      uint256 value = tokenId;
      while (value > 0) {
        tokenIdBytes = bytes32(uint256(tokenIdBytes) / (2 ** 8));
        tokenIdBytes |= bytes32(((value % 10) + 48) * 2 ** (8 * 31));
        value /= 10;
      }
    }

    bytes memory prefixBytes = bytes(baseURI);
    bytes memory tokenURIBytes = new bytes(prefixBytes.length + tokenIdBytes.length);
    uint8 i;
    uint8 index = 0;
    for (i = 0; i < prefixBytes.length; i++) {
      tokenURIBytes[index] = prefixBytes[i];
      index++;
    }
    for (i = 0; i < tokenIdBytes.length; i++) {
      tokenURIBytes[index] = tokenIdBytes[i];
      index++;
    }

    return string(tokenURIBytes);
  }

function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, IERC165Upgradeable) returns (bool) {
    return type(IERC2981Upgradeable).interfaceId == interfaceId || ERC721Upgradeable.supportsInterface(interfaceId);
  }




function OwnerOfToken(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= editionSize) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }


}
