// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IHats } from "hats-protocol/Interfaces/IHats.sol";

interface IHatsModule {
  /// @notice Hats Protocol address
  function HATS() external view returns (IHats);

  /// @notice The address of the implementation contract of which this instance is a clone
  function IMPLEMENTATION() external view returns (address);

  /// @notice The hat id for which this HatsModule instance has been deployed
  function hatId() external view returns (uint256);

  /**
   * @notice Sets up this instance with initial operational values (`_initData`)
   * @dev This function can only be called once, on initialization
   * @param _initData Data to set up initial operational values for this instance
   */
  function setUp(bytes memory _initData) external;

  /// @notice The version of this HatsModule
  /// @dev Used only for the implementation contract; for clones, use {version}
  function version_() external view returns (string memory);

  /// @notice The version of this HatsModule
  function version() external view returns (string memory);
}
