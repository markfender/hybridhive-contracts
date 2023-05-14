// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {UD60x18, convert} from "@prb/math/src/UD60x18.sol";

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
        4. switch to the absolute weights representations of the aggregator subentities
        5. use the fixed point lib
    
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
    mapping(uint256 => mapping(uint256 => UD60x18)) private _weights; // all subentities shares should be equal to 100 000 000 = 100%

    // GLOBAL TRANSFER
    mapping(uint256 => IHybridHiveCore.GlobalTransfer) private _globalTransfer;
    uint256 totalGlobalTransfers;

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
        for (uint256 i = 0; i < _aggregatedEntitiesWeights.length; i++) {
            _weights[newAggregatorId][_aggregatedEntities[i]] = convert(
                _aggregatedEntitiesWeights[i]
            );
        }
        //@todo recheck if it is needed
        //require(totalWeights == DENOMINATOR);

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

        _weights[_aggregatorId][_subEntity] = convert(0); // weight of the new entity should be zero
    }

    // @todo recheck
    function transfer(
        uint256 tokenId,
        address recipient,
        uint256 amount
    ) public {
        // @todo validate if recipient is a allowedHolder or not
        require(recipient != address(0), "Transfer to zero address");
        require(
            _balances[tokenId][msg.sender] >= amount,
            "Insufficient balance"
        );

        _balances[tokenId][msg.sender] -= amount;
        _balances[tokenId][recipient] += amount;
    }

    // GLOBAL TRANSFER
    /*
    @todo separate adding of the global transfer to the pending list and execution of it
    to prevent frontfuning of the tokens buring
    function addGlobalTransfer(
        IHybridHiveCore.GlobalTransfer memory _globalTransferConfig
    ) public {
        // @todo add access validation
        _globalTransfer[totalGlobalTransfers] = _globalTransferConfig;
        totalGlobalTransfers++;
    }
    function globalTransferExecution(uint256 _globalTransferId)
    */
    function _calculateMintAmount(
        uint256 _rootAggregator,
        uint256 _tokenId,
        address _recipient,
        UD60x18 _globalShare
    ) private view returns (uint256) {
        uint256 initialTokenBalance = _balances[_tokenId][_recipient];
        UD60x18 initialGlobalShare = getGlobalTokenShare(
            _rootAggregator,
            _tokenId,
            initialTokenBalance
        );
        UD60x18 amountOfTokensToMint = _globalShare
            .mul(convert(initialTokenBalance))
            .div(initialGlobalShare);
        return convert(amountOfTokensToMint);
    }

    function globalTransfer(
        uint256 _tokenFromId,
        uint256 _tokenToId,
        address _sender,
        address _recipient,
        uint256 _amount
    ) public {
        // @todo add validation
        // @todo validate if it is same as root of `_tokenToId`
        uint256 rootAggregator = getRootAggregator(
            _tokensData[_tokenFromId].parentAggregator
        );
        UD60x18 transferGlobalShare = getGlobalTokenShare(
            rootAggregator,
            _tokenFromId,
            _amount
        );

        // Generate the path up and path down
        uint256 pathFromLength = 1;
        // calculate path array length
        // get length of path up
        uint256 entityParent = _tokensData[_tokenFromId].parentAggregator;

        for (uint256 i = 0; entityParent != 0; i++) {
            entityParent = _aggregatorsData[entityParent].parentAggregator;
            pathFromLength++;
        }
        uint256 pathToLength = 1;
        // get length of path up
        entityParent = _tokensData[_tokenToId].parentAggregator;
        for (uint256 i = 0; entityParent != 0; i++) {
            entityParent = _aggregatorsData[entityParent].parentAggregator;
            pathToLength++;
        }
        // add tokens id
        uint256[] memory pathFrom = new uint[](pathFromLength);
        uint256[] memory pathTo = new uint[](pathToLength);

        entityParent = _tokensData[_tokenFromId].parentAggregator;
        for (uint256 i = 0; entityParent != 0; i++) {
            pathFrom[pathFrom.length - i - 2] = entityParent;
            entityParent = _aggregatorsData[entityParent].parentAggregator;
        }
        pathFrom[pathFrom.length - 1] = _tokenFromId;

        entityParent = _tokensData[_tokenToId].parentAggregator;
        for (uint256 i = 0; entityParent != 0; i++) {
            pathTo[pathTo.length - i - 2] = entityParent;
            entityParent = _aggregatorsData[entityParent].parentAggregator;
        }
        pathTo[pathTo.length - 1] = _tokenToId;

        //@todo validation should match pathFrom[0] == pathTo[0], and should match root

        UD60x18 globalAggregatorSharePathFrom = _weights[rootAggregator][
            pathFrom[1]
        ];
        UD60x18 globalAggregatorSharePathTo = _weights[rootAggregator][
            pathTo[1]
        ];
        _weights[rootAggregator][pathFrom[1]] = _weights[rootAggregator][
            pathFrom[1]
        ].sub(transferGlobalShare);
        _weights[rootAggregator][pathTo[1]] = _weights[rootAggregator][
            pathTo[1]
        ].add(transferGlobalShare);

        // iterative logic down to the rabit hole
        for (uint i = 1; i < pathFrom.length - 1; i++) {
            UD60x18 burnableShare = _weights[pathFrom[i]][pathFrom[i + 1]]
                .mul(transferGlobalShare)
                .div(globalAggregatorSharePathFrom);

            globalAggregatorSharePathFrom = (
                globalAggregatorSharePathFrom.mul(
                    _weights[pathFrom[i]][pathFrom[i + 1]]
                )
            );

            // burn down
            _updateSubEnitiesShare(
                pathFrom[i],
                pathFrom[i + 1],
                burnableShare, // calculate
                false
            );
        }

        for (uint i = 1; i < pathTo.length - 1; i++) {
            UD60x18 mintableShare = _weights[pathTo[i]][pathTo[i + 1]]
                .mul(transferGlobalShare)
                .div(globalAggregatorSharePathTo);

            globalAggregatorSharePathTo = globalAggregatorSharePathTo.mul(
                _weights[pathTo[i]][pathTo[i + 1]]
            );
            // mint down
            _updateSubEnitiesShare(
                pathTo[i],
                pathTo[i + 1],
                mintableShare, // calculate
                true
            );
        }
        // mint tokens to sender // @todo fix
        uint256 amountOfTokensToMint = _calculateMintAmount(
            rootAggregator,
            _tokenToId,
            _recipient,
            transferGlobalShare
        );
        _mintToken(_tokenToId, _recipient, amountOfTokensToMint);
        _burnToken(_tokenFromId, _sender, _amount);
    }

    // INTERNAL FUNCTIONS
    function _updateSubEnitiesShare(
        uint256 _aggregatorId,
        uint256 _entityIdFrom,
        UD60x18 _share,
        bool _action // false - if remove share, true id add share
    ) internal {
        // @todo add `_share` validation
        if (_action) {
            _weights[_aggregatorId][_entityIdFrom] = _weights[_aggregatorId][
                _entityIdFrom
            ].add(_share);
        } else {
            _weights[_aggregatorId][_entityIdFrom] = _weights[_aggregatorId][
                _entityIdFrom
            ].sub(_share);
        }

        UD60x18 currentTotalShares = convert(0);
        for (uint256 i = 0; i < _subEntities[_aggregatorId].length(); i++) {
            currentTotalShares = currentTotalShares.add(
                _weights[_aggregatorId][_subEntities[_aggregatorId].at(i)]
            );
        }
        UD60x18 adjastmentFactor = convert(1).div(currentTotalShares);

        for (uint256 i = 0; i < _subEntities[_aggregatorId].length(); i++) {
            UD60x18 newWeight = adjastmentFactor.mul(
                _weights[_aggregatorId][_subEntities[_aggregatorId].at(i)]
            );

            _weights[_aggregatorId][
                _subEntities[_aggregatorId].at(i)
            ] = newWeight;
        }
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
        address _account,
        uint256 _amount
    ) internal {
        IHybridHiveCore.TokenData storage tokenData = _tokensData[_tokenId];
        // DO NOT CHECK IF RECIPIENT IS A MEMBER
        // it should be possible to burn tokens even if holder is removed from the allowed holder list

        _balances[_tokenId][_account] -= _amount;

        tokenData.totalSupply -= _amount;
    }

    // GETTER FUNCTIONS
    // @todo add validation, and notice that it doesn't work for tokens
    function getRootAggregator(
        uint256 _aggregatorId
    ) public view returns (uint256) {
        if (_aggregatorsData[_aggregatorId].parentAggregator == 0)
            return _aggregatorId;
        return
            getRootAggregator(_aggregatorsData[_aggregatorId].parentAggregator);
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

    function getAllowedTokenHolders(
        uint256 _tokenId
    ) public view returns (address[] memory) {
        //@todo add validations if
        return _allowedHolders[_tokenId].values();
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

    function getGlobalAggregatorShare(
        uint256 _networkRootAggregator,
        uint _aggregatorId
    ) public view returns (uint256) {
        uint256 entityId = _aggregatorId;
        uint256 parentAggregatorId = _aggregatorsData[_aggregatorId]
            .parentAggregator;
        UD60x18 globalShare = _weights[parentAggregatorId][entityId];
        while (parentAggregatorId != _networkRootAggregator) {
            entityId = parentAggregatorId;
            parentAggregatorId = _aggregatorsData[entityId].parentAggregator;

            globalShare = globalShare.mul(
                _weights[parentAggregatorId][entityId]
            );
        }

        return convert(globalShare);
    }

    // @todo unfinalized
    function getGlobalTokenShare(
        uint256 _networkRootAggregator,
        uint256 _tokenId,
        uint256 _tokensAmount
    ) public view returns (UD60x18) {
        // @todo add validation
        // @todo add validate if aggregator is root _networkRootAggregator
        UD60x18 globalShare = convert(_tokensAmount).div(
            convert(_tokensData[_tokenId].totalSupply)
        );
        uint256 entityId = _tokenId;
        uint256 parentAggregatorId = _tokensData[_tokenId].parentAggregator;

        while (parentAggregatorId != _networkRootAggregator) {
            globalShare = globalShare.mul(
                _weights[parentAggregatorId][entityId]
            );

            entityId = parentAggregatorId;
            parentAggregatorId = _aggregatorsData[entityId].parentAggregator;
        }

        return globalShare.mul(_weights[_networkRootAggregator][entityId]);
    }

    /**
     *   @dev opposite to getGlobalTokenShare function
     *   calculate amount of tokens (_tokenId) based on global share
     */
    function getTokensAmountFromShare(
        uint256 _networkRootAggregator,
        uint256 _tokenId,
        UD60x18 _globalShare
    ) public view returns (UD60x18) {
        // @todo add validation
        // @todo add validate if aggregator is root _networkRootAggregator
        UD60x18 tokenTotalSupplyShare = getGlobalTokenShare(
            _networkRootAggregator,
            _tokenId,
            _tokensData[_tokenId].totalSupply
        );
        // validate if toke supply exceeds the given _globalShare
        // @todo rewrite it according to the fixed point math
        require(tokenTotalSupplyShare > _globalShare);

        return
            convert(_tokensData[_tokenId].totalSupply).mul(_globalShare).div(
                tokenTotalSupplyShare
            );
    }

    /**
     * Get the amount of tokens in specific branch
     *
     * @param _aggregatorId aggregator Id
     *
     * @return amount of tokens in spesific network branch under the _aggregatorId
     *
     */
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

    /**
     * Get the list of token ids in the branch with the specified root
     *
     * @param _aggregatorId aggregator Id
     *
     * @return array of tokens
     *
     */
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
    ) private view returns (uint256[] memory, uint256) {
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
