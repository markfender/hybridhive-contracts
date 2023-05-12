// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract HybridHiveCore {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /*
        @todo
        1. add events and event emiting
        2. errors messages
    
     */

    enum EntityType {
        UNDEFINED,
        TOKEN,
        AGGREGATOR
    }

    struct TokenData {
        string name;
        string symbol;
        string uri;
        address operator;
        uint256 tokenAggregator;
        uint256 totalSupply;
    }

    struct AggregatorData {
        string name;
        string symbol;
        string uri;
        address operator;
        uint256 parentAggregator;
        EntityType aggregatedEntityType;
    }

    struct GlobalTransfer {
        uint256 status; // 0 - doesn't exist, 10 - excecuted
        uint256 value; // GLOBAL SHARE
        uint256 tokenFromId;
        uint256 tokenToId;
        address sender;
        address recipient;
    }

    // CONSTANTS
    uint256 public constant DENOMINATOR = 100000000; // 100 000 000

    // TOKENS
    // Set of all token Ids
    EnumerableSet.UintSet private _tokenIds;
    // Mapping from token ID to detailed tokens data
    mapping(uint256 => TokenData) private _tokensData;
    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;
    // Mapping from token ID to list of allowed holders
    mapping(uint256 => EnumerableSet.AddressSet) private _allowedHolders;

    // AGGREGATORS
    // Set of all aggregator Ids
    EnumerableSet.UintSet private _aggregatorIds;
    // Mapping from aggregator ID to detailed aggregator date
    mapping(uint256 => AggregatorData) private _aggregatorsData;
    // Mapping from aggregator ID to a set of aggregated entities
    mapping(uint256 => EnumerableSet.UintSet) private _subEntities;
    // Mapping from aggregator ID to a mapping from sub entity Id to sub entity share
    mapping(uint256 => mapping(uint256 => uint256)) private _weights; // all subentities shares should be equal to 100 000 000 = 100%

    // GLOBAL TRANSFER
    mapping(uint256 => GlobalTransfer) private _globalTransfer;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    function createToken(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _tokenURI,
        address _tokenOperator, // @todo check if it has appropriabe fields like `delegate`
        uint256 _tokenAggregator,
        address[] memory _tokenHolders, //@todo add validation _tokenCommunityMembers.len == _memberBalances.len
        uint256[] memory _holderBalances
    ) public returns (uint256) {
        // @todo add validations
        require(_tokenOperator != address(0));

        uint256 newTokenId = _tokenIds.length() + 1;
        assert(!_tokenIds.contains(newTokenId)); // there should be no token id
        _tokenIds.add(newTokenId);

        TokenData storage newToken = _tokensData[newTokenId]; // skip the first token index
        newToken.name = _tokenName;
        newToken.symbol = _tokenSymbol;
        newToken.uri = _tokenURI;
        newToken.operator = _tokenOperator;
        newToken.tokenAggregator = _tokenAggregator;

        for (uint256 i = 0; i < _tokenHolders.length; i++) {
            // Add account to the allowed token holder list
            _addAllowedHolder(newTokenId, _tokenHolders[i]);

            _mintToken(newTokenId, _tokenHolders[i], _holderBalances[i]);
        }

        return newTokenId;
    }

    // PRIVAT FUNCTIONS

    // TOKEN INTERNAL FUCNTIONS
    function _addAllowedHolder(uint256 _tokenId, address _account) internal {
        // @todo add validations
        require(_allowedHolders[_tokenId].add(_account));
    }

    function _mintToken(
        uint256 _tokenId,
        address _recepient,
        uint256 _amount
    ) internal {
        TokenData storage tokenData = _tokensData[_tokenId];
        require(isAllowedTokenHolder(_tokenId, _recepient)); // @todo consider moving this condition to modifier

        _balances[_tokenId][_recepient] += _amount;
        tokenData.totalSupply += _amount;
    }

    function _burnToken(
        uint256 _tokenId,
        address _recepient,
        uint256 _amount
    ) internal {
        TokenData storage tokenData = _tokensData[_tokenId];
        // DO NOT CHECK IF RECIPIENT IS A MEMBER
        // it should be possible to burn tokens even if holder is removed from the allowed holder list

        _balances[_tokenId][_recepient] -= _amount;
        tokenData.totalSupply -= _amount;
    }

    // GETTER FUNCTIONS

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

    /**
     * Get the id of the aggregator parent
     *
     * @param _aggregatorId aggregator id
     *
     * @return 0 - if no parent, aggregator parent if exists
     * Requirements:
     * aggregator with such id should exist
     */
    function getAggregatorParent(
        uint256 _aggregatorId
    ) public view returns (uint256) {
        require(_aggregatorIds.contains(_aggregatorId));
        return _aggregatorsData[_aggregatorId].parentAggregator;
    }

    /**
     * Get the type and list of aggregator sub entities
     *
     * @param _aggregatorId aggregator id
     *
     * @return
     * EntityType - UNDEFINED if no subentities,
     * uint256[] memory - list of tokens or aggregators Id
     *
     * Requirements:
     * aggregator with such id should exist
     */
    function getAggregatorSubEntities(
        uint256 _aggregatorId
    ) public view returns (EntityType, uint256[] memory) {
        require(_aggregatorIds.contains(_aggregatorId));

        return (
            _aggregatorsData[_aggregatorId].aggregatedEntityType,
            _subEntities[_aggregatorId].values()
        );
    }
}
