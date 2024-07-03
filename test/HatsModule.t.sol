// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, console2 } from "forge-std/Test.sol";
import { HatsModule, IHats } from "../src/HatsModule.sol";

contract HatsModuleTest is Test {
  event HatsModuleHarness_SetUp(bytes initData);

  string public MODULE_VERSION = "test module";
  address hatAddress = makeAddr("this is a hat address");
  uint256 hatId = 1;
  HatsModule public hatsModule;
  bytes largeBytes =
    abi.encodePacked("This is a fairly large bytes object, but is it really? Yes it is, it's quite large");
  uint256 public largeBytesLength = largeBytes.length;

  function _deployModule(string memory _moduleVersion, address _hatAddress, uint256 _hatId) public virtual {
    // deploy a new HatsModule to be tested by the test contracts below
    hatsModule = new HatsModule(_moduleVersion, _hatAddress, _hatId);
  }

  function testFuzz_version(string memory _version) public {
    _deployModule(_version, hatAddress, hatId);
    hatsModule.setUp(abi.encode("another setUp attempt"));
    assertEq(hatsModule.version(), _version, "incorrect module version");
  }

  function testFuzz_hatAddress(address _hatAddress) public {
    _deployModule(MODULE_VERSION, _hatAddress, hatId);
    hatsModule.setUp(abi.encode("another setUp attempt"));
    assertEq(address(hatsModule.HATS()), _hatAddress, "incorrect hat address");
  }

  function testFuzz_hatId(uint256 _hatId) public {
    _deployModule(MODULE_VERSION, hatAddress, _hatId);
    hatsModule.setUp(abi.encode("another setUp attempt"));
    assertEq(hatsModule.hatId(), _hatId, "incorrect hat id");
  }

  function test_setUpCannotBeCalledTwice() public {
    hatsModule = new HatsModule(MODULE_VERSION, hatAddress, hatId);
    hatsModule.setUp(abi.encode("another setUp attempt"));
    vm.expectRevert(HatsModule.AlreadyInitialized.selector);
    hatsModule.setUp(abi.encode("another setUp attempt"));
  }
}
