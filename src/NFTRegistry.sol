// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {NFTCollection} from "./NFTCollection.sol";

contract NFTRegistry is UUPSUpgradeable, OwnableUpgradeable, ERC165Upgradeable {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event CollectionCreated(address indexed owner, address indexed collection, uint256 indexed collectionId);

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    UpgradeableBeacon public nftCollectionBeacon;
    uint256 public totalCollections;
    mapping(uint256 => address) public collections;

    /*//////////////////////////////////////////////////////////////
                                LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        __Ownable_init();

        // Deploy reference implementation for NFTCollection
        // NFTCollection nftCollection = new NFTCollection();

        // Deploy beacon for NFTCollection
        // nftCollectionBeacon = new UpgradeableBeacon(address(nftCollection));
    }

    function createCollection(bytes memory collectionData) external returns (address) {
        (address _owner, string memory _name, string memory _symbol, string memory _baseTokenURI, uint256 _maxSupply, uint256 _mintPrice, uint256 _startTime, address[] memory royaltyReceivers, uint256[] memory royaltyBPS) = abi.decode(
            collectionData,
            (address, string, string, string, uint256, uint256, uint256, address[], uint256[]));

        // Deploy and initialize proxy for NFTCollection
        address nftCollectionProxy = address(new BeaconProxy(
            address(nftCollectionBeacon),
            abi.encodeWithSignature(
                "initialize(address,string,string,string,uint256,uint256,uint256,address[],uint256[])",
                _owner,
                _name,
                _symbol,
                _baseTokenURI,
                _maxSupply,
                _mintPrice,
                _startTime,
                royaltyReceivers,
                royaltyBPS
            )
        ));

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
