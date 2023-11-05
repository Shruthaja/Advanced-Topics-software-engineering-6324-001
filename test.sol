// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

//1

contract ExampleContract {
    address public owner;
    uint public data;
    
    constructor() {
        owner = msg.sender;
    }

    function set(address _newOwner) internal {
        owner = _newOwner;
       
    }

    function get() public view returns (address) {
        return owner;
    }
     function anotherUnusedFunction() public {
        // This function is also never called
        data = 0;
    }
}


//2

contract SimpleContract {
    uint public data;

    constructor() {
        data = 42;
    }

    function updateData(uint _value) public {
        // This is live code
        data = _value;
    }

    function unusedFunction() internal {
        // This function is never called
        data = 0;
    }

    function anotherUnusedFunction() private {
        // This function is also never called
        data = 0;
    }
}