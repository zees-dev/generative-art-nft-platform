// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {NFTRegistry} from "../src/NFTRegistry.sol";
import {NFTCollection} from "../src/NFTCollection.sol";
import {RoyaltySplitter} from "../src/RoyaltySplitter.sol";

contract NFTRegistryScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        RoyaltySplitter royaltySplitterImpl = new RoyaltySplitter();
        NFTCollection nftCollectionImpl = new NFTCollection();
        NFTRegistry registryImpl = new NFTRegistry();
        new ERC1967Proxy(
            address(registryImpl),
            abi.encodeWithSignature(
                "initialize(address,address)",
                address(royaltySplitterImpl),
                address(nftCollectionImpl)
            )
        );

        vm.stopBroadcast();
    }
}
