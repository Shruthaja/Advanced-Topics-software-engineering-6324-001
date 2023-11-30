// ContractA.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ContractA {
    event EventA();

    function functionA() public {
        emit EventA();
    }

    function functionB() public {
        functionA();
    }
}
