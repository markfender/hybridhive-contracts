pragma solidity ^0.8.9;

contract IHybridHiveCore {
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
        uint256 parentAggregator;
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
        uint256 status; // 0 - doesn't exist @dev for future development
        uint256 tokenFromId;
        uint256 tokenToId;
        address sender;
        address recipient;
        uint256 amount; // absolute value of tokenFromId value
    }
}
