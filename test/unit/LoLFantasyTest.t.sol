// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {LoLFantasy} from "../../src/LoLFantasy.sol";
import {DeployLoLFantasy} from "../../script/DeployLoLFantasy.s.sol";

contract LoLFantasyTest is Test {
    LoLFantasy lolFantasy;

    function setUp() public {
        DeployLoLFantasy deployLoLFantasy = new DeployLoLFantasy();
        lolFantasy = deployLoLFantasy.deployContract();
    }
}
