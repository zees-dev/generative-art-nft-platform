// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {PaymentSplitterUpgradeable} from "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";

contract RoyaltySplitter is PaymentSplitterUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address[] memory payees, uint256[] memory shares_) external initializer {
        __PaymentSplitter_init(payees, shares_);
    }
}
