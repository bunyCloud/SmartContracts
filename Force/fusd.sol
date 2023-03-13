// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

contract FUSD {
mapping (address => uint) public wards;
function rely(address guy) external auth { wards[guy] = 1; }
function deny(address guy) external auth { wards[guy] = 0; }
modifier auth {
require(wards[msg.sender] == 1, "FUSD/not-authorized");
_;
}

  // --- ERC20 Data ---
string public name = "Force Stablecoin";
string public symbol = "FUSD";
string public constant version = "1";
uint8 public constant decimals = 18;
uint256 public totalSupply;

mapping (address => uint256) public balanceOf;
mapping (address => mapping (address => uint256)) public allowance;
mapping (address => uint256) public nonces;

event Approval(address indexed src, address indexed guy, uint256 wad);
event Transfer(address indexed src, address indexed dst, uint256 wad);

// --- Math ---
function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, "FUSD/addition-overflow");
}

function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x, "FUSD/subtraction-underflow");
}

// --- EIP712 niceties ---
bytes32 public DOMAIN_SEPARATOR;
bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");

constructor(uint256 chainId_) {
    wards[msg.sender] = 1;
    DOMAIN_SEPARATOR = keccak256(abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes(name)),
        keccak256(bytes(version)),
        chainId_,
        address(this)
    ));
}

// --- Token ---
function transfer(address dst, uint256 wad) external returns (bool) {
    return transferFrom(msg.sender, dst, wad);
}

function transferFrom(address src, address dst, uint256 wad) public returns (bool) {
    require(balanceOf[src] >= wad, "FUSD/insufficient-balance");
    if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
        require(allowance[src][msg.sender] >= wad, "FUSD/insufficient-allowance");
        allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
    }
    balanceOf[src] = sub(balanceOf[src], wad);
    balanceOf[dst] = add(balanceOf[dst], wad);
    emit Transfer(src, dst, wad);
    return true;
}

function mint(address usr, uint256 wad) external auth {
    balanceOf[usr] = add(balanceOf[usr], wad);
    totalSupply = add(totalSupply, wad);
    emit Transfer(address(0), usr, wad);
}


  
   function burn(address usr, uint wad) external {
    require(balanceOf[usr] >= wad, "FUSD/insufficient-balance");
    if (usr != msg.sender && allowance[usr][msg.sender] != 2**256 - 1) {
        require(allowance[usr][msg.sender] >= wad, "FUSD/insufficient-allowance");
        allowance[usr][msg.sender] = sub(allowance[usr][msg.sender], wad);
    }
    balanceOf[usr] = sub(balanceOf[usr], wad);
    totalSupply    = sub(totalSupply, wad);
    emit Transfer(usr, address(0), wad);
}

    function approve(address usr, uint wad) external returns (bool) {
        allowance[msg.sender][usr] = wad;
        emit Approval(msg.sender, usr, wad);
        return true;
    }

    // --- Alias ---
    function push(address usr, uint wad) external {
        transferFrom(msg.sender, usr, wad);
    }
    function pull(address usr, uint wad) external {
        transferFrom(usr, msg.sender, wad);
    }
    function move(address src, address dst, uint wad) external {
        transferFrom(src, dst, wad);
    }

    // --- Approve by signature ---
    function permit(address holder, address spender, uint256 nonce, uint256 expiry,
                    bool allowed, uint8 v, bytes32 r, bytes32 s) external
    {
        bytes32 digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH,
                                     holder,
                                     spender,
                                     nonce,
                                     expiry,
                                     allowed))
        ));

        require(holder != address(0), "FUSD/invalid-address-0");
        require(holder == ecrecover(digest, v, r, s), "FUSD/invalid-permit");
        require(expiry == 0 || block.timestamp <= expiry, "FUSD/permit-expired");
        require(nonce == nonces[holder]++, "FUSD/invalid-nonce");
    uint256 wad = allowed ? 2**256 - 1 : 0;
        allowance[holder][spender] = wad;
        emit Approval(holder, spender, wad);
    }
}
