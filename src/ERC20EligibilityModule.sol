// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import { console2 } from "forge-std/Test.sol"; // remove before deploy
import {HatsEligibilityModule} from "src/HatsEligibilityModule.sol";
import {HatsModule} from "src/HatsModule.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

//Hats Eligibility Module that currently checks if addresses meet a minimum balance of a preset ERC20 token
contract ERC20EligibilityModule is HatsEligibilityModule {
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

    /// The address of the ERC20 contract used to check eligibility
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
    constructor(string memory _version) HatsModule(_version) {}

    /*//////////////////////////////////////////////////////////////
                        HATS ELIGIBILITY FUNCTION
    //////////////////////////////////////////////////////////////*/
    ///
    function getWearerStatus(
        address _wearer,
        uint256 /*_hatId */
    ) public view override returns (bool eligible, bool standing) {
        address token = TOKEN_ADDRESS();
        uint256 balanceOf;
        uint256 minBal = MIN_BALANCE() - 1;
        assembly {
            mstore(0x00, 0x70a08231)
            mstore(0x20, _wearer)
            balanceOf := staticcall(gas(), token, 28, 0x40, 0x00, 0x20)
            balanceOf := mload(0x00)
            if gt(balanceOf, minBal) {
                eligible := 1
            }
        }

        standing = true;
    }
}