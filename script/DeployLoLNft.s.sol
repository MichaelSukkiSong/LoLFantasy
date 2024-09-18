// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;
import {Script} from "forge-std/Script.sol";
import {LoLNft} from "../src/LoLNft.sol";

contract DeployLoLNft is Script {
    LoLNft public loLNft;

    function run() public returns (LoLNft) {
        vm.startBroadcast();
        loLNft = new LoLNft();
        vm.stopBroadcast();

        return loLNft;
    }
}
