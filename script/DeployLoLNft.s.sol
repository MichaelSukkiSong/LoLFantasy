// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;
import {Script} from "forge-std/Script.sol";
import {LoLNft} from "../src/LoLNft.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DeployLoLNft is Script {
    LoLNft public loLNft;

    function run() public returns (LoLNft) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getNetworkConfig();

        vm.startBroadcast(networkConfig.account);
        loLNft = new LoLNft();
        vm.stopBroadcast();

        return loLNft;
    }
}
