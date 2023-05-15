// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../interfaces/IHybridHiveCore.sol";
import "./HybridHiveStorage.sol";

contract HybridHiveGeneralGetters is HybridHiveStorage {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    function getEntityName(
        IHybridHiveCore.EntityType _entityType,
        uint256 _entityId
    ) public view returns (string memory) {
        if (_entityType == IHybridHiveCore.EntityType.TOKEN) {
            return _tokensData[_entityId].name;
        } else if (_entityType == IHybridHiveCore.EntityType.AGGREGATOR) {
            return _aggregatorsData[_entityId].name;
        }
    }

    function getEntitySymbol(
        IHybridHiveCore.EntityType _entityType,
        uint256 _entityId
    ) public view returns (string memory) {
        if (_entityType == IHybridHiveCore.EntityType.TOKEN) {
            return _tokensData[_entityId].symbol;
        } else if (_entityType == IHybridHiveCore.EntityType.AGGREGATOR) {
            return _aggregatorsData[_entityId].symbol;
        }
    }

    function getEntityURI(
        IHybridHiveCore.EntityType _entityType,
        uint256 _entityId
    ) public view returns (string memory) {
        if (_entityType == IHybridHiveCore.EntityType.TOKEN) {
            return _tokensData[_entityId].uri;
        } else if (_entityType == IHybridHiveCore.EntityType.AGGREGATOR) {
            return _aggregatorsData[_entityId].uri;
        }
    }

    /**
     * Get the absolute balance of spesific token
     *
     * @param _tokenId token Id
     * @param _account: address of which we what to calculate the token global share
     *
     * Requirements:
     * _tokenId might not be equal to 0
     * _tokenId should exist
     */
    function getTokenBalance(
        uint256 _tokenId,
        address _account
    ) public view returns (uint256) {
        require(_tokenId > 0);
        require(_tokenIds.contains(_tokenId));

        return _balances[_tokenId][_account];
    }

    function getAllowedTokenHolders(
        uint256 _tokenId
    ) public view returns (address[] memory) {
        //@todo add validations if
        return _allowedHolders[_tokenId].values();
    }

    /**
     * Check if account is allowed to hold spesific token
     *
     * @param _tokenId token Id
     * @param _account account to check
     *
     */
    function isAllowedTokenHolder(
        uint256 _tokenId,
        address _account
    ) public view returns (bool) {
        return _allowedHolders[_tokenId].contains(_account);
    }
}
