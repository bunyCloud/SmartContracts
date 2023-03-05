// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';

contract AuctionBuny is ERC721URIStorage {
  string public Name;
  string public Symbol;

  constructor() ERC721('The Auction BUNY', 'BUNY') {
    Name = name();
    Symbol = symbol();
  }

  struct BUNY {
    string name;
    string tokenURI;
    string des;
    uint uid;
    uint price;
    address payable creator;
    address payable owner;
    bool onauction;
  }

  struct Auction {
    uint initivalue;
    uint finalvalue;
    uint endtime;
    uint nid;
    address payable provider;
    address payable receiver;
    bool on;
    bool mark;
  }

  struct history {
    uint num;
  }

  //BUNY Uid
  uint public itemUid;
  //Auction Uid
  uint public auctionUid;
  //index
  mapping(uint => history) public hislen;
  //mapping
  mapping(uint => BUNY) public marketBoard;
  //mapping
  mapping(uint => Auction) public auctions;
  //mapping
  mapping(uint => address[]) public Historys;

  //BUNY
  function createNFT(string memory _name, string memory _tokenURI, string memory _des, uint _price) external {
    address payable sender = payable(msg.sender);
    //BUNY
    _safeMint((msg.sender), itemUid);
    //uid和uri一一对应
    _setTokenURI(itemUid, _tokenURI);
    //NFT对象
    BUNY memory newNFT = BUNY(_name, _tokenURI, _des, itemUid, _price, sender, sender, false);
    //FT加入市场
    marketBoard[itemUid] = newNFT;
    //
    Historys[itemUid].push(sender);
    //Index
    hislen[itemUid].num++;
    //增加 uid + 1
    itemUid++;
    emit NftMinted((msg.sender), itemUid);
  }

  //
  function getURI(uint _id) public view returns (string memory) {
    string memory thisURI = tokenURI(_id);
    return thisURI;
  }

  //
  function getOwner(uint _id) public view returns (address) {
    return ownerOf(_id);
  }

  //
  function getHislen(uint _id) public view returns (uint) {
    return hislen[_id].num;
  }

  event NftMinted(address owner, uint itemUid);

  // Events that will be emitted on changes.
  event HighestBidIncreased(address bidder, uint _auction, uint amount);
  // The auction has ended.
  event AuctionEnded(address winner, uint amount);
  // The auction has success.
  event AuctionComplete(address from, address to);
  event AuctionCreated(uint _uid, uint _time, uint _value);
  /// The auction has already ended.
  error AuctionAlreadyEnded();
  /// There is already a higher or equal bid.
  error BidNotHighEnough(uint highestBid);
  /// The auction has not ended yet.
  error AuctionNotYetEnded();
  /// The function auctionEnd has already been called.
  error AuctionEndAlreadyCalled();
  /// Poor
  error Poor();
  /// Wrong
  error Wrong();
  /// Not Yours
  error NotYours();

  function createAuction(uint _uid, uint _value, uint _time) external {
    if (!_exists(_uid)) revert Wrong();
    if (msg.sender != ownerOf(_uid)) revert NotYours();

    address payable x = payable(msg.sender);

    marketBoard[_uid].onauction = true;

    Auction memory newAuction = Auction(_value, _value, block.timestamp + _time, _uid, x, x, true, false);
    auctions[_uid] = newAuction;

    emit AuctionCreated(_uid, block.timestamp + _time, _value);
  }

  function Bid(uint _id, uint price) external {
    if (auctions[_id].on == false) revert AuctionAlreadyEnded();
    //
    if (block.timestamp > auctions[_id].endtime) revert AuctionAlreadyEnded();
    //
    if (price > msg.sender.balance) revert Poor();
    //
    if (price <= auctions[_id].finalvalue) revert BidNotHighEnough(auctions[_id].finalvalue);
    //
    auctions[_id].finalvalue = price;
    auctions[_id].provider = auctions[_id].receiver;
    auctions[_id].receiver = payable(msg.sender);
    emit HighestBidIncreased(msg.sender, _id, price);
  }

  function claim(uint _id) public payable {
    if (block.timestamp < auctions[_id].endtime) revert AuctionNotYetEnded();
    if (auctions[_id].receiver != msg.sender) revert NotYours();
    address payable sender = payable(msg.sender);
    Historys[_id].push(msg.sender);
    hislen[_id].num++;
    address t = marketBoard[_id].owner;
    marketBoard[_id].owner = sender;
    marketBoard[_id].onauction = false;
    marketBoard[_id].price = auctions[_id].finalvalue;

    payable(ownerOf(_id)).transfer(msg.value);
    _transfer(ownerOf(_id), msg.sender, _id);
    // uint vv = auctions[_id].finalvalue;
    // payable(ownerOf(_id)).transfer(vv);
    emit AuctionComplete(t, msg.sender);
  }
}
