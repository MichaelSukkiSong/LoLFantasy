// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {LoLFantasy} from "../src/LoLFantasy.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployLoLFantasy is Script {
    LoLFantasy lolFantasy;
    HelperConfig helperConfig;

    function run() public {
        deployContract();
    }

    function deployContract() public returns (LoLFantasy, HelperConfig) {
        helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getNetworkConfig();

        if (networkConfig.subscriptionId == 0) {
            // create subscription
            CreateSubscription createSubscription = new CreateSubscription();
            networkConfig.subscriptionId = createSubscription
                .createSubscription(
                    networkConfig.vrfCoordinator,
                    networkConfig.account
                );
            // fund subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                networkConfig.vrfCoordinator,
                networkConfig.subscriptionId,
                networkConfig.link,
                networkConfig.account
            );
        }

        // deploy contract
        vm.startBroadcast(networkConfig.account);
        lolFantasy = new LoLFantasy(
            networkConfig.vrfCoordinator,
            networkConfig.keyHash,
            networkConfig.subscriptionId,
            networkConfig.lolToken,
            networkConfig.lolNft
        );
        vm.stopBroadcast();

        // add contract as consumer
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            networkConfig.vrfCoordinator,
            networkConfig.subscriptionId,
            address(lolFantasy),
            networkConfig.account
        );

        return (lolFantasy, helperConfig);
    }
}
