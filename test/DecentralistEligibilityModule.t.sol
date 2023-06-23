// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test, console2} from "forge-std/Test.sol";
import {HatsModule, HatsModuleFactory, IHats, Deploy} from "../script/HatsModuleFactory.s.sol";
import {DecentralistEligibilityModule} from "src/DecentralistEligibilityModule.sol";

// NOTE: this test script does not deploy Decentralist or UMA contracts, soit must be run on Goerli
contract DecentralistElibilityModuleTest is Deploy, Test {
    string public FACTORY_VERSION = "test factory";
    address public LIST_ADDRESS = 0xAA053a550CE30fC4DFe3a75Ee81f14950dA19E61; // Goerli address
    address public ADDRESS_ON_LIST = 0xCA4995E1c7Af0E2713f0130275736Fcc2e7EA553; // Goerli address
    address public ADDRESS_OFF_LIST = address(1);

    DecentralistEligibilityModule public moduleInstance;
    DecentralistEligibilityModule public decentralistModule;

    function setUp() external {
        //deploy HatsModuleFactory
        Deploy.prepare(FACTORY_VERSION, false); // set to true to log deployment addresses
        Deploy.run();

        //deploy DecentralistHatsEligbilityModule implementation
        decentralistModule = new DecentralistEligibilityModule(
            "test implementation"
        );

        //create DecentralistHatsEligbilityModule instance
        moduleInstance = DecentralistEligibilityModule(
            factory.createHatsModule(
                address(decentralistModule),
                0,
                abi.encodePacked(LIST_ADDRESS),
                ""
            )
        );
    }

    function testImmutableArgs() external {
        assertEq(
            moduleInstance.LIST_ADDRESS(),
            LIST_ADDRESS,
            "incorrect token address"
        );
    }

    function testIneligibleWearer() external {
        (bool eligible, ) = moduleInstance.getWearerStatus(ADDRESS_OFF_LIST, 0);
        assertEq(eligible, false, "addresses should be ineligible");
    }

    function testEligibleWearers() external {
        (bool eligible, ) = moduleInstance.getWearerStatus(ADDRESS_ON_LIST, 0);
        assertEq(eligible, true, "addresses should be eligible");
    }
}
