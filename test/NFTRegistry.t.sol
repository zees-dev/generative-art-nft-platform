// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "../src/NFTRegistry.sol";
import "../src/NFTCollection.sol";
import "../src/RoyaltySplitter.sol";

contract NFTRegistryTest is Test {
    event CollectionCreated(address indexed owner, address indexed collection, uint256 indexed collectionId);

    address public nftRegistry;

    function setUp() public {
        RoyaltySplitter royaltySplitterImpl = new RoyaltySplitter();
        NFTCollection nftCollectionImpl = new NFTCollection();
        NFTRegistry registryImpl = new NFTRegistry();
        nftRegistry = address(new ERC1967Proxy(
            address(registryImpl),
            abi.encodeWithSignature(
                "initialize(address,address)",
                address(royaltySplitterImpl),
                address(nftCollectionImpl)
            )
        ));
    }

    function test_DeploymentCost() public {
        RoyaltySplitter royaltySplitterImpl = new RoyaltySplitter();
        NFTCollection nftCollectionImpl = new NFTCollection();
        NFTRegistry registryImpl = new NFTRegistry();
        address(new ERC1967Proxy(
            address(registryImpl),
            abi.encodeWithSignature(
                "initialize(address,address)",
                address(royaltySplitterImpl),
                address(nftCollectionImpl)
            )
        ));
    }

    function test_CollectionRegistration() public {
        address[] memory payees = new address[](1);
        payees[0] = address(0x1);
        uint256[] memory shares = new uint256[](1);
        shares[0] = 1000;

        vm.expectEmit(true, false, true, false, nftRegistry);
        emit CollectionCreated(address(this), address(0), 1);
        address collection = NFTRegistry(nftRegistry).createCollection(abi.encode(
            address(this),
            "Test Collection",
            "TEST",
            "https://test.com/",
            100,
            0.2 ether,
            block.timestamp + 1 seconds,
            payees,
            shares
        ));
    }

    function test_CollectionRoyalties() public {
        address[] memory payees = new address[](1);
        payees[0] = address(0x1);
        uint256[] memory shares = new uint256[](1);
        shares[0] = 1000;

        address collection = NFTRegistry(nftRegistry).createCollection(abi.encode(
            address(this),
            "Test Collection",
            "TEST",
            "https://test.com/",
            100,
            0.2 ether,
            block.timestamp + 1 seconds,
            payees,
            shares
        ));

        NFTCollection nftCollection = NFTCollection(collection);
        (address royalty, uint256 amount) = nftCollection.royaltyInfo(0, 1000);
        assertEq(royalty, address(0x1));
    }
}

