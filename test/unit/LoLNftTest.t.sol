// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {LoLNft} from "../../src/LoLNft.sol";
import {DeployLoLNft} from "../../script/DeployLoLNft.s.sol";

contract LoLNftTest is Test {
    LoLNft loLNft;
    DeployLoLNft deployer;
    string public constant FAKER =
        "https://ipfs.io/ipfs/QmbUizF88PWRLv2WHn8yegXpTY9WXvgnuu7EB4iEDmRGZt";
    string public constant SHOWMAKER =
        "https://ipfs.io/ipfs/QmYqHMDenySgjihh89rSH4EsMea6ogot1SNKNcsXCFc9CD";
    string public constant SCOUT =
        "https://ipfs.io/ipfs/QmcQHWWdoxXBQXtVtMpq2seohjWTcfj7JLoTNSn1UkvFWB";
    string public constant ZEKA =
        "https://ipfs.io/ipfs/QmRNBESTZFxT3zQj2TU2BM5uMDn5XqkxByqcAv3vfzbat3";

    address public USER = makeAddr("USER");

    function setUp() public {
        deployer = new DeployLoLNft();
        loLNft = deployer.run();
    }

    function test_nameAndSymbol() public view {
        string memory expectedName = "LoLNft";
        string memory expectedSymbol = "LN";

        assertEq(loLNft.name(), expectedName);
        assertEq(loLNft.symbol(), expectedSymbol);
    }

    function test_mintLoLNft() public {
        vm.prank(USER);
        loLNft.mint(FAKER);

        assert(loLNft.balanceOf(USER) == 1);
        assert(
            keccak256(abi.encodePacked(loLNft.tokenURI(0))) ==
                keccak256(abi.encodePacked(FAKER))
        );
    }
}
