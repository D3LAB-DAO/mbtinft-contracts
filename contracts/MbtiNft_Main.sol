// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/MbtiNftInterface.sol";
import "./PriorityQueue/Heap.sol";
import "./CGV_ERC20.sol";
import "./ChingGu_ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

interface IERC20Burnable {
    function burn(uint256 amount) external;
}

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
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    /* Storage: Tokens */
    CGV public cgv;
    ChingGu public chinggu;

    /* Storage: Priority Queue */
    using Heap for Heap.Data;
    Heap.Data public queue; // request queue
    mapping(int128 => bytes32) public keys; // request (id => key)
    mapping(int128 => address) public accounts; // request (id => account)
    mapping(bytes32 => bool) public pending; // whether key is in the queue or not.

    /* Storage: Inference */
    // get counter (nonce) by `nonces[account][tokenId]`.
    mapping(address => mapping(uint256 => uint256)) public nonces;
    // get amount of locked token by `lockedTokens[key]`.
    mapping(bytes32 => uint256) public lockedTokens;

    // keccak256("Permit(bytes32 key,uint256 permit_nonce,uint256 deadline)");
    bytes32 private constant PERMIT_TYPEHASH = 0xb4739a75ec8852fc3f62bdfd066ffa398d94859237fb48c553b1be7600552493;
    mapping(address => uint256) public permit_nonces;

    /* Events */
    // TBA

    constructor(address cgv_, address chinggu_) {
        cgv = CGV(cgv_);
        chinggu = ChingGu(chinggu_);
        queue.init(); // priority queue
    }

    /* Functions: Priority Queue */
    function _push(int128 priority, bytes32 key, address account) internal returns(int128) {
        Heap.Node memory n = queue.insert(priority);
        keys[n.id] = key;
        accounts[n.id] = account;
        return n.id;
    }
    function _pop() internal returns(int128, int128, bytes32, address) {
        Heap.Node memory n = queue.extractMax();
        bytes32 key = keys[n.id];
        address account = accounts[n.id];
        delete keys[n.id];
        delete accounts[n.id];
        return (n.id, n.priority, key, account);
    }
    function _popById(int128 id) internal returns(int128, int128, bytes32, address) {
        Heap.Node memory n = queue.extractById(id);
        bytes32 key = keys[id];
        address account = accounts[id];
        delete keys[id];
        delete accounts[id];
        return (n.id, n.priority, key, account);
    }
    // function getMax() public view returns(int128, int128) {
    //     Heap.Node memory n = queue.getMax();
    //     return (n.id, n.priority);
    // }
    // function getById(int128 id) public view returns(int128, int128) {
    //     Heap.Node memory n = queue.getById(id);
    //     return (n.id, n.priority);
    // }
    // function getByIndex(uint i) public view returns(int128, int128) { // same as getByRank
    //     Heap.Node memory n =  queue.getByIndex(i);
    //     return (n.id, n.priority);
    // }
    // function size() public view returns(uint){
    //     return queue.size();
    // }
    // function idCount() public view returns(int128){
    //     return queue.idCount;
    // }
    // function indices(int128 id) public view returns(uint){ // same as ranks
    //     return queue.indices[id];
    // }

    /**
     * @notice Check all priorities to calculate proper `inferencePrice`.
     *
     * Speed:
     *
     * - Fastest: max + 1
     * - Faster
     * - Average
     * - Slower
     * - Slowest: min - 1
     */
    function allPriorities() public view returns(int128[] memory ps, int128 maxP, int128 minP) {
        Heap.Node[] memory ns = queue.dump();
        ps = new int128[](ns.length - 1);
        if (ns.length > 1) {
            maxP = ns[1].priority;
            minP = ns[1].priority;
        }
        for (uint256 i = 1; i < ns.length; i++) {
            int128 p = ns[i].priority;
            ps[i - 1] = p;
            if (maxP < p) {maxP = p;}
            else if (minP > p) {minP = p;}
        }
    }

    /* Functions: Inference */

	/**
     * @notice User can skip `upload()` with `permit()`.
     * Instead, service provider calls `inferenceWithPermit()` only.
     *
     * References:
     *
     * - https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2ERC20.sol
     */
    function permit(
        address account, uint256 tokenId, uint256 nonce,
        uint256 maxLength, uint256 inferencePrice,
        uint256 deadline,
        uint8 v, bytes32 r, bytes32 s
    ) external returns(int128 id) {
        require(deadline >= block.timestamp, 'MBTINFT: EXPIRED');

        /* get key */
        // `key` = kaccak256(address, tokenId, nonce)
        bytes32 key = keccak256(abi.encode(account, tokenId, nonce));

        /* get digest */
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19Ethereum Signed Message:\n32',
                keccak256(abi.encode(
                    PERMIT_TYPEHASH,
                    key,
                    permit_nonces[account]++,
                    deadline
                ))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == account, 'MBTINFT: INVALID_SIGNATURE');
        
        /* Logic what you want */
        id = _upload(key, account, maxLength, inferencePrice);
    }

    /**
     * @notice Do not use `upload` with non-exist key.
     * If so, you can miss (freeze) tokens.
     */
    function upload(
        bytes32 key,
        uint256 maxLength, uint256 inferencePrice
    ) public returns(int128 id) {
        id = _upload(key, _msgSender(), maxLength, inferencePrice);
    }

    /**
     * @notice User must do `approve` before `upload`.
     */
    function upload(
        address account, uint256 tokenId,
        uint256 maxLength, uint256 inferencePrice
    ) public returns(int128 id) {
        /* conditions */
        require(chinggu.ownerOf(tokenId) == account, 'MBTINFT: INVALID_OWNERSHIP');

        /* get key */
        // `key` = kaccak256(address, tokenId, nonce)
        uint256 nonce = nonces[account][tokenId]++;
        bytes32 key = keccak256(abi.encode(account, tokenId, nonce));

        /* upload */
        id = _upload(key, account, maxLength, inferencePrice);
    }

    function _upload(
        bytes32 key,
        address account,
        uint256 maxLength, uint256 inferencePrice
    ) internal returns(int128 id) {
        /* condition */
        require(!pending[key], 'MBTINFT: INVALID_KEY');

        /* lock token */
        uint256 amount = maxLength * inferencePrice;
        IERC20(cgv).transferFrom(account, address(this), amount);
        lockedTokens[key] += amount;

        /* push queue */
        id = _push(inferencePrice.toInt256().toInt128(), key, account);
        pending[key] = true;
    }

    /**
     * @notice User can cancle there own request(s).
     */
    function cancle(int128 id) public {
        /* condition */
        address account = accounts[id];
        require(_msgSender() == account, 'MBTINFT: INVALID_SENDER');

        /* get key */
        bytes32 key = keys[id];
        require(pending[key], 'MBTINFT: INVALID_KEY');

        /* unlock token */
        uint256 amount = lockedTokens[key];
        if (amount > 0) {
            lockedTokens[key] = 0;
            IERC20(cgv).transfer(account, amount);
        }

        /* remove element from queue */
        _popById(id);
        pending[key] = false;
    }

    /**
     * @notice Server replies at the highest priority request.
     */
    function inference() public onlyOwner {
        bytes32 key;
        (, , key, ) = _pop(); // remove element from queue.
        require(pending[key], 'MBTINFT: INVALID_KEY'); // check condition.
        pending[key] = false;

        _inference(key);
    }

    /**
     * TODO:
     *
     * - Optimization: queue activities, pending array.
     */
    function inferenceWithPermit(
        address account, uint256 tokenId, uint256 nonce,
        uint256 maxLength, uint256 inferencePrice,
        uint256 deadline,
        uint8 v, bytes32 r, bytes32 s
    ) public onlyOwner {
        /* upload */
        int128 id = this.permit(account, tokenId, nonce, maxLength, inferencePrice, deadline, v, r, s);
        
        int128 maxId;
        bytes32 key;
        (maxId, , key, ) = _pop(); // remove element from queue.

        /* condition */
        require(maxId == id, 'MBTINFT: INVALID_PRIORITY');
        require(pending[key], 'MBTINFT: INVALID_KEY'); // check condition.
        pending[key] = false;

        /* inference */
        _inference(key);
    }

    function _inference(bytes32 key) internal {
        /* burn token */
        uint256 amount = lockedTokens[key];
        lockedTokens[key] = 0;
        IERC20Burnable(address(cgv)).burn(amount);

        /* inferencer */
        // TODO
    }

    // function download() public {};
}
