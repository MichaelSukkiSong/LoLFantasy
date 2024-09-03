// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {LoLFantasy} from "../src/LoLFantasy.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployLoLFantasy is Script {
    LoLFantasy lolFantasy;
    HelperConfig helperConfig;

    function run() public {
        deployContract();
    }

    function deployContract() public returns (LoLFantasy) {
        helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getNetworkConfig();

        address vrfCoordinator = networkConfig.vrfCoordinator;
        bytes32 keyHash = networkConfig.keyHash;
        uint256 subscriptionId = networkConfig.subscriptionId;

        vm.startBroadcast();
        lolFantasy = new LoLFantasy(vrfCoordinator, keyHash, subscriptionId);
        vm.stopBroadcast();

        return lolFantasy;
    }
}
