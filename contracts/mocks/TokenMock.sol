pragma solidity ^0.8.0;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/extensions/ERC20Burnable.sol";

contract TokenMock is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20Burnable("Gold", "GLD") {
        _mint(msg.sender, initialSupply);
    }

    function mint(uint256 _amount, address _recipient) onlyOwner {
        _mint(_amount, _recipient);
    }

    function burn(uint256 _amount, address _target) onlyOwner {
        _burn(_amount, _target);
    }
}
//@todo add token factory
