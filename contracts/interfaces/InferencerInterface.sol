// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface InferencerInterface {
    function inferenceCall(bytes32 key, address account, uint256 tokenId) external;
}
