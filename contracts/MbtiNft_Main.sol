// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/MbtiNftInterface.sol";
import "./PriorityQueue/Heap.sol";
import "./CGV_ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @notice
 * 
 * Key functions:
 * - `upload`: User uploads key of task.
 * - `inference`: After user requests `upload`, service provider executes inference and submit the result.
 * - `download`: Check responses.
 *
 * TODO:
 *
 * - Ownable.
 * - Implement EIP1559 methods to priority queue.
 */
contract MbtiNft is MbtiNftInterface, Context, Ownable {
    /* Storage: CGV Token */
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;
    CGV public cgv;

    /* Storage: Priority Queue */
    using Heap for Heap.Data;
    Heap.Data public queue; // request queue
    mapping(int128 => bytes32) keys; // id => key

    /* Storage: Inference */
    // get counter by `nonces[account][tokenId]`.
    mapping(address => mapping(uint256 => uint256)) public nonces;
    mapping(address => uint256) public lockedTokens;

    /* Storage: Permit */
    // keccak256("Permit(address account,uint256 tokenId,uint256 nonce,uint256 deadline)");
    bytes32 private constant PERMIT_TYPEHASH = 0x600ae6fb467d2304044233b22bef66549647e83cdfae60403f90db8d0479cd8d;
    mapping(address => uint256) public permit_nonces;

    /* Events */
    // TBA

    constructor() {
        queue.init(); // priority queue
    }

    /* Functions: Priority Queue */
    function _push(int128 priority, bytes32 key) internal {
        Heap.Node memory n = queue.insert(priority);
        keys[n.id] = key;
    }
    function _pop() internal {
        Heap.Node memory n = queue.extractMax();
        delete keys[n.id];
    }
    function _popById(int128 id) internal {
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
    function permit(address account, uint256 tokenId, uint256 maxLength, uint256 inferencePrice, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
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
        upload(account, tokenId, maxLength, inferencePrice);
    }

    /**
     * @notice Check all priorities to calculate proper `inferencePrice`.
     * <Fastest | Faster | Average | Slower | Slowest>
     */
    function allPriorities() public view returns(int128[] memory) {
        Heap.Node[] memory ns = queue.dump();
        int128[] memory ps = new int128[](ns.length);
        for (uint256 i = 0; i < ns.length; i++) {
            ps[i] = (ns[i].priority);
        }
        return ps;
    }

    /**
     * @notice User must do `approve` before `upload`.
     */
    function upload(address account, uint256 tokenId, uint256 maxLength, uint256 inferencePrice) public {
        /* get key */
        // `key` = kaccak256(address, tokenId, nonce)
        bytes32 key = keccak256(abi.encode(account, tokenId, nonces[account][tokenId]++));

        // /* burn token */
        // IERC20(cgv).burn(maxLength * inferencePrice);
        /* lock token */
        uint256 amount = maxLength * inferencePrice;
        IERC20(cgv).transferFrom(_msgSender(), address(this), amount);
        lockedTokens[_msgSender()] += amount;

        /* push queue */
        _push(inferencePrice.toInt256().toInt128(), key);
    }

    /**
     * @notice User can cancle request.
     *
     * TODO:
     *
     * - Restrict ownership.
     */
    function cancle(address account, uint256 tokenId) public {
        /* get key */
        // `key` = kaccak256(address, tokenId, nonce)
        bytes32 key = keccak256(abi.encode(account, tokenId, nonces[account][tokenId]++));

        // TODO
    }

    /**
     * @notice Test purpose only.
     *
     * TODO:
     *
     * - Remove this function.
     */
    function uploadByKey(bytes32 key) public {
        
    }

    function inference() public {}

    function inferenceWithPermit() public {}

    function download() public {}
}
