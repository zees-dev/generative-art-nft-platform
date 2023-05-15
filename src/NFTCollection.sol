// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ERC721AUpgradeable} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";
import {IERC2981Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

contract NFTCollection is ERC721AUpgradeable, IERC2981Upgradeable, UUPSUpgradeable, OwnableUpgradeable, ERC165Upgradeable {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event RoyaltyPaid(address indexed _receiver, uint256 _amount);
    event BaseURIUpdated(string indexed _newBaseURI);
    event MintPriceUpdated(uint256 indexed _newMintPrice);
    event RoyaltiesUpdated(address payable[] indexed _newReceivers, uint256[] indexed _newBPS);
    event Withdrawn(address indexed _receiver, uint256 _amount);

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct Royalties {
        address payable[] receivers;
        mapping(address => uint256) receiverToBPS;
    }

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    string public baseURI;
    uint256 public maxSupply;
    uint256 public mintPrice;
    uint256 public startTime;
    Royalties royalties;

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
        address[] calldata _royaltyReceivers,
        uint256[] memory _royaltyBPS
    ) public initializerERC721A initializer {
        __ERC721A_init(_name, _symbol);
        __Ownable_init();
        transferOwnership(_owner);

        baseURI = _baseTokenURI;
        maxSupply = _maxSupply;
        mintPrice = _mintPrice;

        require(_startTime > block.timestamp, "NFT: invalid start time");
        startTime = _startTime;

        require(_royaltyReceivers.length == _royaltyBPS.length, "NFT: invalid royalties; length mismatch");
        for (uint256 i = 0; i < _royaltyReceivers.length; i++) {
            royalties.receivers.push(payable(_royaltyReceivers[i]));
            royalties.receiverToBPS[_royaltyReceivers[i]] = _royaltyBPS[i];
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 _quantity) external payable {
        require(block.timestamp >= startTime, "NFT: minting not started");
        require(totalSupply() + _quantity <= maxSupply, "NFT: max supply reached");
        require(msg.value >= mintPrice * _quantity, "NFT: insufficient funds");

        _mint(msg.sender, _quantity);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256) {
        uint256 totalRoyalty = 0;
        for (uint256 i = 0; i < royalties.receivers.length; i++) {
            totalRoyalty += _salePrice * royalties.receiverToBPS[royalties.receivers[i]] / 10000;
        }
        return (address(this), totalRoyalty);
    }

    receive() external payable {
        for (uint256 i = 0; i < royalties.receivers.length; i++) {
            uint256 royaltyAmount = msg.value * royalties.receiverToBPS[royalties.receivers[i]] / 10000;
            royalties.receivers[i].call{value: royaltyAmount}("");
            emit RoyaltyPaid(royalties.receivers[i], royaltyAmount);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC165Upgradeable, ERC721AUpgradeable)
        returns (bool)
    {
        return ERC721AUpgradeable.supportsInterface(interfaceId) || interfaceId == type(IERC2981Upgradeable).interfaceId;
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

    function setRoyalties(address payable[] calldata _royaltyReceivers, uint256[] calldata _royaltyBPS)
        external
        onlyOwner
    {
        require(_royaltyReceivers.length == _royaltyBPS.length, "NFT: invalid input");
        royalties.receivers = _royaltyReceivers;
        for (uint256 i = 0; i < _royaltyReceivers.length; i++) {
            royalties.receiverToBPS[_royaltyReceivers[i]] = _royaltyBPS[i];
        }
        emit RoyaltiesUpdated(_royaltyReceivers, _royaltyBPS);
    }

    function withdrawFunds(address payable _to) external onlyOwner {
        uint256 balance = address(this).balance;
        _to.call{value: balance}("");
        emit Withdrawn(_to, balance);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
