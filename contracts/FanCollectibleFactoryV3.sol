// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./libs/IBEP20.sol";
import "./libs/SafeBEP20.sol";
import "./FanCollectibles.sol";
import "./FanCollectibleMintingStation.sol";

contract FanCollectibleFactoryV3 is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    FanCollectibleMintingStation public fanCollectibleMintingStation;

    IBEP20 public goalToken;

    // starting block
    uint256 public startBlockNumber;

    // Number of GOALs a user needs to pay to acquire a token
    uint256 public tokenPrice;

    // Map if address has already claimed a NFT
    mapping(address => bool) public hasClaimed;

    // IPFS hash for new json
    string private ipfsHash;

    // Map the token number to URI
    mapping(uint8 => string) private fanCollectibleIdURIs;

    // Event to notify when NFT is successfully minted
    event FanCollectibleMint(
        address indexed to,
        uint256 indexed tokenId,
        uint8 indexed fanCollectibleId
    );

    constructor(
        FanCollectibleMintingStation _fanCollectibleMintingStation,
        IBEP20 _goalToken,
        uint256 _tokenPrice,
        string memory _ipfsHash,
        uint256 _startBlockNumber
    ) public {
        fanCollectibleMintingStation = _fanCollectibleMintingStation;
        goalToken = _goalToken;
        tokenPrice = _tokenPrice;
        ipfsHash = _ipfsHash;
        startBlockNumber = _startBlockNumber;
    }

    /**
     * @dev Mint NFTs from the FanCollectibleMintingStation contract.
     * Users can specify what fanCollectibleId they want to mint. Users can claim once.
     */
    function mintNFT(uint8 _fanCollectibleId) external {
        address senderAddress = _msgSender();

        // Check _msgSender() has not claimed
        require(!hasClaimed[senderAddress], "Has claimed");
        // Check block time is not too late
        require(block.number > startBlockNumber, "too early");

        string memory tokenURI = fanCollectibleIdURIs[_fanCollectibleId];
        bytes memory check = bytes(tokenURI);
        // Check that the _fanCollectibleId is within boundary:
        require(check.length > 0, "fanCollectibleId doesnt exist");

        // Update that _msgSender() has claimed
        hasClaimed[senderAddress] = true;

        // Send GOAL tokens to this contract
        goalToken.safeTransferFrom(senderAddress, address(this), tokenPrice);

        uint256 tokenId =
            fanCollectibleMintingStation.mintCollectible(
                senderAddress,
                tokenURI,
                _fanCollectibleId
            );

        emit FanCollectibleMint(senderAddress, tokenId, _fanCollectibleId);
    }

    /**
     * @dev It transfers the GOAL tokens back to the chef address.
     * Only callable by the owner.
     */
    function claimFee(uint256 _amount) external onlyOwner {
        goalToken.safeTransfer(_msgSender(), _amount);
    }

    /**
     * @dev Set up json extensions for fancollectibles 5-9
     * Assign tokenURI to look for each fanCollectibleId in the mint function
     * Only the owner can set it.
     */
    function setFanCollectibleJson(
        string calldata _fanCollectibleId5Json,
        string calldata _fanCollectibleId6Json,
        string calldata _fanCollectibleId7Json,
        string calldata _fanCollectibleId8Json,
        string calldata _fanCollectibleId9Json
    ) external onlyOwner {
        fanCollectibleIdURIs[5] = string(abi.encodePacked(ipfsHash, _fanCollectibleId5Json));
        fanCollectibleIdURIs[6] = string(abi.encodePacked(ipfsHash, _fanCollectibleId6Json));
        fanCollectibleIdURIs[7] = string(abi.encodePacked(ipfsHash, _fanCollectibleId7Json));
        fanCollectibleIdURIs[8] = string(abi.encodePacked(ipfsHash, _fanCollectibleId8Json));
        fanCollectibleIdURIs[9] = string(abi.encodePacked(ipfsHash, _fanCollectibleId9Json));
    }

    /**
     * @dev Set up json extensions for fancollectibles
     * Assign tokenURI to look for each fanCollectibleId in the mint function
     * Only the owner can set it.
     */
    function setFanCollectibleJson(uint8 _fanCollectibleId,
        string calldata _fanCollectibleIdJson ) external onlyOwner {
        fanCollectibleIdURIs[_fanCollectibleId] = string(abi.encodePacked(ipfsHash, _fanCollectibleIdJson));
    }

    /**
     * @dev Allow to set up the start number
     * Only the owner can set it.
     */
    function setStartBlockNumber(uint256 _newStartBlockNumber)
        external
        onlyOwner
    {
        require(_newStartBlockNumber > block.number, "too short");
        startBlockNumber = _newStartBlockNumber;
    }

    /**
     * @dev Allow to change the token price
     * Only the owner can set it.
     */
    function updateTokenPrice(uint256 _newTokenPrice) external onlyOwner {
        tokenPrice = _newTokenPrice;
    }

    function canMint(address userAddress) external view returns (bool) {
        return !hasClaimed[userAddress];
    }
}