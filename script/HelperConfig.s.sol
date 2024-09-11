// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {console} from "forge-std/console.sol";

abstract contract CodeConstants {
    // Chain IDs
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ANVIL_CHAIN_ID = 31337;

    // VRF mock constructor variables
    uint96 public constant BASE_FEE = 0;
    uint96 public constant GAS_PRICE = 0;
    int256 public constant WEI_PER_UNIT_LINK = 1;
}

contract HelperConfig is CodeConstants, Script {
    struct NetworkConfig {
        address vrfCoordinator;
        bytes32 keyHash;
        uint256 subscriptionId;
        address link;
        address account;
    }

    mapping(uint256 => NetworkConfig) private networkConfigs;

    constructor() {
        if (block.chainid == ANVIL_CHAIN_ID) {
            networkConfigs[block.chainid] = getAnvilConfig();
        } else if (block.chainid == SEPOLIA_CHAIN_ID) {
            networkConfigs[block.chainid] = getSepoliaConfig();
        }
    }

    function getNetworkConfig() public view returns (NetworkConfig memory) {
        return networkConfigs[block.chainid];
    }

    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subscriptionId: 0,
                link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                account: 0x6b748671F2F3B1d264f554f87B64227e0Ac142ec
            });
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        // deploy mock vrf coordinator
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinator = new VRFCoordinatorV2_5Mock(
            BASE_FEE,
            GAS_PRICE,
            WEI_PER_UNIT_LINK
        );
        LinkToken link = new LinkToken();
        vm.stopBroadcast();

        return
            NetworkConfig({
                vrfCoordinator: address(vrfCoordinator),
                // doesnt matter
                keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subscriptionId: 0,
                link: address(link),
                account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
            });
    }
}
