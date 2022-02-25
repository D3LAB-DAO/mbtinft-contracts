// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20VotesComp.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract veCGV is ERC20VotesComp, Ownable {
    constructor() ERC20("vote-escrowed CGV", "veCGV") ERC20Permit("vote-escrowed CGV") {}
    
    /**
     * @notice Stake CGV for veCGV.
     *
     * TODO
     */
    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}
