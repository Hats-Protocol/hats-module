// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IHatsModuleFactory {
  function deployModule(uint256 _hatId, address _hat, bytes calldata _initData, uint256 _saltNonce)
    external
    returns (address);
}
