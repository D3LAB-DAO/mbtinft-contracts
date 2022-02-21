// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface MbtiNftInterface {
    function permit(address account, uint256 tokenId, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function upload(address account, uint256 tokenId) external;
    function inference() external;
    function inferenceWithPermit() external;
    function download() external;
}
