// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract NFTRegistry is UUPSUpgradeable, OwnableUpgradeable, ERC165Upgradeable {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event CollectionCreated(address indexed owner, address indexed collection, uint256 indexed collectionId);

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    UpgradeableBeacon public nftCollectionBeacon;
    address public royaltySplitterImpl;
    uint256 public totalCollections;
    mapping(uint256 => address) public collections;

    /*//////////////////////////////////////////////////////////////
                                LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _royaltySplitterImpl, address _nftCollectionImpl) external initializer {
        __Ownable_init();

        royaltySplitterImpl = _royaltySplitterImpl;
        // Deploy beacon for NFTCollection
        nftCollectionBeacon = new UpgradeableBeacon(address(_nftCollectionImpl));
    }

    function createCollection(bytes memory collectionData) external returns (address) {
        (
            address _owner,
            string memory _name,
            string memory _symbol,
            string memory _baseTokenURI,
            uint256 _maxSupply,
            uint256 _mintPrice,
            uint256 _startTime,
            address[] memory royaltyReceivers,
            uint256[] memory royaltyBPS
        ) = abi.decode(
            collectionData, (address, string, string, string, uint256, uint256, uint256, address[], uint256[])
        );

        ERC1967Proxy paymentProxy = new ERC1967Proxy(
            royaltySplitterImpl,
            abi.encodeWithSignature("initialize(address[],uint256[])", royaltyReceivers, royaltyBPS)
        );
        uint96 royaltyAmount;
        for (uint256 i = 0; i < royaltyBPS.length;) {
            royaltyAmount += uint96(royaltyBPS[i]);
            unchecked {
                i++;
            }
        }

        // Deploy and initialize proxy for NFTCollection
        address nftCollectionProxy = address(
            new BeaconProxy(
            address(nftCollectionBeacon),
            abi.encodeWithSignature(
                    "initialize(address,string,string,string,uint256,uint256,uint256,address,uint96)",
                    _owner,
                    _name,
                    _symbol,
                    _baseTokenURI,
                    _maxSupply,
                    _mintPrice,
                    _startTime,
                    address(paymentProxy),
                    royaltyAmount
                )
            )
        );

        // Store address of NFTCollection
        collections[totalCollections] = nftCollectionProxy;
        totalCollections++;

        emit CollectionCreated(msg.sender, nftCollectionProxy, totalCollections - 1);

        return nftCollectionProxy;
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function upgradeNFTCollections(address _newImplementation) external onlyOwner {
        nftCollectionBeacon.upgradeTo(_newImplementation);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
