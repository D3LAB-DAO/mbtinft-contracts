// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Talk is ERC721URIStorage, Ownable {
    constructor() ERC721("ChingGu-Talk", "TALK") {}
    
    // /**
    //  * TODO:
    //  *
    //  * - Ownable.
    //  */
    // function mint(address to, uint256 tokenId) public /* onlyOwner */ {
    //     _mint(to, tokenId);
    // }

    uint256 tokenIdCounter;
    mapping(address => mapping(uint256 => mapping(uint256 => bytes32))) public keys; // [account][inftId][tokenId]

    function mint(address account, uint256 inftId, bytes32 key) public {
        uint256 tokenId = tokenIdCounter++;

        _mint(account, tokenId);
        keys[account][inftId][tokenId] = key;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     *
     * TODO:
     *
     * - Set baseURI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return "";
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * TODO:
     *
     * - Ownable.
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public virtual {
        _setTokenURI(tokenId, _tokenURI);
    }
}
