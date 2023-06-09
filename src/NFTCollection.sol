// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ERC721AUpgradeable} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import {ERC2981Upgradeable} from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract NFTCollection is ERC721AUpgradeable, ERC2981Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event BaseURIUpdated(string indexed _newBaseURI);
    event MintPriceUpdated(uint256 indexed _newMintPrice);
    event RoyaltiesUpdated(address _royaltyReceiver, uint256 _royaltyAmount);

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    string public baseURI;
    uint256 public maxSupply;
    uint256 public mintPrice;
    uint256 public startTime;

    /*//////////////////////////////////////////////////////////////
                                LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // Take note of the initializer modifiers.
    // - `initializerERC721A` for `ERC721AUpgradeable`.
    // - `initializer` for OpenZeppelin's `OwnableUpgradeable`.
    function initialize(
        address _owner,
        string calldata _name,
        string calldata _symbol,
        string calldata _baseTokenURI,
        uint256 _maxSupply,
        uint256 _mintPrice,
        uint256 _startTime,
        address _royaltyReceiver,
        uint96 _royaltyAmount
    ) public initializerERC721A initializer {
        __ERC721A_init(_name, _symbol);
        __Ownable_init();
        transferOwnership(_owner);

        baseURI = _baseTokenURI;
        maxSupply = _maxSupply;
        mintPrice = _mintPrice;

        require(_startTime > block.timestamp, "NFT: invalid start time");
        startTime = _startTime;

        _setDefaultRoyalty(_royaltyReceiver, _royaltyAmount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 _quantity) external payable {
        require(block.timestamp >= startTime, "NFT: minting not started");
        require(totalSupply() + _quantity <= maxSupply, "NFT: max supply reached");
        require(msg.value >= mintPrice * _quantity, "NFT: insufficient funds");

        _safeMint(msg.sender, _quantity, "");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return ERC721AUpgradeable.supportsInterface(interfaceId) || ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
        emit BaseURIUpdated(_baseTokenURI);
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
        emit MintPriceUpdated(_mintPrice);
    }

    function setRoyalties(address _royaltyReceiver, uint96 _royaltyAmount) external onlyOwner {
        _setDefaultRoyalty(_royaltyReceiver, _royaltyAmount);
        emit RoyaltiesUpdated(_royaltyReceiver, _royaltyAmount);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
