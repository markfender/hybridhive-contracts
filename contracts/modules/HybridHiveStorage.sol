// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// @todo fix 0.254 is missing

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../interfaces/IHybridHiveCore.sol";

contract HybridHiveStorage {
    // CONSTANTS
    uint256 public constant DENOMINATOR = 100000000; // 100 000 000

    // TOKENS // @todo remove underscore
    // Set of all token Ids
    EnumerableSet.UintSet internal _tokenSet;
    // Mapping from token ID to detailed tokens data
    mapping(uint256 => IHybridHiveCore.TokenData) internal _tokensData;
    // Mapping from token ID to list of allowed holders
    mapping(uint256 => EnumerableSet.AddressSet) internal _allowedHolders; // @todo probably remove this list

    // AGGREGATORS
    // Set of all aggregator Ids
    EnumerableSet.UintSet internal _aggregatorIds;
    // Mapping from aggregator ID to detailed aggregator date
    mapping(uint256 => IHybridHiveCore.AggregatorData)
        internal _aggregatorsData;
    // Mapping from aggregator ID to a set of aggregated entities
    mapping(uint256 => EnumerableSet.UintSet) internal _subEntities; // @todo add ability to exclude from _subEntities list
    // Mapping from aggregator ID to a mapping from sub entity Id to sub entity share
    mapping(uint256 => mapping(uint256 => uint256)) internal _weights;

    // GLOBAL TRANSFER
    mapping(uint256 => IHybridHiveCore.GlobalTransfer) internal _globalTransfer;
    uint256 internal totalGlobalTransfers;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string internal _uri;
}
