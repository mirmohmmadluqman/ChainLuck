    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.19;

    import {VRFConsumerBaseV2Plus} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
    import {VRFV2PlusClient} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
    import {VRFCoordinatorV2_5Mock} from "../lib/chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

    /*
    * @title RAFFLE_LOTTERY
    * @author Mir Mohmmad Luqman
    * @notice This contract is created for sample raffle lottery.
    * @dev Implements Chainlink VRFv2.5
    *
    */

    contract Raffle is VRFConsumerBaseV2Plus {
        // Errors --------------------------------------------------------------------------------------------------
        error NotEnoughEthEntered();
        error TransferFailed();
        error TimeNotPassed();
        error RaffleNotOpen();
        error Raffle___UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState); 

        // events --------------------------------------------------------------------------------------------------
        event RaffleEntered(address indexed player);
        event WinnerPicked(address indexed winner);


        // Type Declarations ----------------------------------------------------------------------------------------
        enum RaffleState {
            Open,          // 0
            Calculating    // 1
        }


        // State Variables -------------------------------------------------------------------------------------------
        uint16 private constant REQUREST_CONFIRMATIONS = 3;
        uint32 private constant NUMWORDS = 1; // Number of random words we want to get
        address payable[] private s_players;
        address public s_recentWinner;
        uint256 private s_lastTimeStamp;
        uint256 public immutable I_ENTRANCEFEE; // Minimum ETH to enter the raffle
        bytes32 private immutable I_KEYHASH; // Gas lane key hash
        uint256 private immutable I_SUBSCRIPTIONID;
        uint256 private immutable I_INTERVAL; // Time interval for the raffle to end
        uint32 private immutable I_CALLBACKGASLIMIT;
        RaffleState private s_raffleState; // To track the state of the raffle
        



        // Modifiers --------------------------------------------------------------------------------------------------
        constructor(
            uint256 entranceFee,
            uint256 interval,

            address _vrfCoordinator,
            bytes32 gaselane, /*Key Hash*/
            uint256 subscriptionId,
            uint32 callbackGasLimit
        ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
            s_lastTimeStamp = block.timestamp; // s_lastTimeStamp = now, Current Block Time
            I_ENTRANCEFEE = entranceFee;
            I_INTERVAL = interval;
            I_KEYHASH = gaselane;
            I_SUBSCRIPTIONID = subscriptionId;
            I_CALLBACKGASLIMIT = callbackGasLimit;
            s_raffleState = RaffleState.Open;
        
        }

        // Functions -------------------------------------------------------------------------------------------------
        function enterRaffle() external payable {
            // Logic to enter the raffle
            // require(msg.value >= I_ENTRANCEFEE, "Not enough ETH entered!");
            // Don' use ^, it is not Gas Efficient, because we are storing a string here ^\
            // require(msg.value >= I_ENTRANCEFEE, NotEnoughEthEntered());
            // or use ^ if compiler version is => 0.8.26v
            if (msg.value >= I_ENTRANCEFEE) {
                revert NotEnoughEthEntered(); //⛔
            }
            s_players.push(payable(msg.sender)); // Add the player to the players array
            emit RaffleEntered(msg.sender); // Emit the event, that you(msg.sender) had entered the raffle as player

            if (s_raffleState != RaffleState.Open) {
                revert RaffleNotOpen(); //⛔
            }
    
        }


        /**
        * @dev This is the function that the Chainlink Keeper nodes call, if the:
        *       time has passed, 
        *       Lottery is open
                the contract has ETH, 
                implicitly your subscription is funded with LINK,
                and there is at least 1 player, 
                then it will return true
        */
        function checkUpkeep(bytes memory /*checkData*/)
            public 
            view returns
            (bool upkeepNeeded, bytes memory /*performData*/) 

            {
                bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= I_INTERVAL);
                bool isOpen = s_raffleState == RaffleState.Open;
                bool hasBalance = address(this).balance > 0;
                bool hasPlayers = s_players.length > 0;
                upkeepNeeded =  timeHasPassed && isOpen && hasBalance && hasPlayers;
                return (upkeepNeeded, hex""); 
        }

        // 1. Get a random number
        // 2. Use - ^ to pick a winner
        // Be automatically call-able (called)
        function performUpKeep() external {
            // Check to see if the raffle is over, time is enough, or not
            // if ((block.timestamp - s_lastTimeStamp) < I_INTERVAL) {
            //     revert TimeNotPassed(); //⛔
            // }

            (bool upkeepNeeded,) = checkUpkeep ("");

            if (!upkeepNeeded) {
                revert  Raffle___UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState)); //⛔
            }
            s_raffleState = RaffleState.Calculating; 

            VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
                keyHash: I_KEYHASH,
                subId: I_SUBSCRIPTIONID,
                requestConfirmations: REQUREST_CONFIRMATIONS,
                callbackGasLimit: I_CALLBACKGASLIMIT,
                numWords: NUMWORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
            s_vrfCoordinator.requestRandomWords(request);
        }

        function fulfillRandomWords(uint256/* requestId,*/, uint256[] calldata randomWords) internal override {
            
            // Checks

            // Interactions
            uint256 indexOfWinner = randomWords[0] % s_players.length;
            address payable recentWinner = s_players[indexOfWinner];
            s_raffleState = RaffleState.Open;
            s_recentWinner = recentWinner;
            s_players = new address payable[](0); // Reset the players array
            s_lastTimeStamp = block.timestamp; // Reset the last timestamp
            emit WinnerPicked(recentWinner);

            // Effect
                (bool success,) = recentWinner.call{value: address(this).balance}("");
                if (!success){       
                    revert TransferFailed(); //⛔
                }

        }

        // Getter Functions -----------------------------------------------------------------------------------------
        function getEntranceFee() external view returns (uint256) {
            return I_ENTRANCEFEE;   
        }
    }


// 3:20