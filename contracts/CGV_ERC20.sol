// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CGV is ERC20Capped, ERC20Burnable, Ownable {
    constructor()
        ERC20Capped(1000000000 * 10e18)
        ERC20("Ching-Gu-Vi", "CGV")
    {}
    
    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override(ERC20Capped, ERC20) {
        ERC20Capped._mint(account, amount);
    }

    /**
     * TODO:
     *
     * - Ownable.
     */
    function mint(address account, uint256 amount) public /* onlyOwner */ {
        _mint(account, amount);
    }
}
