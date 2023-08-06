// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { HatsEligibilityModule } from "../../src/HatsEligibilityModule.sol";
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
