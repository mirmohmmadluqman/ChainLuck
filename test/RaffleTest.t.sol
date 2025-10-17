// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from forge-std/Test.sol;
import {Raffle} from "src/Raffle.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;
  
    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deplouContract();
        //Raffle raffle = deployer.run();
    }
}