// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IHatsModuleFactory {
  event ModuleDeployed(
    address implementation, address instance, uint256 hatId, bytes otherImmutableArgs, bytes initData, uint256 saltNonce
  );

  function deployModule(uint256 _hatId, address _hat, bytes calldata _initData, uint256 _saltNonce)
    external
    returns (address);
}
