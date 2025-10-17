// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFCoordinatorV2_5Mock} from "lib/chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Script} from "forge-std/Script.sol";

abstract contract CodeConstants {
    /* VRF Mock Values */
    uint96 public MOCK_GAS_FEE = 0.25 ether;
    uint96 public MOCK_LINK_FEE = 1 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1 ether;
    /* LINK/ETH Price */
    int256 public MOCK_WEI_PER_UINT_LINK = 4e15;


    uint256 public constant ETH_SEPLOIA_CHAINID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gaselane /*Key Hash*/;
        uint32 callbackGasLimit;
        uint256 subscriptionId;
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } 
        else if (chainId == ETH_SEPLOIA_CHAINID) {
            return getSepoliaEthConfig();
        } 
        else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } 
        else {
            revert HelperConfig___InvalidChainId();
        }
    }


    function getConfig() public returns(NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 => NetworkConfig) public networkConfig;

    constructor() {
        networkConfig[11155111] = getSepoliaEthConfig();
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0x5CE8D5A2BC84beb22a398CCA51996F7930313D61,
            gaselane: 0xe9f223d7d83ec85c4f78042a4845af3a1c8df7757b4997b815ce4b8d07aca68c,
            callbackGasLimit: 500000,
            subscriptionId: 0
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // check to see if we have an active network config
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        // Deploy mocks and such
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(MOCK_GAS_FEE,
            MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UINT_LINK);
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoordinatorMock),
            gaselane: 0xe9f223d7d83ec85c4f78042a4845af3a1c8df7757b4997b815ce4b8d07aca68c, // This doesn't matter for a mock, it can be anything
            callbackGasLimit: 500000,
            subscriptionId: 0
        });
        return localNetworkConfig;
    }
}
