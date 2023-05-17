// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {UD60x18, convert} from "@prb/math/src/UD60x18.sol";

import "./interfaces/IHybridHiveCore.sol";
import "./modules/HybridHiveGeneralGetters.sol";

// Uncomment this line to use console.log
import "hardhat/console.sol";

contract HybridHiveCore is IHybridHiveCore, HybridHiveGeneralGetters {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /*
        @todo
        1. add events and event emiting
        2. create error codes
        3. avoid circles in the tree
        4. switch to the absolute weights representations of the aggregator subentities
        5. use the fixed point lib
        6. recheck all access rights
        7. add tokens decimals
        8. try to make tokens erc20/erc1155 compatible
    */

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
            _weights[newAggregatorId][
                _aggregatedEntities[i]
            ] = _aggregatedEntitiesWeights[i];
            newAggregator.totalWeight += _aggregatedEntitiesWeights[i];
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
            HybridHiveStorage
                ._aggregatorsData[_parentAggregatorId]
                .aggregatedEntityType == _entityType
        );

        if (_entityType == IHybridHiveCore.EntityType.AGGREGATOR) {
            HybridHiveStorage
                ._aggregatorsData[_entityId]
                .parentAggregator = _parentAggregatorId;
        } else if (_entityType == IHybridHiveCore.EntityType.TOKEN) {
            HybridHiveStorage
                ._tokensData[_entityId]
                .parentAggregator = _parentAggregatorId;
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

    // @audit precalculate path on frontend and only do the validation off-chain
    function globalTransfer(
        uint256 _tokenFromId,
        uint256 _tokenToId,
        address _sender,
        address _recipient,
        uint256 _amount
    ) public {
        // @todo add validation
        // @todo validate if it is same as root of `_tokenToId`
        require(_sender == msg.sender);
        uint256 rootAggregator = getRootAggregator(
            _tokensData[_tokenFromId].parentAggregator
        );
        UD60x18 transferGlobalShare = getGlobalValueShare(
            rootAggregator,
            IHybridHiveCore.EntityType.TOKEN,
            _tokenFromId,
            _amount
        );
        // @todo ITERATE UP FROM `_tokenFromId` and probably up from `_tokenToId`

        //@todo validation should match pathFrom[0] == pathTo[0], and should match root

        // @todo optimize it
        uint256 entityId = _tokenFromId;
        uint256 parentEntity = _tokensData[entityId].parentAggregator;
        uint256 parentTotalSupplay = _tokensData[entityId].totalSupply;
        _burnToken(_tokenFromId, _sender, _amount);
        UD60x18 operationalShare = convert(_amount).div(
            convert(parentTotalSupplay)
        );
        uint256 operationalValue;
        while (parentEntity != 0) {
            operationalValue = convert(
                convert(_weights[parentEntity][entityId]).mul(operationalShare)
            );

            _weights[parentEntity][entityId] -= operationalValue;
            _aggregatorsData[parentEntity].totalWeight -= operationalValue;

            entityId = parentEntity;
            parentEntity = _aggregatorsData[entityId].parentAggregator;
            parentTotalSupplay = _aggregatorsData[parentEntity].totalWeight;
            if (parentEntity != 0)
                operationalShare = convert(operationalValue).div(
                    convert(parentTotalSupplay)
                );
        }

        // generate path down
        uint256 pathDownLength = 0;
        entityId = _tokenToId;
        parentEntity = _tokensData[_tokenToId].parentAggregator;
        while (parentEntity != 0) {
            pathDownLength++;
            entityId = parentEntity;
            parentEntity = _aggregatorsData[parentEntity].parentAggregator;
        }
        uint256[] memory pathDown = new uint256[](pathDownLength + 1);

        parentEntity = _tokensData[_tokenToId].parentAggregator;
        for (uint256 i = 1; parentEntity != 0; i++) {
            pathDown[pathDownLength - i] = parentEntity;
            parentEntity = _aggregatorsData[parentEntity].parentAggregator;
        }
        pathDown[3] = _tokenToId;

        for (uint256 i = 0; i < pathDown.length - 1; i++) {
            entityId = pathDown[i + 1];
            parentEntity = pathDown[i];
            if (i == pathDown.length - 2) {
                parentTotalSupplay = _tokensData[entityId].totalSupply;
            } else {
                parentTotalSupplay = _aggregatorsData[entityId].totalWeight;
            }

            operationalShare = convert(parentTotalSupplay).div(
                convert(_weights[parentEntity][entityId])
            );

            _weights[parentEntity][entityId] += operationalValue;
            _aggregatorsData[parentEntity].totalWeight += operationalValue;

            operationalValue = convert(
                operationalShare.mul(convert(operationalValue))
            );
        }

        _mintToken(_tokenToId, _recipient, operationalValue);
    }

    function getTotalSupply(
        IHybridHiveCore.EntityType _entityType,
        uint256 _entityId
    ) public view returns (uint256) {
        if (_entityType == IHybridHiveCore.EntityType.TOKEN) {
            return _tokensData[_entityId].totalSupply;
        } else if (_entityType == IHybridHiveCore.EntityType.AGGREGATOR) {
            return _aggregatorsData[_entityId].totalWeight;
        }
    }

    // INTERNAL FUNCTIONS

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
        require(_aggregatorIds.contains(_aggregatorId), "E001");
        if (_aggregatorsData[_aggregatorId].parentAggregator == 0)
            return _aggregatorId;
        return
            getRootAggregator(_aggregatorsData[_aggregatorId].parentAggregator);
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

    function getGlobalAggregatorShare(
        uint256 _networkRootAggregator,
        uint _aggregatorId
    ) public view returns (UD60x18) {
        uint256 entityId = _aggregatorId;
        uint256 parentAggregatorId = _aggregatorsData[_aggregatorId]
            .parentAggregator;
        UD60x18 globalShare = getRelativeWeight(parentAggregatorId, entityId);
        while (parentAggregatorId != _networkRootAggregator) {
            entityId = parentAggregatorId;
            parentAggregatorId = _aggregatorsData[entityId].parentAggregator;

            globalShare = globalShare.mul(
                getRelativeWeight(parentAggregatorId, entityId)
            );
        }

        return globalShare;
    }

    function getRelativeWeight(
        uint256 _parentAggregatorId,
        uint256 _entityId
    ) public view returns (UD60x18) {
        // @todo add validation
        // check if _parentAggregatorId has _entityId child
        uint256 parentTotalSupply = _aggregatorsData[_parentAggregatorId]
            .totalWeight;
        uint256 childAbsoluteShareValue = _weights[_parentAggregatorId][
            _entityId
        ];

        return convert(childAbsoluteShareValue).div(convert(parentTotalSupply));
    }

    //75 66
    // @todo unfinalized
    function getGlobalValueShare(
        uint256 _networkRootAggregator,
        IHybridHiveCore.EntityType _entityType,
        uint256 _entityId,
        uint256 _absoluteAmount
    ) public view returns (UD60x18) {
        // @todo add validation
        // @todo add validate if aggregator is root _networkRootAggregator
        uint256 totalAmount;
        uint256 entityId = _entityId;
        uint256 parentAggregatorId;
        if (_entityType == IHybridHiveCore.EntityType.TOKEN) {
            totalAmount = _tokensData[entityId].totalSupply;
            parentAggregatorId = _tokensData[entityId].parentAggregator;
        } else if (_entityType == IHybridHiveCore.EntityType.AGGREGATOR) {
            totalAmount = _aggregatorsData[entityId].totalWeight;
            parentAggregatorId = _aggregatorsData[entityId].parentAggregator;
        }

        UD60x18 globalShare = convert(_absoluteAmount).div(
            convert(totalAmount)
        );

        while (parentAggregatorId != _networkRootAggregator) {
            globalShare = globalShare.mul(
                getRelativeWeight(parentAggregatorId, entityId)
            );

            entityId = parentAggregatorId;
            parentAggregatorId = _aggregatorsData[entityId].parentAggregator;
        }

        return
            globalShare.mul(
                getRelativeWeight(_networkRootAggregator, entityId)
            );
    }

    /**
     *   @dev opposite to getGlobalValueShare function
     *   calculate amount of tokens (_tokenId) based on global share
     */
    function getAbsoluteAmountFromShare(
        uint256 _networkRootAggregator,
        IHybridHiveCore.EntityType _entityType,
        uint256 _entityId,
        UD60x18 _globalShare
    ) public view returns (uint256) {
        // @todo add validation
        // @todo add validate if aggregator is root _networkRootAggregator
        uint256 totalAmount;
        if (_entityType == IHybridHiveCore.EntityType.TOKEN) {
            totalAmount = _tokensData[_tokensData[_entityId].parentAggregator]
                .totalSupply;
        } else if (_entityType == IHybridHiveCore.EntityType.AGGREGATOR) {
            totalAmount = _aggregatorsData[
                _aggregatorsData[_entityId].parentAggregator
            ].totalWeight;
        }

        UD60x18 totalSupplyShare = getGlobalValueShare(
            _networkRootAggregator,
            _entityType,
            _entityId,
            totalAmount
        );

        // validate if toke supply exceeds the given _globalShare
        // @todo rewrite it according to the fixed point math
        // recheck if there is a need in requirement statement
        //require(totalSupplyShare > _globalShare);

        return
            convert(
                convert(totalAmount).mul(_globalShare).div(totalSupplyShare)
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
