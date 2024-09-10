// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {console} from "forge-std/console.sol";

contract LoLToken is ERC20 {
    uint256 constant INITIAL_SUPPLY = 1000000000000000000000000; // 10^24

    constructor() ERC20("LoLToken", "LoL", 18) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}
