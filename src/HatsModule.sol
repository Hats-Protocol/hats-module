// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import { console2 } from "forge-std/Test.sol"; // remove before deploy
import { IHats } from "hats-protocol/Interfaces/IHats.sol";
import { Clone } from "solady/utils/Clone.sol";
import { Initializable } from "@openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

contract HatsModule is Clone, Initializable {
  /*//////////////////////////////////////////////////////////////
                          PUBLIC CONSTANTS
  //////////////////////////////////////////////////////////////*/

  /**
   * This contract is a clone with immutable args, which means that it is deployed with a set of
   * immutable storage variables (ie constants). Accessing these constants is cheaper than accessing
   * regular storage variables (such as those set on initialization of a typical EIP-1167 clone),
   * but requires a slightly different approach since they are read from calldata instead of storage.
   *
   * Below is a table of constants and their location.
   *
   * For more, see here: https://github.com/Saw-mon-and-Natalie/clones-with-immutable-args
   *
   * --------------------------------------------------------------------+
   * CLONE IMMUTABLE "STORAGE"                                           |
   * --------------------------------------------------------------------|
   * Offset  | Constant        | Type    | Length  |                     |
   * --------------------------------------------------------------------|
   * 0       | IMPLEMENTATION  | address | 20      |                     |
   * 20      | HATS            | address | 20      |                     |
   * 40      | hatId           | uint256 | 32      |                     |
   * 72+     | [other args]    | [type]  | [len]   |                     |
   * --------------------------------------------------------------------+
   */

  /// @notice The address of the implementation contract of which this instance is a clone
  function IMPLEMENTATION() public pure returns (address) {
    return _getArgAddress(0);
  }

  /// @notice Hats Protocol address
  function HATS() public pure returns (IHats) {
    return IHats(_getArgAddress(20));
  }

  /// @notice The hat id for which this HatsModule instance has been deployed
  function hatId() public pure returns (uint256) {
    return _getArgUint256(40);
  }

  /// @notice The version of this HatsModule
  /// @dev Used only for the implementation contract; for clones, use {version}
  string public version_;

  /// @notice The version of this HatsModule
  function version() public view returns (string memory) {
    return HatsModule(IMPLEMENTATION()).version_();
  }

  /*//////////////////////////////////////////////////////////////
                            INITIALIZER
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Sets up this instance with initial operational values (`_initData`)
   * @dev This function can only be called once, on initialization
   * @param _initData Data to set up initial operational values for this instance
   */
  function setUp(bytes memory _initData) public virtual initializer { }

  /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

  /// @notice Deploy the implementation contract and set its version
  /// @dev This is only used to deploy the implementation contract, and should not be used to deploy clones
  constructor(string memory _version) {
    version_ = _version;
    // prevent the implementation contract from being initialized
    _disableInitializers();
  }
}
