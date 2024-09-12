// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;
import {Test} from "forge-std/Test.sol";
import {LoLToken} from "../../src/LoLToken.sol";
import {DeployLoLToken} from "../../script/DeployLoLToken.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract LoLTokenTest is Test {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    DeployLoLToken deployLoLToken;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig networkConfig;
    LoLToken loLToken;

    uint256 constant INITIAL_SUPPLY = 1000000000000000000000000; // 10^24
    uint256 constant TRANSFERRED_AMOUNT = 100;
    uint256 constant ALLOWED_AMOUNT = 10;
    string constant NAME = "LoLToken";
    string constant SYMBOL = "LoL";
    uint8 constant DECIMALS = 18;

    address public USER_A = makeAddr("USER_A");
    address public USER_B = makeAddr("USER_B");

    function setUp() public {
        deployLoLToken = new DeployLoLToken();
        loLToken = deployLoLToken.deployContract();

        helperConfig = new HelperConfig();
        networkConfig = helperConfig.getNetworkConfig();
    }

    function test_ConstructorIsCalled() public view {
        assertEq(loLToken.totalSupply(), INITIAL_SUPPLY);
        assertEq(loLToken.name(), NAME);
        assertEq(loLToken.symbol(), SYMBOL);
        assertEq(loLToken.decimals(), DECIMALS);
    }

    function test_CheckMintedAddressProperlyHasTheInitialSupply() public view {
        assertEq(loLToken.balanceOf(networkConfig.account), INITIAL_SUPPLY);
    }

    function test_Approve() public {
        vm.expectEmit(true, true, false, false);
        emit Approval(USER_A, USER_B, ALLOWED_AMOUNT);

        vm.prank(USER_A);
        loLToken.approve(USER_B, ALLOWED_AMOUNT);

        assertEq(loLToken.allowance(USER_A, USER_B), ALLOWED_AMOUNT);
    }

    function test_Transfer() public {
        vm.expectEmit(true, true, false, false);
        emit Transfer(networkConfig.account, USER_A, TRANSFERRED_AMOUNT);

        vm.prank(networkConfig.account);
        loLToken.transfer(USER_A, TRANSFERRED_AMOUNT);

        assertEq(loLToken.balanceOf(USER_A), TRANSFERRED_AMOUNT);
        assertEq(
            loLToken.balanceOf(networkConfig.account),
            INITIAL_SUPPLY - TRANSFERRED_AMOUNT
        );
    }

    function test_TransferFrom() public {
        vm.prank(networkConfig.account);
        loLToken.transfer(USER_A, TRANSFERRED_AMOUNT);

        vm.prank(USER_A);
        loLToken.approve(USER_B, ALLOWED_AMOUNT);

        vm.expectEmit(true, true, false, false);
        emit Transfer(USER_A, USER_B, ALLOWED_AMOUNT);
        vm.prank(USER_B);
        loLToken.transferFrom(USER_A, USER_B, ALLOWED_AMOUNT);

        assertEq(loLToken.balanceOf(USER_B), ALLOWED_AMOUNT);
        assertEq(
            loLToken.balanceOf(USER_A),
            TRANSFERRED_AMOUNT - ALLOWED_AMOUNT
        );
    }
}
