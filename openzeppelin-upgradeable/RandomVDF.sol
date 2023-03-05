// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
 
import './SlothVDF.sol';
 
contract RandomVDFv1  {
     
    // large prime
    uint256 public prime = 432211379112113246928842014508850435796007;
    // adjust for block finality
    uint256 public iterations = 1000;
    // increment nonce to increase entropy
    uint256 private nonce;
    // address -> vdf seed
    mapping(address => uint256) public seeds;
 
    function createSeed() external payable {
        // commit funds/tokens/etc here
        // create a pseudo random seed as the input
        seeds[msg.sender] = uint256(keccak256(abi.encodePacked(msg.sender, nonce++, block.timestamp, blockhash(block.number - 1))));
    }
 
    function prove(uint256 proof) external {
        // see if the proof is valid for the seed associated with the address
        require(SlothVDF.verify(proof, seeds[msg.sender], prime, iterations), 'Invalid proof');
 
        // use the proof as a provable random number
        uint256 _random = proof;
    }
}