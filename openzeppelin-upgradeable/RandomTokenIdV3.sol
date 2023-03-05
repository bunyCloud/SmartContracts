
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
 
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import './Randomness.sol';
import './SlothVDF.sol';
 
contract RandomTokenIdv1 is ERC721  {
    
    using Randomness for Randomness.RNG;
     
    Randomness.RNG private _rng;

   uint256 public editionSize = 0;
    uint16[100] public ids;
    uint16 private index;
    uint256 public randomNumber = 0;
     mapping(address => uint256) public seeds;
    uint256 public prime = 432211379112113246928842014508850435796007;
    uint256 public iterations = 1000;
 
    constructor() ERC721('RandomIdv1', 'RNDMv1') {}
 
     function mint(address[] calldata _to, uint256 proof) external {
        require(SlothVDF.verify(proof, seeds[msg.sender], prime, iterations), 'Invalid proof');
 
        uint256 _randomness = proof;
        uint256 _random;
        for (uint256 i = 0; i < _to.length; i++) {
            (_randomness, _random) = _rng.getRandom(_randomness);
            _safeMint(_to[i], _pickRandomUniqueId(_random));
        }
    }
 
    function _pickRandomUniqueId(uint256 random) private returns (uint256 id) {
        uint256 len = ids.length - index++;
        require(len > 0, 'no ids left');
        uint256 randomIndex = random % len;
        id = ids[randomIndex] != 0 ? ids[randomIndex] : randomIndex;
        ids[randomIndex] = uint16(ids[len - 1] == 0 ? len - 1 : ids[len - 1]);
        ids[len - 1] = 0;
    }
       //seed is generated using sender address
    function createSeed() external payable returns(uint) {
        // commit funds
                seeds[msg.sender] = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, blockhash(block.number - 1))));
                    }
 
    function prove(uint256 proof) external returns(uint) {
        // see if the proof is valid for the seed associated with the address
        require(SlothVDF.verify(proof, seeds[msg.sender], prime, iterations), 'Invalid proof');
 
        // use the proof as a provable random number
         randomNumber = proof;
    }
}