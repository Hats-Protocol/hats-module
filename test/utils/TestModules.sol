// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//import { console2 } from "forge-std/Test.sol";
import { HatsEligibilityModule } from "../../src/HatsEligibilityModule.sol";
import { HatsToggleModule } from "../../src/HatsToggleModule.sol";
import { HatsModule } from "../../src/HatsModule.sol";

contract TestEligibilityAlwaysEligible is HatsEligibilityModule {
  constructor(string memory _version) HatsModule(_version) { }

  function getWearerStatus(address, /* _wearer */ uint256 /* _hatId */ )
    public
    pure
    override
    returns (bool eligible, bool standing)
  {
    return (true, true);
  }
}

contract TestEligibilityAlwaysNotEligible is HatsEligibilityModule {
  constructor(string memory _version) HatsModule(_version) { }

  function getWearerStatus(address, /* _wearer */ uint256 /* _hatId */ )
    public
    pure
    override
    returns (bool eligible, bool standing)
  {
    return (false, true);
  }
}

contract TestEligibilityAlwaysBadStanding is HatsEligibilityModule {
  constructor(string memory _version) HatsModule(_version) { }

  function getWearerStatus(address, /* _wearer */ uint256 /* _hatId */ )
    public
    pure
    override
    returns (bool eligible, bool standing)
  {
    return (false, false);
  }
}

contract TestEligibilityOnlyBadStanding is HatsEligibilityModule {
  constructor(string memory _version) HatsModule(_version) { }

  function getWearerStatus(address, /* _wearer */ uint256 /* _hatId */ )
    public
    pure
    override
    returns (bool eligible, bool standing)
  {
    return (true, false);
  }
}

contract TestToggleAlwaysActive is HatsToggleModule {
  constructor(string memory _version) HatsModule(_version) { }

  function getHatStatus(uint256) public pure override returns (bool) {
    return true;
  }
}

contract TestToggleAlwaysNotActive is HatsToggleModule {
  constructor(string memory _version) HatsModule(_version) { }

  function getHatStatus(uint256) public pure override returns (bool) {
    return false;
  }
}
