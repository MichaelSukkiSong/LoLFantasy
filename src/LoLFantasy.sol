// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract LoLFantasy is VRFConsumerBaseV2Plus {
    // errors
    // interfaces, libraries, contracts

    // Type declarations
    struct MidLaner {
        uint256 soloKillPotential; // number between 1-100
        uint256 laneDominancePotential; // number between 1-100
        uint256 gankResistanceAbility; // number between 1-100
        uint256 towerPressureCapability; // number between 1-100
        uint256 teamfightInfluenceVsEnemyMid; // number between 1-100
        uint256 csAdvantagePotential; // number between 1-100
        uint256 goldLeadPotential; // number between 1-100
        uint256 roamingEffectiveness; // number between 1-100
        uint256 dodgeSuccessProbability; // number between 1-100
    }

    // State variables
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 public constant NUM_WORDS = 9;
    uint32 public constant CALLBACK_GAS_LIMIT = 200000;
    uint256 public constant MAX_PERCENTAGE = 100;
    address private immutable i_owner;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint256 private requestId;

    // requestId => summoner
    mapping(uint256 => address) private s_mapRequestIdToSummoner;
    // summoner => MidLaner
    mapping(address => MidLaner) private s_mapSummonerToMidLaner;

    // Events
    event MidLanerCreated(uint256 indexed requestId, address indexed summoner);

    // Modifiers

    constructor(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint256 _subscriptionId
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_keyHash = _keyHash;
        i_subscriptionId = _subscriptionId;
        i_owner = msg.sender;
    }

    function createMidLaner() public returns (MidLaner memory) {
        // require: dont let the same address call this function twice
        require(
            s_mapSummonerToMidLaner[msg.sender].length == 0,
            "LoLFantasy: Already called"
        );

        // kick off VRF request
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: CALLBACK_GAS_LIMIT,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        s_mapRequestIdToSummoner[requestId] = msg.sender;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        // assign the random number to each stat
        MidLaner memory midLaner = MidLaner({
            soloKillPotential: randomWords[0] % MAX_PERCENTAGE,
            laneDominancePotential: randomWords[1] % MAX_PERCENTAGE,
            gankResistanceAbility: randomWords[2] % MAX_PERCENTAGE,
            towerPressureCapability: randomWords[3] % MAX_PERCENTAGE,
            teamfightInfluenceVsEnemyMid: randomWords[4] % MAX_PERCENTAGE,
            csAdvantagePotential: randomWords[5] % MAX_PERCENTAGE,
            goldLeadPotential: randomWords[6] % MAX_PERCENTAGE,
            roamingEffectiveness: randomWords[7] % MAX_PERCENTAGE,
            dodgeSuccessProbability: randomWords[8] % MAX_PERCENTAGE
        });

        s_mapSummonerToMidLaner[msg.sender] = midLaner;

        emit MidLanerCreated(requestId, msg.sender);
    }
}
