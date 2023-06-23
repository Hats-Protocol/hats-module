// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import { console2 } from "forge-std/Test.sol"; // remove before deploy
import { HatsEligibilityModule } from "src/HatsEligibilityModule.sol";
import { HatsModule } from "src/HatsModule.sol";
import {DecentralistInterface} from "lib/Decentra-List/src/DecentralistInterface.sol";

//Hats Eligibility Module that currently checks if addresses meet a minimum balance of a preset ERC20 token
contract DecentralistEligibilityModule is HatsEligibilityModule {
  /*//////////////////////////////////////////////////////////////
                          PUBLIC CONSTANTS
    //////////////////////////////////////////////////////////////*/

  /**
   * See: https://github.com/Hats-Protocol/hats-module/blob/main/src/HatsModule.sol
   * --------------------------------------------------------------------+
   * CLONE IMMUTABLE "STORAGE"                                           |
   * --------------------------------------------------------------------|
   * Offset  | Constant        | Type    | Length  |                     |
   * --------------------------------------------------------------------|
   * 0       | IMPLEMENTATION  | address | 20      |                     |
   * 20      | HATS            | address | 20      |                     |
   * 40      | hatId           | uint256 | 32      |                     |
   * 72      | LIST_ADDRESS    | address | 20      |                     |
   * --------------------------------------------------------------------+
   */

  /// The address of the ERC20 contract used to check eligibility
  function LIST_ADDRESS() public pure returns (address) {
    return _getArgAddress(72);
  }

  /*//////////////////////////////////////////////////////////////
                                INITIALIZER
    //////////////////////////////////////////////////////////////*/
  function setUp(bytes calldata _initData) public override initializer {
    //not used currently TODO: delete?
  }

  /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
  constructor(string memory _version) HatsModule(_version) { }

  /*//////////////////////////////////////////////////////////////
                        HATS ELIGIBILITY FUNCTION
    //////////////////////////////////////////////////////////////*/
  ///
  function getWearerStatus(
    address _wearer,
    uint256 /*_hatId */
  ) override public view returns (bool eligible, bool standing) {
    eligible = DecentralistInterface(LIST_ADDRESS()).onList(_wearer);

    standing = true;
  }
}
