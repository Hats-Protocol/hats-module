// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import { console2 } from "forge-std/Test.sol"; // remove before deploy
import { HatsModule } from "./HatsModule.sol";
import { HatsEligibilityModule } from "./HatsEligibilityModule.sol";

abstract contract HatsEligibilitiesChain is HatsEligibilityModule {
  /*//////////////////////////////////////////////////////////////
                          PUBLIC  CONSTANTS
    //////////////////////////////////////////////////////////////*/

  /**
   * This contract is a clone with immutable args, which means that it is deployed with a set of
   * immutable storage variables (ie constants). Accessing these constants is cheaper than accessing
   * regular storage variables (such as those set on initialization of a typical EIP-1167 clone),
   * but requires a slightly different approach since they are read from calldata instead of storage.
   *
   * Below is a table of constants and their locations. In this module, all are inherited from HatsModule.
   *
   * For more, see here: https://github.com/Saw-mon-and-Natalie/clones-with-immutable-args
   *
   * ------------------------------------------------------------------------------------------------------------------+
   * CLONE IMMUTABLE "STORAGE"                                                                                         |
   * ------------------------------------------------------------------------------------------------------------------|
   * Offset                          | Constant                  | Type      | Length                     | Source     |
   * -----------------------------------------------------------------------------------------------------|------------|
   * 0                               | IMPLEMENTATION            | address   | 20                         | HatsModule |
   * 20                              | HATS                      | address   | 20                         | HatsModule |
   * 40                              | hatId                     | uint256   | 32                         | HatsModule |
   * 72                              | NUM_CONJUCTION_CLAUSES    | uint256   | 32                         | this       |
   * 104                             | CONJUCTION_CLAUSE_LENGTHS | uint256[] | NUM_CONJUCTION_CLAUSES* 32 | this       |
   * 104+(NUM_CONJUCTION_CLAUSES*32) | MODULES                   | address[] | NUM_MODULES * 20           | this       |
   * ------------------------------------------------------------------------------------------------------------------+
   */

  function NUM_CONJUCTION_CLAUSES() public pure returns (uint256) {
    return _getArgUint256(72);
  }

  function CONJUCTION_CLAUSE_LENGTHS() public pure returns (uint256[] memory) {
    return _getArgUint256Array(104, NUM_CONJUCTION_CLAUSES());
  }

  function MODULES() public pure returns (address[] memory) {
    uint256[] memory lengths = CONJUCTION_CLAUSE_LENGTHS();
    uint256 numClauses = lengths.length;
    uint256 numModules;
    for (uint256 i = 0; i < numClauses;) {
      numModules += lengths[i];

      unchecked {
        ++i;
      }
    }

    address[] memory modules = new address[](numModules);
    uint256 modulesStart = 104 + numClauses * 32;
    for (uint256 i = 0; i < numModules;) {
      modules[i] = _getArgAddress(modulesStart + 20 * i);

      unchecked {
        ++i;
      }
    }
    return modules;
  }

  /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
  /**
   * @notice Deploy the HatsEligibilitiesChain implementation contract and set its version
   * @dev This is only used to deploy the implementation contract, and should not be used to deploy clones
   */
  constructor(string memory _version) HatsModule(_version) { }

  function getWearerStatus(address _wearer, uint256 _hatId)
    public
    view
    virtual
    override
    returns (bool eligible, bool standing)
  {
    uint256 numClauses = NUM_CONJUCTION_CLAUSES();
    uint256 modulesStart = 104 + 32 * numClauses;
    uint256 clauseOffset = 0;

    for (uint256 i = 0; i < numClauses;) {
      uint256 length = _getArgUint256(104 + i * 32);

      bool standingInClause = true;
      bool eligibleInClause = true;
      for (uint256 j = 0; j < length;) {
        address module = _getArgAddress(modulesStart + clauseOffset + 20 * j);
        (bool eligibleInModule, bool standingInModule) = HatsEligibilityModule(module).getWearerStatus(_wearer, _hatId);

        if (!eligibleInModule) {
          eligibleInClause = false;
          break;
        }

        unchecked {
          ++j;
        }
      }

      if (eligibleInClause) {
        return (true, true);
      }

      clauseOffset += length * 20;

      unchecked {
        ++i;
      }
    }
  }
}
