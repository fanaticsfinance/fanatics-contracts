// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./FanCollectibles.sol";

/** @title FanCollectibleMintingStation.
@dev It is a contract that allow different factories to mint
Fanatics Collectibles.
*/

contract FanCollectibleMintingStation is AccessControl {
    FanCollectibles public fanCollectibles;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Modifier for minting roles
    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "Not a minting role");
        _;
    }

    // Modifier for admin roles
    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Not an admin role");
        _;
    }

    constructor(FanCollectibles _fanCollectibles) public {
        fanCollectibles = _fanCollectibles;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Mint NFTs from the FanCollectibles contract.
     */
    function mintCollectible(
        address _tokenReceiver,
        string calldata _tokenURI,
        uint8 _fanCollectibleId
    ) external onlyMinter returns (uint256) {
        uint256 tokenId =
            fanCollectibles.mint(_tokenReceiver, _tokenURI, _fanCollectibleId);
        return tokenId;
    }

    /**
     * @dev Set up names for fan collectables.
     * Only the main admins can set it.
     */
    function setFanCollectibleName(uint8 _fanCollectibleId, string calldata _fanCollectibleName)
        external
        onlyOwner
    {
        fanCollectibles.setFanCollectibleName(_fanCollectibleId, _fanCollectibleName);
    }

    /**
     * @dev It transfers the ownership of the NFT contract
     * to a new address.
     * Only the main admins can set it.
     */
    function changeOwnershipNFTContract(address _newOwner) external onlyOwner {
        fanCollectibles.transferOwnership(_newOwner);
    }

    /**
     * @dev It transfers the ownership of the NFT contract
     * to a new address.
     * Only the main admins can set it.
     */
    function grantMinterRole(address _minter) external onlyOwner {
        grantRole(MINTER_ROLE, _minter);
    }
}