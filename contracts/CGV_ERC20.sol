// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20VotesComp.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CGV is ERC20VotesComp, Ownable {
    constructor() ERC20("Ching-Gu-Vi", "CGV") ERC20Permit("Ching-Gu-Vi") {}
    
    /**
     * TODO: mint process
     */
    function mint(address account, uint256 amount) public /* onlyOwner */ {
        _mint(account, amount);
    }
}
