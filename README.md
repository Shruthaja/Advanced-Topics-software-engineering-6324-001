# Advanced-software-engineering--6324-001

This project is concerned with the enhancement of the slither tool . As of this moment we are working on the [Bug] 1265 : Slither incorrectly reports internal library function as unused #1265 (https://github.com/crytic/slither/issues/1265).

On further inspection of the bug it is evident that the dead-code detector is falsely adding internal function calls that are being used later on in its report. This porject hopes to understand what the issue is and come up with a better logic to filter out the truly unused function calls.

False positive :

Upon successful installation and running we were able to get the below output :

BridgeGovernanceParameters.beginRedemptionTimeoutNotifierRewardMultiplierUpdate(BridgeGovernanceParameters.RedemptionData,uint32) (contracts/bridge/BridgeGovernanceParameters.sol#685-699) is never used and should be removed
BridgeGovernanceParameters.getNewDepositDustThreshold(BridgeGovernanceParameters.DepositData) (contracts/bridge/BridgeGovernanceParameters.sol#355-361) is never used and should be removed
BridgeGovernanceParameters.getNewDepositTreasuryFeeDivisor(BridgeGovernanceParameters.DepositData) (contracts/bridge/BridgeGovernanceParameters.sol#401-407) is never used and should be removed
BridgeGovernanceParameters.getNewDepositTxMaxFee(BridgeGovernanceParameters.DepositData) (contracts/bridge/BridgeGovernanceParameters.sol#442-448) is never used and should be removed
BridgeGovernanceParameters.getNewFraudChallengeDefeatTimeout(BridgeGovernanceParameters.FraudData) (contracts/bridge/BridgeGovernanceParameters.sol#1596-1602) is never used and should be removed
BridgeGovernanceParameters.getNewFraudChallengeDepositAmount(BridgeGovernanceParameters.FraudData) (contracts/bridge/BridgeGovernanceParameters.sol#1549-1555) is never used and should be removed
BridgeGovernanceParameters.getNewFraudNotifierRewardMultiplier(BridgeGovernanceParameters.FraudData) (contracts/bridge/BridgeGovernanceParameters.sol#1688-1694) is never used and should be removed
BridgeGovernanceParameters.getNewFraudSlashingAmount(BridgeGovernanceParameters.FraudData) (contracts/bridge/BridgeGovernanceParameters.sol#1640-1646) is never used and should be removed.........

Of this, on examining for example the first line itself we can see that the function "beginRedemptionTimeoutNotifierRewardMultiplierUpdate" is actually being used in line 649 of "tbtc-v2/solidity/contracts/bridge/BridgeGovernance.sol"

True positive :

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


output : 

INFO:Detectors:
ExampleContract.set(address) (tbtc-v2/solidity/contracts/test.sol#11-14) is never used and should be removed
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
