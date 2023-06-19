// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { Test, console2 } from "forge-std/Test.sol";
import { HatsModule, HatsModuleFactory, IHats, Deploy } from "../script/HatsModuleFactory.s.sol";
import { ERC721 } from "@openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import { ERC721HatsEligibilityModule } from "src/ERC721HatsEligibilityModule.sol";

contract MintableERC721 is ERC721 {
  constructor() ERC721("Test NFT", "TNFT") { }

  function mint(address to, uint256 tokenId) public {
    _mint(to, tokenId);
  }
}

contract ERC721HatsElibilityModule is Deploy, Test {
  string public FACTORY_VERSION = "test factory";
  uint256 public MIN_BALANCE = 1;
  address[] public addresses = [address(1), address(2), address(3)];

  ERC721HatsEligibilityModule public moduleInstance;
  MintableERC721 public mintableERC721;
  ERC721HatsEligibilityModule public erc721Module;

  function setUp() external {
    //deploy HatsModuleFactory
    Deploy.prepare(FACTORY_VERSION, false); // set to true to log deployment addresses
    Deploy.run();

    //deploy ERC721 contract & mint to test addresses
    mintableERC721 = new MintableERC721();
    mintableERC721.mint(addresses[1], 1);
    mintableERC721.mint(addresses[2], 2);
    mintableERC721.mint(addresses[2], 3);

    //deploy ERC721HatsEligbilityModule implementation
    erc721Module = new ERC721HatsEligibilityModule("test implementation");

    //create ERC721HatsEligbilityModule instance
    moduleInstance = ERC721HatsEligibilityModule(
      factory.createHatsModule(address(erc721Module), 0, abi.encodePacked(address(mintableERC721), MIN_BALANCE), "")
    );
  }

  function testImmutableArgs() external {
    assertEq(moduleInstance.TOKEN_ADDRESS(), address(mintableERC721), "incorrect token address");
    assertEq(moduleInstance.MIN_BALANCE(), MIN_BALANCE, "incorrect token address");
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
