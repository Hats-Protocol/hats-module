// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { Test, console2 } from "forge-std/Test.sol";
import { HatsModule, HatsModuleFactory, IHats, Deploy } from "../script/HatsModuleFactory.s.sol";
import { ERC1155 } from "@openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import { ERC1155EligibilityModule } from "src/ERC1155EligibilityModule.sol";

contract MintableERC1155 is ERC1155 {
  constructor() ERC1155("") { }

  function mint(address to, uint256 tokenId, uint256 amount) public {
    _mint(to, tokenId, amount, "");
  }
}

contract ERC1155EligibilityModuleTest is Deploy, Test {
  string public FACTORY_VERSION = "test factory";
  uint256 public TOKEN_ID = 1;
  uint256 public MIN_BALANCE = 1;
  address[] public addresses = [address(1), address(2), address(3)];

  ERC1155EligibilityModule public moduleInstance;
  MintableERC1155 public mintableERC1155;
  ERC1155EligibilityModule public erc1155Module;

  function setUp() external {
    //deploy HatsModuleFactory
    Deploy.prepare(FACTORY_VERSION, false); // set to true to log deployment addresses
    Deploy.run();

    //deploy ERC1155 contract & mint to test addresses
    mintableERC1155 = new MintableERC1155();
    mintableERC1155.mint(addresses[1], TOKEN_ID, 1);
    mintableERC1155.mint(addresses[2], TOKEN_ID, 2);

    //deploy ERC1155HatsEligbilityModule implementation
    erc1155Module = new ERC1155EligibilityModule("test implementation");

    //create ERC1155HatsEligbilityModule instance
    moduleInstance = ERC1155EligibilityModule(
      factory.createHatsModule(address(erc1155Module), 0, abi.encodePacked(address(mintableERC1155), TOKEN_ID, MIN_BALANCE), "")
    );
  }

  function testImmutableArgs() external {
    assertEq(moduleInstance.TOKEN_ADDRESS(), address(mintableERC1155), "incorrect token address");
    assertEq(moduleInstance.TOKEN_ID(), TOKEN_ID, "incorrect token id");
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
