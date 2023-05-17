pragma solidity 0.8.19;

import {UD60x18} from "@prb/math/src/UD60x18.sol";

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
        uint256 totalWeight;
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
