// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Script, console2 } from "forge-std/Script.sol";

contract Deploy is Script {
  bytes32 public SALT = bytes32(abi.encode(0x4a75)); // ~ H(4) A(a) T(7) S(5)

  // default values
  string public version = "0.6.0"; // increment with each deploy
  bool private verbose = true;

  /// @notice Override default values, if desired
  function prepare(string memory _version, bool _verbose) public {
    version = _version;
    verbose = _verbose;
  }

  function run() public {
    //uint256 privKey = vm.envUint("PRIVATE_KEY");
    vm.startBroadcast();


     // factory = new HatsModuleFactory(hats, version);
	 // console2.logAddress(address(factory));

     vm.stopBroadcast();

  //   if (verbose) {
  //     console2.log("HatsModuleFactory:", address(factory));
  //   }
   }
}

// forge script script/Deploy.s.sol -f ethereum --broadcast --verify
