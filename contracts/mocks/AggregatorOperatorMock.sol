// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../HybridHiveCore.sol";
import "../interfaces/IHybridHiveCore.sol";

contract AggregatorOperatorMock is Ownable {
    HybridHiveCore public hybridHiveCore;

    function setCoreAddress(address _hybridHiveCore) public {
        hybridHiveCore = HybridHiveCore(_hybridHiveCore);
    }

    function updateParentAggregator(
        uint256 _aggregatorId,
        uint256 _parentAggregatorId
    ) public onlyOwner {
        hybridHiveCore.updateParentAggregator(
            IHybridHiveCore.EntityType.AGGREGATOR,
            _aggregatorId,
            _parentAggregatorId
        );
    }
}
