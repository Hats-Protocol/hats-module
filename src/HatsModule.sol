// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import { console2 } from "forge-std/Test.sol"; // remove before deploy
import { IHats } from "hats-protocol/Interfaces/IHats.sol";
import { IHatsModule } from "./interfaces/IHatsModule.sol";
import { Initializable } from "@openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

contract HatsModule is IHatsModule {
  address zkImplementation;
  IHats zkHats;
  uint256 zkHatId;

  /// @inheritdoc IHatsModule
  function IMPLEMENTATION() public pure returns (address) {
    return address(0);
  }

  /// @inheritdoc IHatsModule
  function HATS() public pure returns (IHats) {
    return IHats(address(0));
  }

  /// @inheritdoc IHatsModule
  function hatId() public pure returns (uint256) {
    return 0;
  }

  /// @inheritdoc IHatsModule
  string public version_;

  /// @inheritdoc IHatsModule
  function version() public view returns (string memory) {
    return HatsModule(IMPLEMENTATION()).version_();
  }

  /*//////////////////////////////////////////////////////////////
                            INITIALIZER
  //////////////////////////////////////////////////////////////*/

  /// @inheritdoc IHatsModule
  function setUp(bytes calldata _initData) public {
    _setUp(_initData);
  }

  /// @dev Override this function to set initial operational values for module instances
  function _setUp(bytes calldata _initData) internal virtual { }

  /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

  /// @notice Deploy the implementation contract and set its version
  /// @dev This is only used to deploy the implementation contract, and should not be used to deploy clones
  constructor(string memory _version) {
    version_ = _version;
  }
}
