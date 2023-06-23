// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { Test, console2 } from "forge-std/Test.sol";
import { HatsModule, HatsModuleFactory, IHats, Deploy } from "../script/HatsModuleFactory.s.sol";
import { ERC20 } from "@openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { ERC20EligibilityModule } from "src/ERC20EligibilityModule.sol";

contract MintableERC20 is ERC20 {
  constructor() ERC20("Test Token", "TT") { }

  function mint(address to, uint256 amount) public {
    _mint(to, amount);
  }
}

contract ERC20EligibilityModuleTest is Deploy, Test {
  string public FACTORY_VERSION = "test factory";
  uint256 public MIN_BALANCE = 1;
  address[] public addresses = [address(1), address(2), address(3)];

  ERC20EligibilityModule public moduleInstance;
  MintableERC20 public mintableERC20;
  ERC20EligibilityModule public erc20Module;

  function setUp() external {
    //deploy HatsModuleFactory
    Deploy.prepare(FACTORY_VERSION, false); // set to true to log deployment addresses
    Deploy.run();

    //deploy ERC20 contract & mint to test addresses
    mintableERC20 = new MintableERC20();
    mintableERC20.mint(addresses[1], 1);
    mintableERC20.mint(addresses[2], 2);

    //deploy ERC20HatsEligbilityModule implementation
    erc20Module = new ERC20EligibilityModule("test implementation");

    //create ERC20HatsEligbilityModule instance
    moduleInstance = ERC20EligibilityModule(
      factory.createHatsModule(address(erc20Module), 0, abi.encodePacked(address(mintableERC20), MIN_BALANCE), "")
    );
  }

  function testImmutableArgs() external {
    assertEq(moduleInstance.TOKEN_ADDRESS(), address(mintableERC20), "incorrect token address");
    assertEq(moduleInstance.MIN_BALANCE(), MIN_BALANCE, "incorrect min balance");
  }

  function testIneligibleWearer() external {
    (bool eligible,) = moduleInstance.getWearerStatus(addresses[0], 0);
    assertEq(eligible, false, "addresses[0] should be ineligible");
  }

  function testEligibleWearers() external {
    (bool eligible,) = moduleInstance.getWearerStatus(addresses[1], 0);
    assertEq(eligible, true, "addresses[1] should be eligible");
    (eligible,) = moduleInstance.getWearerStatus(addresses[2], 0 );
    assertEq(eligible, true, "addresses[2] should be eligible");
  }
}
