// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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

    function addAggregatorDetails(
        uint256 _aggregatorId,
        string memory _aggregatorURI,
        address _aggregatorOperator,
        uint256 _parentAggregatorId
    ) public onlyOwner {
        hybridHiveCore.addAggregatorDetails(
            _aggregatorId,
            _aggregatorURI,
            _aggregatorOperator,
            _parentAggregatorId
        );
    }
}
