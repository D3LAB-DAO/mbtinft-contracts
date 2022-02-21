// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/MbtiNftInterface.sol";
import "./PriorityQueue/Heap.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice
 * 
 * Key functions:
 * - `upload`: User uploads key of task.
 * - `inference`: After user requests `upload`, service provider executes inference and submit the result.
 * - `download`: checks 
 *
 * TODO:
 *
 * - Ownable.
 */
contract MbtiNft is MbtiNftInterface, Ownable {
    /* Storage: Priority Queue */
    using Heap for Heap.Data;
    Heap.Data public queue; // request queue
    mapping(int128 => bytes32) keys; // id => key

    /* Storage: Permit */
    // keccak256("Permit(address account,uint256 tokenId,uint256 nonce,uint256 deadline)");
    bytes32 private constant PERMIT_TYPEHASH = 0x600ae6fb467d2304044233b22bef66549647e83cdfae60403f90db8d0479cd8d;
    mapping(address => uint256) public permit_nonces;

    /* Storage: Inference */
    // get counter by `nonces[account][tokenId]`.
    mapping(address => mapping(uint256 => uint256)) public nonces;

    /* Events */
    // TBA

    constructor() {
        queue.init(); // priority queue
    }

    /* Functions: Priority Queue */
    function push(int128 priority, bytes32 key) public {
        Heap.Node memory n = queue.insert(priority);
        keys[n.id] = key;
    }
    function pop() public onlyOwner {
        Heap.Node memory n = queue.extractMax();
        delete keys[n.id];
    }
    function popById(int128 id) public onlyOwner {
        Heap.Node memory n = queue.extractById(id);
        delete keys[n.id];
    }
    function getMax() public view returns(int128, int128, bytes32) {
        Heap.Node memory n = queue.getMax();
        return (n.id, n.priority, keys[n.id]);
    }
    function getById(int128 id) public view returns(int128, int128, bytes32) {
        Heap.Node memory n = queue.getById(id);
        return (n.id, n.priority, keys[n.id]);
    }
    function getByIndex(uint i) public view returns(int128, int128, bytes32) { // same as getByRank
        Heap.Node memory n =  queue.getByIndex(i);
        return (n.id, n.priority, keys[n.id]);
    }
    function size() public view returns(uint){
        return queue.size();
    }
    function idCount() public view returns(int128){
        return queue.idCount;
    }
    function indices(int128 id) public view returns(uint){ // same as ranks
        return queue.indices[id];
    }

	/**
     * @notice User can skip `upload()` with `permit()`.
     * Instead, service provider calls `inferenceWithPermit()` only.
     *
     * References:
     *
     * - https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2ERC20.sol
     */
    function permit(address account, uint256 tokenId, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'MBTINFT: EXPIRED');

        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19Ethereum Signed Message:\n32',
                keccak256(abi.encode(PERMIT_TYPEHASH, account, tokenId, permit_nonces[account]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == account, 'MBTINFT: INVALID_SIGNATURE');
        
        /* Logic what you want */
        upload(account, tokenId);
    }

    function upload(address account, uint256 tokenId) public {
        // `key` = kaccak256(address, tokenId, nonce)
        bytes32 key = keccak256(abi.encode(account, tokenId, nonces[account][tokenId]++));
    }

    function inference() public {}

    function inferenceWithPermit() public {}

    function download() public {}
}
