// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface MbtiNftInterface {
    function upload(address account, uint256 tokenId, uint256 maxLength, uint256 inferencePrice) external;
    function inference() external;
    function inferenceWithPermit() external;
    function permit(address account, uint256 tokenId, uint256 maxLength, uint256 inferencePrice, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function download() external;
}
