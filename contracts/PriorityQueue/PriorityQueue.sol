// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Heap.sol";

/**
 * Implementation for Solidity v0.8.
 *
 * @notice This is a simple contract that uses the heap library.
 *
 * References:
 *
 * - https://github.com/zmitton/eth-heap
 */
contract PriorityQueue {
    using Heap for Heap.Data;
    Heap.Data public data;

    constructor() {
        data.init();
    }

    function heapify(int128[] memory priorities) public {
        for(uint i ; i < priorities.length ; i++){
            data.insert(priorities[i]);
        }
    }
    function insert(int128 priority) public returns(Heap.Node memory) {
        return data.insert(priority);
    }
    function extractMax() public returns(Heap.Node memory) {
        return data.extractMax();
    }
    function extractById(int128 id) public returns(Heap.Node memory) {
        return data.extractById(id);
    }

    /* view */
    function dump() public view returns(Heap.Node[] memory) {
        return data.dump();
    }
    function getMax() public view returns(Heap.Node memory) {
        return data.getMax();
    }
    function getById(int128 id) public view returns(Heap.Node memory) {
        return data.getById(id);
    }
    function getByIndex(uint i) public view returns(Heap.Node memory) {
        return data.getByIndex(i);
    }
    function size() public view returns(uint){
        return data.size();
    }
    function idCount() public view returns(int128){
        return data.idCount;
    }
    function indices(int128 id) public view returns(uint){
        return data.indices[id];
    }
}
