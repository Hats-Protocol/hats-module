// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { Script, console2 } from "forge-std/Script.sol";
import { HatsEligibilitiesChain } from "../src/HatsEligibilitiesChain.sol";
import { HatsModuleFactory, deployModuleFactory, deployModuleInstance } from "../src/utils/DeployFunctions.sol";

contract DeployImplementation is Script {
  HatsEligibilitiesChain public implementation;
  bytes32 public SALT = keccak256("lets add some salt to this meal");

  // default values
  string public version = "0.2.0"; // increment with each deploy
  bool private verbose = true;

  /// @notice Override default values, if desired
  function prepare(string memory _version, bool _verbose) public {
    version = _version;
    verbose = _verbose;
  }

  function run() public {
    uint256 privKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.rememberKey(privKey);
    vm.startBroadcast(deployer);

    implementation = new HatsEligibilitiesChain{ salt: SALT}(version);

    vm.stopBroadcast();

    if (verbose) {
      console2.log("HatsEligibilitiesChain:", address(implementation));
    }
  }
}

// forge script script/HatsEligibilitiesChain.s.sol:DeployImplementation -f ethereum --broadcast --verify
// forge verify-contract --chain-id 5 --num-of-optimizations 1000000 --watch --constructor-args $(cast abi-encode
// "constructor(string)" "0.1.0") --compiler-version v0.8.18 0xd7c10b09453007993960FE2f92cE497A32059E08
// src/HatsEligibilitiesChain.sol:HatsEligibilitiesChain --etherscan-api-key
