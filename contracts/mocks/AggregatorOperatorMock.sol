// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../HybridHiveCore.sol";

contract AggregatorOperatorMock is Ownable {
    HybridHiveCore public hybridHiveCore;

    function setCoreAddress(address _hybridHiveCore) public {
        hybridHiveCore = HybridHiveCore(_hybridHiveCore);
    }
}
