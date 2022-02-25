// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ChingGu is ERC721URIStorage, Ownable {
    /* Events */
    event Rare(uint256 tokenId, uint256 degree);

    mapping (address => uint256[]) internal _collectables;
    uint256 tokenIdCounter;

    /* Storage: Properties */
    struct MBTI {
        uint64 energy; // E <=> I, save 'E'
        uint64 information; // S <=> N, save 'S'
        uint64 decision; // T <=> F, save 'T'
        uint64 relate; // J <=> P, save 'J'
    }
    struct Properties {
        uint256 amount; // of training data
        uint256 love;
        uint256 rarity;
        uint256 popularity;
        MBTI mbti;
        uint256 sp; // skill point
    }
    // key: [account][tokenId]
    mapping(address => mapping(uint256 => Properties)) internal _properties;

    uint64 private constant SP_PER_RARITY = 5;

    constructor() ERC721("ChingGu-Profile", "CGP") {}

    /* Functions: Metadata */

    function mint(uint256 job) public {
        uint256 tokenId = tokenIdCounter++;
        address sender = _msgSender();

        _mint(sender, tokenId);
        _collectables[sender].push(tokenId);

        Properties storage p = _properties[sender][tokenId];

        // Rarity
        uint64 rarity = _rarity(_random());
        p.rarity = rarity; 
        emit Rare(tokenId, rarity);

        if (job == 16) { // Neutral
            p.sp = rarity * SP_PER_RARITY * 4;
        }
        else {
            bool[4] memory b = _binary(job);
            if (b[0]) { p.mbti.energy = 100 - rarity * SP_PER_RARITY; }
            else { p.mbti.energy = rarity * SP_PER_RARITY; }
            if (b[1]) { p.mbti.information = 100 - rarity * SP_PER_RARITY; }
            else { p.mbti.information = rarity * SP_PER_RARITY; }
            if (b[2]) { p.mbti.decision = 100 - rarity * SP_PER_RARITY; }
            else { p.mbti.decision = rarity * SP_PER_RARITY; }
            if (b[3]) { p.mbti.relate = 100 - rarity * SP_PER_RARITY; }
            else { p.mbti.relate = rarity * SP_PER_RARITY; }
        }
    }

    /**
     * TODO: Real random.
     */
    uint256 internal _seed;
    function _random() internal returns(uint256) {
        _seed = uint256(keccak256(abi.encode(_seed)) | bytes32(block.timestamp));
        return _seed;
    }

    // mbti
    /*
        0:  0, 0, 0, 0: ISFP
        1:  1, 0, 0, 0: ESFP
        2:  0, 1, 0, 0: INFP
        3:  1, 1, 0, 0: ENFP
        4:  0, 0, 1, 0: ISTP
        5:  1, 0, 1, 0: ESTP
        6:  0, 1, 1, 0: INTP
        7:  1, 1, 1, 0: ENTP
        8:  0, 0, 0, 1: ISFJ
        9:  1, 0, 0, 1: ESFJ
        10: 0, 1, 0, 1: INFJ
        11: 1, 1, 0, 1: ENFJ
        12: 0, 0, 1, 1: ISTJ
        13: 1, 0, 1, 1: ESTJ
        14: 0, 1, 1, 1: INTJ
        15: 1, 1, 1, 1: ENTJ
    */
    function _binary(uint256 x) internal pure returns(bool[4] memory y) {
        require(x < 16, "ChingGu: EXCEED_BOUNDARY.");
        require(x >= 0, "ChingGu: EXCEED_BOUNDARY.");

        uint8 index;
        while(x > 0) {
            y[index++] = x % 2 == 1 ? true : false;
            unchecked { x /= 2; }
        }
    }
    function _rarity(uint256 r) internal pure returns(uint64 y) {
        // for test purpose
        if (r % 100 < 20) { return 5; }
        else if(r % 100 < 40) { return 4; }
        else if(r % 100 < 60) { return 3; }
        else if(r % 100 < 80) { return 2; }
        else { return 1; }

        // if (r % 100 < 1) { return 5; } // legendary (1%)
        // else if(r % 100 < 7) { return 4; } // unique (6%)
        // else if(r % 100 < 25) { return 3; } // epic (18%)
        // else if(r % 100 < 50) { return 2; } // rare (25%)
        // else { return 1; } // normal (50%)
    }

    /* View & Pure Functions */
    function collectables(address account) public view returns(uint256[] memory) {
        return _collectables[account];
    }
    function getMBTI(
        uint64 energy, // E <=> I, save 'E'
        uint64 information, // S <=> N, save 'S'
        uint64 decision, // T <=> F, save 'T'
        uint64 relate // J <=> P, save 'J'
    ) public pure returns(string memory) {
        bytes[4] memory mbti;
        if (energy > 50) { mbti[0] = 'I'; }
        else { mbti[0] = 'E'; }
        if (information > 50) { mbti[1] = 'N'; }
        else { mbti[1] = 'S'; }
        if (decision > 50) { mbti[2] = 'F'; }
        else { mbti[2] = 'T'; }
        if (relate > 50) { mbti[3] = 'P'; }
        else { mbti[3] = 'J'; }
        return string(abi.encodePacked(mbti[0], mbti[1], mbti[2], mbti[3]));
    }
    function getMBTI(uint256 job) public pure returns(string memory) {
        bytes[4] memory mbti;
        bool[4] memory b = _binary(job);
        if (b[0]) { mbti[0] = 'I'; }
        else { mbti[0] = 'E'; }
        if (b[1]) { mbti[1] = 'N'; }
        else { mbti[1] = 'S'; }
        if (b[2]) { mbti[2] = 'F'; }
        else { mbti[2] = 'T'; }
        if (b[3]) { mbti[3] = 'P'; }
        else { mbti[3] = 'J'; }
        return string(abi.encodePacked(mbti[0], mbti[1], mbti[2], mbti[3]));
    }

    // /**
    //  * TODO:
    //  *
    //  * - Ownable.
    //  */
    // function mint(address to, uint256 tokenId) public /* onlyOwner */ {
    //     _mint(to, tokenId);
    // }

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

    /* Functions: Properties */

    function properties(
        address account, uint256 tokenId
    ) public view returns(
        uint256 amount,
        uint256 love, uint256 rarity, uint256 popularity,
        uint64 energy, uint64 information, uint64 decision, uint64 relate,
        uint256 sp
    ) {
        Properties memory p = _properties[account][tokenId];

        amount = p.amount;
        love = p.love;
        rarity = p.rarity;
        popularity = p.popularity;
        energy = p.mbti.energy;
        information = p.mbti.information;
        decision = p.mbti.decision;
        relate = p.mbti.relate;
        sp = p.sp;
    }

    /**
     * TODO: internal.
     */
    function _setProperties(
        address account, uint256 tokenId,
        uint256 amount,
        uint256 love, uint256 rarity, uint256 popularity,
        uint64 energy, uint64 information, uint64 decision, uint64 relate,
        uint256 sp
    ) public {
        _properties[account][tokenId] = Properties({
            amount: amount,
            love: love, rarity: rarity, popularity: popularity,
            mbti: MBTI({energy: energy, information: information, decision: decision, relate: relate}),
            sp: sp
        });
    }
}
