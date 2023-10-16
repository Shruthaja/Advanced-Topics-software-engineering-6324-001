// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract ExampleContract {
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }

    function set(address _newOwner) internal {
        owner = _newOwner;
       
    }

    function get() public view returns (address) {
        return owner;
    }
}
// This is an example of where the dead-code detector is indeed working fine. 
// This is also an internal function however unlike in the other contracts it is truly never used.

// Internal library
library L {
    function add(uint a, uint b) internal pure returns (uint) {
        return a + b;
    }
}

contract testforpositive {
    function test(uint x, uint y) public view returns (uint) {
        // Call the internal library function
        return L.add(x, y);
    }
}


// This is an example of where the dead-code detector is indeed working fine. 
// This is also an internal function which is used. The detector is reporting this correctly.