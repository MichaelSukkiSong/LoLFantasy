// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {LoLFantasy} from "../../src/LoLFantasy.sol";
import {DeployLoLFantasy} from "../../script/DeployLoLFantasy.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract LoLFantasyTest is Test {
    DeployLoLFantasy deployLoLFantasy;
    LoLFantasy lolFantasy;
    HelperConfig helperConfig;

    address vrfCoordinator;
    bytes32 keyHash;
    uint256 subscriptionId;
    address link;
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 public constant CALLBACK_GAS_LIMIT = 500000000;
    uint256 public constant MAX_PERCENTAGE = 100;
    uint256 public constant MINIMUM_JOINING_FEE = 0.01 ether;
    uint256 public constant STARTING_BALANCE = 100 ether;
    uint256 public constant JOINING_FEE = 0.02 ether;

    address public USER = makeAddr("USER");
    address public SECOND_USER = makeAddr("SECOND_USER");
    address public THIRD_USER = makeAddr("THIRD_USER");

    // Events
    event MidLanerCreated(uint256 indexed requestId, address indexed summoner);
    event WinnerSelected(address indexed winner);

    function setUp() public {
        deployLoLFantasy = new DeployLoLFantasy();
        (lolFantasy, helperConfig) = deployLoLFantasy.deployContract();

        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getNetworkConfig();

        vrfCoordinator = networkConfig.vrfCoordinator;
        keyHash = networkConfig.keyHash;
        subscriptionId = networkConfig.subscriptionId;
        link = networkConfig.link;

        vm.deal(USER, STARTING_BALANCE);
        vm.deal(SECOND_USER, STARTING_BALANCE);
        vm.deal(THIRD_USER, STARTING_BALANCE);
    }

    function test_PublicConstantVariablesReturnsCorrectValues() public view {
        assertEq(lolFantasy.REQUEST_CONFIRMATIONS(), REQUEST_CONFIRMATIONS);
        assertEq(lolFantasy.CALLBACK_GAS_LIMIT(), CALLBACK_GAS_LIMIT);
        assertEq(lolFantasy.MAX_PERCENTAGE(), MAX_PERCENTAGE);
        assertEq(lolFantasy.MINIMUM_JOINING_FEE(), MINIMUM_JOINING_FEE);
    }

    function test_OwnerIsProperlySet() public view {
        assertEq(lolFantasy.getOwner(), msg.sender);
    }

    function test_ConstructorParametersAreProperlySet() public {
        HelperConfig.NetworkConfig memory networkConfig = new HelperConfig()
            .getNetworkConfig();

        assertEq(lolFantasy.getKeyHash(), networkConfig.keyHash);
        assert(lolFantasy.getSubscriptionId() != 0);
        assert(address(lolFantasy.getVrfCoordinator()) != address(0));
    }

    /***************************/
    /*      createMidLaner     */
    /***************************/

    // 지금 이 함수에서는 이 테스트 못하는것 같음 fulfillrandomwords에서 만들어지고 할듯?
    // function test_CannotCallFunctionIfSummonerAlreadyCreatedMidLaner() public {
    //     // 첫 호출로 MidLaner 생성
    //     vm.prank(USER);
    //     lolFantasy.createMidLaner();
    //     vm.warp(block.timestamp + 1);
    //     vm.roll(block.number + 1);

    //     // 강제로 gameState를 OPEN으로 변경 (상태를 수동으로 설정)
    //      forge inspect LoLFantasy storageLayout
    //      cast storage <contract address> <storage slot number>
    //     // vm.store(address(lolFantasy), bytes32(uint256(2)), bytes32(uint256(0)));

    //     // 이미 생성된 MidLaner로 인해 에러 발생 기대
    //     vm.prank(USER);
    //     vm.expectRevert(LoLFantasy.LoLFantasy__AlreadyCreatedMidLaner.selector);
    //     lolFantasy.createMidLaner();
    // }

    function test_CanOnlyCallWhenStateIsOpenInCreateMidLanerFunction() public {
        vm.prank(USER);
        lolFantasy.createMidLaner();

        vm.prank(USER);
        vm.expectRevert(LoLFantasy.LoLFantasy__GameStateIsNotOpen.selector);
        lolFantasy.createMidLaner();
    }

    function test_GameStateChangesToCalculatingInCreateMidLanerFunction()
        public
    {
        vm.prank(USER);
        lolFantasy.createMidLaner();

        assertEq(uint256(lolFantasy.getGameState()), 1);
    }

    function test_SummonerIsSavedToDatabaseAsIntended() public {
        vm.prank(USER);
        lolFantasy.createMidLaner();
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1);

        assertEq(USER, lolFantasy.getSummonerOfRequestId(1));
    }

    function test_RequestTypeIsSavedAsIntended() public {
        vm.prank(USER);
        lolFantasy.createMidLaner();
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1);

        assertEq("createMidLaner", lolFantasy.getRequestTypeOfRequestId(1));
    }

    modifier midLanerCreated() {
        vm.prank(USER);
        lolFantasy.createMidLaner();
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1);
        _;
    }

    /*******************************/
    /*      fulfillRandomWords     */
    /*******************************/

    function test_FulfillrandomWordsCanOnlyBeCalledAfterCreateMidLanerFunctionIsCalled(
        uint256 randomRequestId
    ) public {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        // we are pretending to be the coordinator,
        // in the actual corordinator, not anybody can call this function
        // only the chainlink nodes themselves can call this function
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(lolFantasy)
        );
    }

    function test_FulfillrandomWordsCreatesAMidLanerSaveToDatabaseChangesStateAndEmitsEvent()
        public
        midLanerCreated
    {
        uint256 requestId = 1;

        // assert: emits event
        vm.expectEmit(true, true, false, false);
        emit MidLanerCreated(requestId, USER);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            requestId,
            address(lolFantasy)
        );

        // TODO(done): OutOfGas 오류 나는중!! -> 이건 callbackGasLimit를 넘어서 발생하는 오류였음 해결함
        // TODO(done): soloKillPotential 값이 0 나오는중 -> 해결 주소가 잘못됬었음. vrfCoordinator가 콜하니 vrfCoordinator의 주소여야함

        // assert: midlaner is saved
        assert(lolFantasy.getMidLanerOfSummoner(USER).soloKillPotential != 0);
        // assert: summoners is saved
        for (uint256 i = 0; i < lolFantasy.getSummoners().length; i++) {
            if (lolFantasy.getSummoners()[i] == USER) {
                assertEq(lolFantasy.getSummoners()[i], USER);
            }
        }
        // assert: state is changed to open
        assertEq(uint256(lolFantasy.getGameState()), 0);
    }

    // similar to "test_FulfillrandomWordsCanOnlyBeCalledAfterCreateMidLanerFunctionIsCalled"
    function test_RevertsIfRequestTypeIsNotValid() public {
        uint256 requestId = 1;

        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            requestId,
            address(lolFantasy)
        );
    }

    /***********************/
    /*      joinSeason     */
    /***********************/

    function test_RevertIfJoiningFeeIsLessThanMinimum() public midLanerCreated {
        vm.prank(USER);
        vm.expectRevert(LoLFantasy.LoLFantasy__NotEnoughJoiningFee.selector);
        lolFantasy.joinSeason{value: 0.001 ether}();
    }

    function test_CannotJoinMultipleTimes()
        public
        midLanerCreated
        fulfillRandomWords(1)
    {
        vm.prank(USER);
        lolFantasy.joinSeason{value: JOINING_FEE}();

        vm.expectRevert(LoLFantasy.LoLFantasy__AlreadyJoinedSeason.selector);
        vm.prank(USER);
        lolFantasy.joinSeason{value: JOINING_FEE}();
    }

    function test_OnlySummonersCanJoin() public {
        vm.expectRevert(LoLFantasy.LoLFantasy__NotSummoner.selector);
        vm.prank(USER);
        lolFantasy.joinSeason{value: JOINING_FEE}();
    }

    function test_DataStrucutreIsUpdatedProperly()
        public
        midLanerCreated
        fulfillRandomWords(1)
    {
        vm.prank(USER);
        lolFantasy.joinSeason{value: JOINING_FEE}();

        for (uint256 i = 0; i < lolFantasy.getParticipants().length; i++) {
            if (lolFantasy.getParticipants()[i] == USER) {
                assertEq(lolFantasy.getParticipants()[i], USER);
            }
        }

        assert(lolFantasy.getParticipantStatus(USER));
    }

    modifier fulfillRandomWords(uint256 reqId) {
        uint256 requestId = reqId;

        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            requestId,
            address(lolFantasy)
        );

        _;
    }

    /**************************/
    /*      competeSeason     */
    /**************************/

    modifier midLanerCreatedAndFulfillRandomWords(address user, uint256 reqId) {
        vm.prank(user);
        lolFantasy.createMidLaner();
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1);

        uint256 requestId = reqId;

        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            requestId,
            address(lolFantasy)
        );

        _;
    }

    function test_OnlyParticipantsCanCompete()
        public
        midLanerCreated
        fulfillRandomWords(1)
        midLanerCreatedAndFulfillRandomWords(SECOND_USER, 2)
    {
        vm.prank(USER);
        lolFantasy.joinSeason{value: JOINING_FEE}();

        vm.prank(SECOND_USER);
        lolFantasy.joinSeason{value: JOINING_FEE}();

        vm.prank(THIRD_USER);
        vm.expectRevert(LoLFantasy.LoLFantasy__NotParticipant.selector);
        lolFantasy.competeSeason();
    }

    function test_CanOnlyRunWhenParticipantsAreMoreThanOne()
        public
        midLanerCreated
        fulfillRandomWords(1)
    {
        vm.prank(USER);
        lolFantasy.joinSeason{value: JOINING_FEE}();

        vm.prank(USER);
        vm.expectRevert(LoLFantasy.LoLFantasy__NotEnoughParticipants.selector);
        lolFantasy.competeSeason();
    }

    function test_CanOnlyCallWhenStateIsOpenInCompeteSeasonFunction()
        public
        midLanerCreated
        fulfillRandomWords(1)
        midLanerCreatedAndFulfillRandomWords(SECOND_USER, 2)
    {
        vm.prank(USER);
        lolFantasy.joinSeason{value: JOINING_FEE}();

        vm.prank(SECOND_USER);
        lolFantasy.joinSeason{value: JOINING_FEE}();

        // change state to CALCULATING manually
        // this is done as a quick fix to change game state for testing purposes
        lolFantasy.changeStateToCalculating();

        vm.prank(USER);
        vm.expectRevert(LoLFantasy.LoLFantasy__GameStateIsNotOpen.selector);
        lolFantasy.competeSeason();
    }

    function test_FinalWinnerIsSelected()
        public
        midLanerCreated
        fulfillRandomWords(1)
        midLanerCreatedAndFulfillRandomWords(SECOND_USER, 2)
    {
        vm.prank(USER);
        lolFantasy.joinSeason{value: JOINING_FEE}();

        vm.prank(SECOND_USER);
        lolFantasy.joinSeason{value: JOINING_FEE}();

        vm.prank(USER);
        lolFantasy.competeSeason();

        assert(lolFantasy.getFinalWinner() != address(0));
    }

    function test_DataStructureIsCleared()
        public
        midLanerCreated
        fulfillRandomWords(1)
        midLanerCreatedAndFulfillRandomWords(SECOND_USER, 2)
    {
        vm.prank(USER);
        lolFantasy.joinSeason{value: JOINING_FEE}();

        vm.prank(SECOND_USER);
        lolFantasy.joinSeason{value: JOINING_FEE}();

        vm.prank(USER);
        lolFantasy.competeSeason();

        assertEq(lolFantasy.getParticipantStatus(USER), false);
        assertEq(lolFantasy.getParticipantStatus(SECOND_USER), false);
        assert(lolFantasy.getParticipants().length == 0);
    }

    function test_EventIsEmmitedAfterWinnerIsSelected()
        public
        midLanerCreated
        fulfillRandomWords(1)
        midLanerCreatedAndFulfillRandomWords(SECOND_USER, 2)
    {
        vm.prank(USER);
        lolFantasy.joinSeason{value: JOINING_FEE}();

        vm.prank(SECOND_USER);
        lolFantasy.joinSeason{value: JOINING_FEE}();

        vm.expectEmit(true, false, false, false);
        // because this is a test environment, the values are deterministic and the USER always win
        emit WinnerSelected(USER);
        vm.prank(USER);
        lolFantasy.competeSeason();
    }

    function test_PrizeIsGivenToWinner()
        public
        midLanerCreated
        fulfillRandomWords(1)
        midLanerCreatedAndFulfillRandomWords(SECOND_USER, 2)
    {
        vm.prank(USER);
        lolFantasy.joinSeason{value: JOINING_FEE}();

        vm.prank(SECOND_USER);
        lolFantasy.joinSeason{value: JOINING_FEE}();

        uint256 initialBalance = USER.balance;

        vm.prank(USER);
        lolFantasy.competeSeason();

        uint256 finalBalance = USER.balance;

        assertEq(finalBalance, initialBalance + JOINING_FEE * 2);
    }

    function test_GameStateIsChangedToOpenAfterAllIsDone()
        public
        midLanerCreated
        fulfillRandomWords(1)
        midLanerCreatedAndFulfillRandomWords(SECOND_USER, 2)
    {
        vm.prank(USER);
        lolFantasy.joinSeason{value: JOINING_FEE}();

        vm.prank(SECOND_USER);
        lolFantasy.joinSeason{value: JOINING_FEE}();

        vm.prank(USER);
        lolFantasy.competeSeason();

        assertEq(uint256(lolFantasy.getGameState()), 0);
    }
}
