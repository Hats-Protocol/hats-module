// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

abstract contract DecentralistInterface {
    // returns boolean whether address is on list
    function onList(address) external view virtual returns (bool);
}
