// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../HybridHiveCore.sol";
import "../interfaces/IHybridHiveCore.sol";

contract TokenOperatorMock is Ownable {
    HybridHiveCore public hybridHiveCore;

    function setCoreAddress(address _hybridHiveCore) public {
        hybridHiveCore = HybridHiveCore(_hybridHiveCore);
    }

    function mintToken(
        uint256 _tokenId,
        address _account,
        uint256 _amount
    ) public onlyOwner {
        // @todo implement onlyOperator(_tokenId)
        hybridHiveCore.mintToken(_tokenId, _account, _amount);
    }

    function burnToken(
        uint256 _tokenId,
        address _account,
        uint256 _amount
    ) public onlyOwner {
        // @todo implement onlyOperator(_tokenId)
        hybridHiveCore.burnToken(_tokenId, _account, _amount);
    }

    function updateParentAggregator(
        uint256 _tokenId,
        uint256 _parentAggregatorId
    ) public onlyOwner {
        hybridHiveCore.updateParentAggregator(
            IHybridHiveCore.EntityType.TOKEN,
            _tokenId,
            _parentAggregatorId
        );
    }
}
