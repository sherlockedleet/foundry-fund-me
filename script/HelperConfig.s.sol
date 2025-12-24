// SPDX-License-Identifier: MIT

// 1. Deploy mocks when we are on a local anvil chain
// 2. Keep track of contract addresses across different chains
// Sepolia ETH/USD: 0x694AA1769357215DE4FAC081bf1f309aDC325306
// Mainnet ETH/USD: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419

pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
import {Test, console} from "forge-std/Test.sol";

contract HelperConfig is Script {
    // If we are on a local anvil chain, deploy mocks!
    // Otherwise, grab the existing address from the live network

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_ANSWER = 2000e8;

    // console.log("HelperConfig's address: ", address(this));

    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address priceFeed;
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory mainnetConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return mainnetConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // 1. Deploy the mocks
        // 2. Return the mock address

        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }
        console.log("HelperConfig's address: ", address(this));

        vm.startBroadcast();
        address priceFeedAddress = address(
            new MockV3Aggregator(DECIMALS, INITIAL_ANSWER)
        );
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: priceFeedAddress
        });
        return anvilConfig;
    }
}
