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

library Calculate {
    function midLanerTotalScore(
        MidLaner memory midLaner
    ) internal pure returns (uint256) {
        // calculate the total score of a midLaner
        uint256 totalScore = 0;
        totalScore =
            midLaner.soloKillPotential +
            midLaner.laneDominancePotential +
            midLaner.gankResistanceAbility +
            midLaner.towerPressureCapability +
            midLaner.teamfightInfluenceVsEnemyMid +
            midLaner.csAdvantagePotential +
            midLaner.goldLeadPotential +
            midLaner.roamingEffectiveness +
            midLaner.dodgeSuccessProbability;

        return totalScore;
    }
}

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

contract LoLFantasy is VRFConsumerBaseV2Plus {
    // errors
    error LoLFantasy__AlreadyCreatedMidLaner();
    error LoLFantasy__GameStateIsNotOpen();
    error LoLFantasy__NotCreatedMidLaner();
    error LoLFantasy__NotOwner();
    error LoLFantasy__NotSummoner();
    error LoLFantasy__NotParticipant();
    error LoLFantasy__NotEnoughJoiningFee();
    error LoLFantasy__AlreadyJoinedSeason();
    error LoLFantasy__UnknownRequestId();
    error LoLFantasy__NotEnoughParticipants();

    enum LoLFantasyState {
        OPEN,
        CLOSED
    }

    // State variables
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 public constant CALLBACK_GAS_LIMIT = 200000;
    uint256 public constant MAX_PERCENTAGE = 100;
    uint256 public constant MINIMUM_JOINING_FEE = 0;
    address private immutable i_owner;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint256 private s_requestId;
    LoLFantasyState private s_gameState;
    address[] private s_summoners;
    address[] private s_participants;
    uint256 private s_prize;

    // requestId => summoner
    mapping(uint256 => address) private s_mapRequestIdToSummoner;
    // summoner => MidLaner
    mapping(address => MidLaner) private s_mapSummonerToMidLaner;
    // participant => bool
    mapping(address => bool) private s_mapParticipantToStatus;
    // requestId => requestType
    mapping(uint256 => string) private s_requestIdToType;

    // Events
    event MidLanerCreated(uint256 indexed requestId, address indexed summoner);
    event WinnerSelected(address indexed winner);

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

    function createMidLaner() public {
        // require: dont let the same address call this function twice
        if (s_mapSummonerToMidLaner[msg.sender].soloKillPotential != 0) {
            revert LoLFantasy__AlreadyCreatedMidLaner();
        }
        // require: can only call when state is OPEN
        require(s_gameState == LoLFantasyState.OPEN, "Game is not open");
        if (s_gameState != LoLFantasyState.OPEN) {
            revert LoLFantasy__GameStateIsNotOpen();
        }

        s_gameState = LoLFantasyState.CLOSED;

        // kick off VRF request
        s_requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: CALLBACK_GAS_LIMIT,
                numWords: 9,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        // save the requestId
        s_mapRequestIdToSummoner[s_requestId] = msg.sender;

        s_requestIdToType[s_requestId] = "createMidLaner";
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        string memory requestType = s_requestIdToType[requestId];

        if (
            keccak256(abi.encodePacked(requestType)) ==
            keccak256(abi.encodePacked("createMidLaner"))
        ) {
            // create midLaner: assign the random number to each stat
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

            // save the midLaner
            s_mapSummonerToMidLaner[msg.sender] = midLaner;
            s_summoners.push(msg.sender);

            s_gameState = LoLFantasyState.OPEN;

            emit MidLanerCreated(requestId, msg.sender);
        } else if (
            keccak256(abi.encodePacked(requestType)) ==
            keccak256(abi.encodePacked("competeSeason"))
        ) {
            // competeSeason
            // two summoners compete laning against each other
            address winner = competeLaningAndReturnWinner(
                msg.sender,
                s_summoners[randomWords[0] % s_summoners.length]
            );

            // clear the mapParticipantToStatus
            for (uint i = 0; i < s_participants.length; i++) {
                delete s_mapParticipantToStatus[s_participants[i]];
            }

            // clear the participants array
            delete s_participants;
            // s_participants = new address[](0);

            // clear prize pool
            s_prize = 0;

            emit WinnerSelected(winner);
        } else {
            revert LoLFantasy__UnknownRequestId();
        }
    }

    // two summoners compete laning against each other
    function competeLaningAndReturnWinner(
        address _summoner1,
        address _summoner2
    ) internal view returns (address) {
        // require: both summoners have created midLaner
        if (s_mapSummonerToMidLaner[_summoner1].soloKillPotential == 0) {
            revert LoLFantasy__NotCreatedMidLaner();
        }
        if (s_mapSummonerToMidLaner[_summoner2].soloKillPotential == 0) {
            revert LoLFantasy__NotCreatedMidLaner();
        }

        // calculate the score of each summoner
        uint256 score1 = Calculate.midLanerTotalScore(
            s_mapSummonerToMidLaner[_summoner1]
        );
        uint256 score2 = Calculate.midLanerTotalScore(
            s_mapSummonerToMidLaner[_summoner2]
        );

        // return the winner address of the summoner with higher score
        if (score1 > score2) {
            return _summoner1;
        } else {
            return _summoner2;
        }
    }

    function joinSeason() public payable {
        // require: msg.value > MINIMUM_JOINING_FEE
        if (msg.value <= MINIMUM_JOINING_FEE) {
            revert LoLFantasy__NotEnoughJoiningFee();
        }
        // require: can not join multiple times
        if (s_mapParticipantToStatus[msg.sender]) {
            revert LoLFantasy__AlreadyJoinedSeason();
        }
        // require: only summoners can join
        if (s_mapSummonerToMidLaner[msg.sender].soloKillPotential == 0) {
            revert LoLFantasy__NotSummoner();
        }

        // summoner joins the season as participant
        s_participants.push(msg.sender);
        s_mapParticipantToStatus[msg.sender] = true;

        // add the prize to the prize pool
        s_prize += msg.value;
    }

    function competeSeason() public {
        // require: only participants can compete
        if (!s_mapParticipantToStatus[msg.sender]) {
            revert LoLFantasy__NotParticipant();
        }
        // require: can only run when participants are more than 1
        if (s_participants.length <= 1) {
            revert LoLFantasy__NotEnoughParticipants();
        }

        // out of all the paricipants pick 1 random oponents to compete
        s_requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: CALLBACK_GAS_LIMIT,
                numWords: 1,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        s_requestIdToType[s_requestId] = "competeSeason";
    }
}
