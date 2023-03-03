//isSaleComplete.sol

contract NFTSale {
    uint public totalSold;
    uint public maxSupply;
    bool public isComplete;

    function isSoldOut() public returns (bool) {
        if(totalSold == maxSupply){
            isComplete = true;
        }
        return isComplete;
    }
}
