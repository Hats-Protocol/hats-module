// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import { console2 } from "forge-std/Test.sol"; // remove before deploy
import { HatsEligibilityModule } from "src/HatsEligibilityModule.sol";
import { HatsModule } from "src/HatsModule.sol";
import { IERC721 } from "@openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

//Hats Eligibility Module that currently checks if addresses meet a minimum balance of a preset ERC721 token
contract ERC721EligibilityModule is HatsEligibilityModule {
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
   * 72      | TOKEN_ADDRESS   | address | 20      |                     |
   * 92      | MIN_BALANCE     | uint256 | 32      |                     |
   * --------------------------------------------------------------------+
   */

  /// The address of the ERC721 contract used to check eligibility
  function TOKEN_ADDRESS() public pure returns (address) {
    return _getArgAddress(72);
  }

  /// The minimum token balance required to be eligible
  function MIN_BALANCE() public pure returns (uint256) {
    return _getArgUint256(92);
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
    uint256 balance = IERC721(TOKEN_ADDRESS()).balanceOf(_wearer);
    eligible = balance >= MIN_BALANCE() ? true : false;

    standing = true;
  }
}
