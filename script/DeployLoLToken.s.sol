// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {LoLToken} from "../src/LoLToken.sol";

contract DeployLoLToken is Script {
    LoLToken loLToken;

    function run() public {
        deployContract();
    }

    function deployContract() public returns (LoLToken) {
        vm.startBroadcast();
        loLToken = new LoLToken();
        vm.stopBroadcast();

        return loLToken;
    }
}
