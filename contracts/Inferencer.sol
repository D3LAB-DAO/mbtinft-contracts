// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/InferencerInterface.sol";
import "./Talk_ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ITalk {
    function mint(address account, uint256 inftId, bytes32 key) external;
}

contract Inferencer is InferencerInterface, Ownable {
    IERC721 public talk;
    
    /**
     * TODO:
     *
     * - Ownable.
     */
    function inference(bytes32 key, address account, uint256 inftId) public /* onlyOwner */ {
        ITalk(address(talk)).mint(account, inftId, key);
        
        inference(key);
    }
}
