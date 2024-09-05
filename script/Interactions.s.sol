// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;
import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is CodeConstants, Script {
    function createSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getNetworkConfig();

        createSubscription(networkConfig.vrfCoordinator);
    }

    function createSubscription(
        address vrfCoordinator
    ) public returns (uint256) {
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();

        return subId;
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is CodeConstants, Script {
    uint256 public constant FUND_AMOUNT = 20 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getNetworkConfig();

        fundSubscription(
            networkConfig.vrfCoordinator,
            networkConfig.subscriptionId
        );
    }

    function fundSubscription(
        address vrfCoordinator,
        uint256 subscriptionId
    ) public {
        if (block.chainid == ANVIL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subscriptionId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else if (block.chainid == SEPOLIA_CHAIN_ID) {
            // TODO : LINK token
            /*
            LINKTOKEN.transferAndCall(
                address(COORDINATOR),
                amount,
                abi.encode(subId)
            );
            */
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address consumer) public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getNetworkConfig();

        addConsumer(
            networkConfig.vrfCoordinator,
            networkConfig.subscriptionId,
            consumer
        );
    }

    function addConsumer(
        address vrfCoordinator,
        uint256 subscriptionId,
        address consumer
    ) public {
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(
            subscriptionId,
            consumer
        );
        vm.stopBroadcast();
    }

    function run() public {
        // get mostRecentlyDeployed
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "LoLFantasy",
            block.chainid
        );

        // add as consumer
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}
