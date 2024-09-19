// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;
import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {LoLNft} from "../src/LoLNft.sol";

contract CreateSubscription is CodeConstants, Script {
    function createSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getNetworkConfig();

        createSubscription(networkConfig.vrfCoordinator, networkConfig.account);
    }

    function createSubscription(
        address vrfCoordinator,
        address account
    ) public returns (uint256) {
        console.log("Creating subscription on chain Id:", block.chainid);
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();

        console.log("Your subscription Id is:", subId);
        console.log(
            "Please update the subscription Id in your HelperConfig.s.sol"
        );

        return subId;
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is CodeConstants, Script {
    uint256 public constant FUND_AMOUNT = 10 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getNetworkConfig();

        fundSubscription(
            networkConfig.vrfCoordinator,
            networkConfig.subscriptionId,
            networkConfig.link,
            networkConfig.account
        );
    }

    function fundSubscription(
        address vrfCoordinator,
        uint256 subscriptionId,
        address link,
        address account
    ) public {
        console.log("Funding subscription: ", subscriptionId);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainId: ", block.chainid);

        if (block.chainid == ANVIL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subscriptionId,
                FUND_AMOUNT * 100
            );
            vm.stopBroadcast();
        } else if (block.chainid == SEPOLIA_CHAIN_ID) {
            vm.startBroadcast(account);
            LinkToken(link).transferAndCall(
                address(vrfCoordinator),
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );
            vm.stopBroadcast();
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
            consumer,
            networkConfig.account
        );
    }

    function addConsumer(
        address vrfCoordinator,
        uint256 subscriptionId,
        address consumer,
        address account
    ) public {
        console.log("Adding consumer contract: ", consumer);
        console.log("To vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainId: ", block.chainid);

        vm.startBroadcast(account);
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

contract MintLoLNft is Script {
    string public constant FAKER =
        "https://ipfs.io/ipfs/QmbUizF88PWRLv2WHn8yegXpTY9WXvgnuu7EB4iEDmRGZt";
    string public constant SHOWMAKER =
        "https://ipfs.io/ipfs/QmYqHMDenySgjihh89rSH4EsMea6ogot1SNKNcsXCFc9CD";
    string public constant SCOUT =
        "https://ipfs.io/ipfs/QmcQHWWdoxXBQXtVtMpq2seohjWTcfj7JLoTNSn1UkvFWB";
    string public constant ZEKA =
        "https://ipfs.io/ipfs/QmRNBESTZFxT3zQj2TU2BM5uMDn5XqkxByqcAv3vfzbat3";

    function run() public {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "LoLNft",
            block.chainid
        );

        mintNftUsingConfig(mostRecentlyDeployed);
    }

    function mintNftUsingConfig(address contractAddress) public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getNetworkConfig();

        mintNft(contractAddress, networkConfig.account);
    }

    function mintNft(address contractAddress, address account) public {
        vm.startBroadcast(account);
        LoLNft(contractAddress).mint(FAKER);
        LoLNft(contractAddress).mint(SHOWMAKER);
        LoLNft(contractAddress).mint(SCOUT);
        LoLNft(contractAddress).mint(ZEKA);
        vm.stopBroadcast();
    }
}
