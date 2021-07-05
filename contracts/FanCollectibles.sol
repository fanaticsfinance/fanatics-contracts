// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract FanCollectibles is ERC721, Ownable {
    using Counters for Counters.Counter;

    // Map the number of tokens per fanCollectibleId
    mapping(uint8 => uint256) public fanCollectibleCount;

    // Map the number of tokens burnt per fanCollectibleId
    mapping(uint8 => uint256) public fanCollectibleBurnCount;

    // Used for generating the tokenId of new NFT minted
    Counters.Counter private _tokenIds;

    // Map the fanCollectibleId for each tokenId
    mapping(uint256 => uint8) private fanCollectibleIds;

    // Map the fanCollectibleName for a tokenId
    mapping(uint8 => string) private fanCollectibleNames;

    constructor(string memory _baseURI) public ERC721("Fanatics Collectibles", "FCB") {
        _setBaseURI(_baseURI);
    }

    /**
     * @dev Get fanCollectibleId for a specific tokenId.
     */
    function getFanCollectibleId(uint256 _tokenId) external view returns (uint8) {
        return fanCollectibleIds[_tokenId];
    }

    /**
     * @dev Get the associated fanCollectibleName for a specific fanCollectibleId.
     */
    function getFanCollectibleName(uint8 _fanCollectibleId)
        external
        view
        returns (string memory)
    {
        return fanCollectibleNames[_fanCollectibleId];
    }

    /**
     * @dev Get the associated fanCollectibleName for a unique tokenId.
     */
    function getFanCollectibleNameOfTokenId(uint256 _tokenId)
        external
        view
        returns (string memory)
    {
        uint8 fanCollectibleId = fanCollectibleIds[_tokenId];
        return fanCollectibleNames[fanCollectibleId];
    }

    /**
     * @dev Mint NFTs. Only the owner can call it.
     */
    function mint(
        address _to,
        string calldata _tokenURI,
        uint8 _fanCollectibleId
    ) external onlyOwner returns (uint256) {
        uint256 newId = _tokenIds.current();
        _tokenIds.increment();
        fanCollectibleIds[newId] = _fanCollectibleId;
        fanCollectibleCount[_fanCollectibleId] = fanCollectibleCount[_fanCollectibleId].add(1);
        _mint(_to, newId);
        _setTokenURI(newId, _tokenURI);
        return newId;
    }

    /**
     * @dev Set a unique name for each fanCollectibleId. It is supposed to be called once.
     */
    function setFanCollectibleName(uint8 _fanCollectibleId, string calldata _name)
        external
        onlyOwner
    {
        fanCollectibleNames[_fanCollectibleId] = _name;
    }

    /**
     * @dev Burn a NFT token. Callable by owner only.
     */
    function burn(uint256 _tokenId) external onlyOwner {
        uint8 fanCollectibleIdBurnt = fanCollectibleIds[_tokenId];
        fanCollectibleCount[fanCollectibleIdBurnt] = fanCollectibleCount[fanCollectibleIdBurnt].sub(1);
        fanCollectibleBurnCount[fanCollectibleIdBurnt] = fanCollectibleBurnCount[fanCollectibleIdBurnt].add(1);
        _burn(_tokenId);
    }
}