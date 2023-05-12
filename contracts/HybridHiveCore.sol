// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/IHybridHiveCore.sol";

// Uncomment this line to use console.log
import "hardhat/console.sol";

contract HybridHiveCore {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /*
        @todo
        1. add events and event emiting
        2. errors messages
        3. avoid circles in the tree
    
    */

    // CONSTANTS
    uint256 public constant DENOMINATOR = 100000000; // 100 000 000

    // TOKENS
    // Set of all token Ids
    EnumerableSet.UintSet private _tokenIds;
    // Mapping from token ID to detailed tokens data
    mapping(uint256 => IHybridHiveCore.TokenData) private _tokensData;
    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;
    // Mapping from token ID to list of allowed holders
    mapping(uint256 => EnumerableSet.AddressSet) private _allowedHolders;

    // AGGREGATORS
    // Set of all aggregator Ids
    EnumerableSet.UintSet private _aggregatorIds;
    // Mapping from aggregator ID to detailed aggregator date
    mapping(uint256 => IHybridHiveCore.AggregatorData) private _aggregatorsData;
    // Mapping from aggregator ID to a set of aggregated entities
    mapping(uint256 => EnumerableSet.UintSet) private _subEntities;
    // Mapping from aggregator ID to a mapping from sub entity Id to sub entity share
    mapping(uint256 => mapping(uint256 => uint256)) private _weights; // all subentities shares should be equal to 100 000 000 = 100%

    // GLOBAL TRANSFER
    mapping(uint256 => IHybridHiveCore.GlobalTransfer) private _globalTransfer;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    //MODIFIER

    modifier onlyOperator(
        IHybridHiveCore.EntityType _entityType,
        uint256 _entityId
    ) {
        if (_entityType == IHybridHiveCore.EntityType.TOKEN) {
            require(_tokenIds.contains(_entityId));
            require(_tokensData[_entityId].operator == msg.sender);
        } else if (_entityType == IHybridHiveCore.EntityType.AGGREGATOR) {
            require(_aggregatorIds.contains(_entityId));
            require(_aggregatorsData[_entityId].operator == msg.sender);
        } else revert("Unknown entity type");

        _;
    }

    function createToken(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _tokenURI,
        address _tokenOperator, // @todo check if it has appropriabe fields like `delegate`
        uint256 _parentAggregator,
        address[] memory _tokenHolders, //@todo add validation _tokenCommunityMembers.len == _memberBalances.len
        uint256[] memory _holderBalances
    ) public returns (uint256) {
        // @todo add validations
        require(_tokenOperator != address(0));

        uint256 newTokenId = _tokenIds.length() + 1;
        assert(!_tokenIds.contains(newTokenId)); // there should be no token id
        _tokenIds.add(newTokenId);

        IHybridHiveCore.TokenData storage newToken = _tokensData[newTokenId]; // skip the first token index
        newToken.name = _tokenName;
        newToken.symbol = _tokenSymbol;
        newToken.uri = _tokenURI;
        newToken.operator = _tokenOperator;
        newToken.parentAggregator = _parentAggregator;

        for (uint256 i = 0; i < _tokenHolders.length; i++) {
            // Add account to the allowed token holder list
            _addAllowedHolder(newTokenId, _tokenHolders[i]);

            _mintToken(newTokenId, _tokenHolders[i], _holderBalances[i]);
        }

        return newTokenId;
    }

    function mintToken(
        uint256 _tokenId,
        address _account,
        uint256 _amount
    ) public onlyOperator(IHybridHiveCore.EntityType.TOKEN, _tokenId) {
        // @todo implement onlyOperator(_tokenId)
        _mintToken(_tokenId, _account, _amount);
    }

    function burnToken(
        uint256 _tokenId,
        address _account,
        uint256 _amount
    ) public onlyOperator(IHybridHiveCore.EntityType.TOKEN, _tokenId) {
        // @todo implement onlyOperator(_tokenId)
        _burnToken(_tokenId, _account, _amount);
    }

    // @todo add validations
    function addAllowedHolder(
        uint256 _tokenId,
        address _newAllowedHolder
    ) public onlyOperator(IHybridHiveCore.EntityType.TOKEN, _tokenId) {
        _addAllowedHolder(_tokenId, _newAllowedHolder);
    }

    function createAggregator(
        string memory _aggregatorName,
        string memory _aggregatorSymbol,
        string memory _aggregatorURI,
        address _aggregatorOperator, // @todo FOR future implementaionsЖcheck if it has appropriabe fields like `delegate`
        uint256 _parentAggregator,
        IHybridHiveCore.EntityType _aggregatedEntityType,
        uint256[] memory _aggregatedEntities, // @todo add validation _aggregatedEntities.len == _aggregatedEntitiesWeights.len
        uint256[] memory _aggregatedEntitiesWeights // @todo should be equal to denminator
    ) public returns (uint256) {
        // @todo add validations
        require(_aggregatorOperator != address(0));

        uint256 newAggregatorId = _aggregatorIds.length() + 1;
        assert(!_aggregatorIds.contains(newAggregatorId)); // there should be no such aggregator id
        _aggregatorIds.add(newAggregatorId);

        IHybridHiveCore.AggregatorData storage newAggregator = _aggregatorsData[
            newAggregatorId
        ]; // skip the first token index
        newAggregator.name = _aggregatorName;
        newAggregator.symbol = _aggregatorSymbol;
        newAggregator.uri = _aggregatorURI;
        newAggregator.operator = _aggregatorOperator;
        newAggregator.parentAggregator = _parentAggregator;
        newAggregator.aggregatedEntityType = _aggregatedEntityType;

        // add aggregator subentities to the list of entities
        for (uint256 i = 0; i < _aggregatedEntities.length; i++) {
            _subEntities[newAggregatorId].add(_aggregatedEntities[i]);
        }

        // sum of all weights should be equal to 100%
        uint256 totalWeights = 0;
        for (uint256 i = 0; i < _aggregatedEntitiesWeights.length; i++) {
            totalWeights += _aggregatedEntitiesWeights[i];

            _weights[newAggregatorId][
                _aggregatedEntities[i]
            ] = _aggregatedEntitiesWeights[i];
        }
        require(totalWeights == DENOMINATOR);

        return newAggregatorId;
    }

    // GENERAL FUCNCTIONS
    // @todo restrict control to onlyOperatorValidator
    function updateParentAggregator(
        IHybridHiveCore.EntityType _entityType,
        uint256 _entityId,
        uint256 _parentAggregatorId
    ) public onlyOperator(_entityType, _entityId) {
        // @todo validate if it matches the type

        require(
            _aggregatorsData[_parentAggregatorId].aggregatedEntityType ==
                _entityType
        );

        if (_entityType == IHybridHiveCore.EntityType.AGGREGATOR) {
            _aggregatorsData[_entityId].parentAggregator = _parentAggregatorId;
        } else if (_entityType == IHybridHiveCore.EntityType.TOKEN) {
            _tokensData[_entityId].parentAggregator = _parentAggregatorId;
        }
    }

    function addSubEntity(
        IHybridHiveCore.EntityType _entityType,
        uint256 _aggregatorId,
        uint256 _subEntity
    ) public onlyOperator(_entityType, _aggregatorId) {
        require(_subEntities[_aggregatorId].add(_subEntity));

        _weights[_aggregatorId][_subEntity] = 0; // weight of the new entity should be zero
    }

    // INTERNAL FUNCTIONS

    function _updateSubEntitiesWeights(
        uint256 _aggregatorId,
        uint256 _entityIdFrom,
        uint256 _entityIdTo,
        uint256 _share // DENOMINATOR = 100%
    ) internal {
        require(_share > 0);
        _weights[_aggregatorId][_entityIdFrom] -= _share;
        _weights[_aggregatorId][_entityIdTo] += _share;
    }

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
        IHybridHiveCore.TokenData storage tokenData = _tokensData[_tokenId];
        require(isAllowedTokenHolder(_tokenId, _recepient)); // @todo consider moving this condition to modifier

        _balances[_tokenId][_recepient] += _amount;
        tokenData.totalSupply += _amount;
    }

    function _burnToken(
        uint256 _tokenId,
        address _recepient,
        uint256 _amount
    ) internal {
        IHybridHiveCore.TokenData storage tokenData = _tokensData[_tokenId];
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
        //@todo check if parent connected this aggregator as a child
        return _aggregatorsData[_aggregatorId].parentAggregator;
    }

    /*
        Token _tokenId  should be a part of the networks _networkRootAggregator
        _tokenId might not be 0
    */

    function getGlobalTokenShare(
        uint256 _networkRootAggregator,
        uint256 _tokenId,
        address _account
    ) public view returns (uint256) {
        // @todo add validate if aggregator is root _networkRootAggregator
        /*
        uint256 globalShareValue = 0;
        uint256 depthCounter = 0;
        uint256 aggregatorPointer = 0;

        while (aggregatorPointer != _networkRootAggregator) {
            
            aggregatorPointer _tokensData[_tokenId].parentAggregator 
        }*/

        return 0;
    }

    function getTokenNumberInNetwork(
        uint256 _aggregatorId
    ) public view returns (uint256) {
        return _getTokenNumberInNetwork(_aggregatorId);
    }

    function _getTokenNumberInNetwork(
        uint256 _entityId
    ) private view returns (uint256) {
        if (
            _aggregatorsData[_entityId].aggregatedEntityType ==
            IHybridHiveCore.EntityType.TOKEN
        ) return _subEntities[_entityId].length();
        else {
            uint256 tokensCount = 0;
            for (uint256 i = 0; i < _subEntities[_entityId].length(); i++) {
                tokensCount += _getTokenNumberInNetwork(
                    _subEntities[_entityId].at(i)
                );
            }
            return tokensCount;
        }
    }

    function getTokensInNetwork(
        uint256 _aggregatorId
    ) public view returns (uint256[] memory) {
        uint256 tokensNumber = _getTokenNumberInNetwork(_aggregatorId);
        uint256[] memory tokensIdList = new uint[](tokensNumber);
        (tokensIdList, ) = _getTokensInNetwork(_aggregatorId, tokensIdList, 0);
        return tokensIdList;
    }

    function _getTokensInNetwork(
        uint256 _entityId,
        uint256[] memory leafArray,
        uint256 index
    ) public view returns (uint256[] memory, uint256) {
        if (
            _aggregatorsData[_entityId].aggregatedEntityType ==
            IHybridHiveCore.EntityType.TOKEN
        ) {
            for (uint256 i = 0; i < _subEntities[_entityId].length(); i++) {
                leafArray[index] = _subEntities[_entityId].at(i);
                index++;
            }

            return (leafArray, index);
        } else {
            for (uint256 i = 0; i < _subEntities[_entityId].length(); i++) {
                (leafArray, index) = _getTokensInNetwork(
                    _subEntities[_entityId].at(i),
                    leafArray,
                    index
                );
            }
            return (leafArray, index);
        }
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
    ) public view returns (IHybridHiveCore.EntityType, uint256[] memory) {
        //@todo check if sub entities connected this aggregator as a parent
        require(_aggregatorIds.contains(_aggregatorId));

        return (
            _aggregatorsData[_aggregatorId].aggregatedEntityType,
            _subEntities[_aggregatorId].values()
        );
    }
}
