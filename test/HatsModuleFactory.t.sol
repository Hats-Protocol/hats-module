// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, console2 } from "forge-std/Test.sol";
import { HatsModule, HatsModuleFactory, IHats, Deploy } from "../script/HatsModuleFactory.s.sol";
import { LibClone } from "solady/utils/LibClone.sol";

contract HatsModuleFactoryTest is Deploy, Test {
  // variables inhereted from Deploy script
  // HatsModuleFactory public HatsModuleFactory;
  // IHats public constant hats

  // uint256 public fork;
  // uint256 public BLOCK_NUMBER;
  address public implementation;
  address public instance;
  string public FACTORY_VERSION = "test factory";
  string public MODULE_VERSION = "test module";
  uint256 public hat1_1 = 0x0000000100010000000000000000000000000000000000000000000000000000;
  bytes largeBytes =
    abi.encodePacked("This is a fairly large bytes object, but is it really? Yes it is, it's quite large");
  bytes32 maxBytes32 = bytes32(type(uint256).max);
  bytes public otherArgs;
  bytes public initData;
  uint256 public hatId;
  uint256 public saltNonce;

  error HatsModuleFactory_ModuleAlreadyDeployed(
    address implementation, uint256 hatId, bytes otherImmutableArgs, uint256 saltNonce
  );

  event HatsModuleFactory_ModuleDeployed(
    address implementation, address instance, uint256 hatId, bytes otherImmutableArgs, bytes initData, uint256 saltNonce
  );

  function setUp() public virtual {
    // create and activate a fork, at BLOCK_NUMBER
    // fork = vm.createSelectFork(vm.rpcUrl("mainnet"), BLOCK_NUMBER);

    // deploy via the script
    Deploy.prepare(FACTORY_VERSION, false); // set to true to log deployment addresses
    Deploy.run();
  }
}

contract DeployFactory is HatsModuleFactoryTest {
  function test_deploy() public {
    assertEq(address(factory.HATS()), address(hats), "incorrect hats address");
    assertEq(factory.version(), FACTORY_VERSION, "incorrect factory version");
  }
}

/// @notice Harness contract to test HatsModuleFactory's internal functions
contract FactoryHarness is HatsModuleFactory {
  constructor(IHats _hats, string memory _version) HatsModuleFactory(_hats, _version) { }

  function encodeArgs(address _implementation, uint256 _hatId, bytes calldata _otherImmutableArgs)
    public
    view
    returns (bytes memory)
  {
    return _encodeArgs(_implementation, _hatId, _otherImmutableArgs);
  }

  function calculateSalt(bytes memory _args, uint256 _saltNonce) public view returns (bytes32) {
    return _calculateSalt(_args, _saltNonce);
  }

  function getHatsModuleAddress(address _implementation, bytes memory _arg, bytes32 _salt)
    public
    view
    returns (address)
  {
    return _getHatsModuleAddress(_implementation, _arg, _salt);
  }

  function createModule(address _implementation, uint256 _hatId, bytes calldata _otherImmutableArgs, uint256 _saltNonce)
    public
    returns (address)
  {
    // encode the Hats contract adddress and _hatId to pass as immutable args when deploying the clone
    bytes memory args = _encodeArgs(_implementation, _hatId, _otherImmutableArgs);
    // calculate the determinstic address salt based on the args
    bytes32 _salt = _calculateSalt(args, _saltNonce);
    // deploy the clone to the deterministic address
    return LibClone.cloneDeterministic(_implementation, args, _salt);
  }
}

contract InternalTest is HatsModuleFactoryTest {
  FactoryHarness harness;

  function setUp() public virtual override {
    super.setUp();
    // deploy harness
    harness = new FactoryHarness(hats, "this is a test harness");
  }
}

contract Internal_encodeArgs is InternalTest {
  function testFuzz_encodeArgs(address _implementation, uint256 _hatId, bytes memory _otherArgs) public {
    assertEq(
      harness.encodeArgs(_implementation, _hatId, _otherArgs),
      abi.encodePacked(_implementation, hats, _hatId, _otherArgs),
      "incorrect encodeArgs"
    );
  }

  function testFuzz_encodeArgs_0_0_fuzz(bytes memory _otherArgs) public {
    testFuzz_encodeArgs(address(0), 0, _otherArgs);
  }

  function testFuzz_encodeArgs_max_max_fuzz(bytes memory _otherArgs) public {
    testFuzz_encodeArgs(address(type(uint160).max), type(uint256).max, _otherArgs);
  }

  function testFuzz_encodeArgs_1_validHat_fuzz(bytes memory _otherArgs) public {
    testFuzz_encodeArgs(address(1), hat1_1, _otherArgs);
  }

  function testFuzz_encodeArgs_1_fuzz_empty(uint256 _hatId) public {
    testFuzz_encodeArgs(address(1), _hatId, hex"00");
  }

  function testFuzz_encodeArgs_1_fuzz_large(uint256 _hatId) public {
    testFuzz_encodeArgs(address(1), _hatId, largeBytes);
  }
}

contract Internal_calculateSalt is InternalTest {
  function testFuzz_calculateSalt(bytes memory _args, uint256 _saltNonce) public {
    assertEq(
      harness.calculateSalt(_args, _saltNonce),
      keccak256(abi.encodePacked(_args, block.chainid, _saltNonce)),
      "incorrect calculateSalt"
    );
  }

  function test_calculateSalt_0() public {
    testFuzz_calculateSalt(hex"00", 0);
  }

  function test_calculateSalt_large() public {
    testFuzz_calculateSalt(largeBytes, 0);
  }

  function test_calculateSalt_validHat() public {
    testFuzz_calculateSalt(harness.encodeArgs(address(1), hat1_1, hex"00"), 0);
  }
}

contract Internal_getHatsModuleAddress is InternalTest {
  function testFuzz_getHatsModuleAddress(address _implementation, bytes memory _arg, bytes32 _salt) public {
    assertEq(
      harness.getHatsModuleAddress(_implementation, _arg, _salt),
      LibClone.predictDeterministicAddress(_implementation, _arg, _salt, address(harness))
    );
  }

  function test_getHatsModuleAddress_0() public {
    testFuzz_getHatsModuleAddress(address(0), hex"00", hex"00");
  }

  function test_getHatsModuleAddress_large() public {
    testFuzz_getHatsModuleAddress(address(type(uint160).max), largeBytes, maxBytes32);
  }

  function test_getHatsModuleAddress_validHat() public {
    bytes memory args = harness.encodeArgs(address(1), hat1_1, hex"00");
    testFuzz_getHatsModuleAddress(address(1), args, harness.calculateSalt(args, 0));
  }
}

contract Internal_createModule is InternalTest {
  function setUp() public virtual override {
    super.setUp();
    // deploy new implementation
    implementation = address(new HatsModule("test implementation"));
  }

  function test_createModule_1() public {
    hatId = 1;
    otherArgs = hex"01";
    bytes memory args = harness.encodeArgs(implementation, hatId, otherArgs);
    saltNonce = 1;
    instance = harness.createModule(implementation, hatId, otherArgs, saltNonce);
    assertEq(
      address(instance), harness.getHatsModuleAddress(implementation, args, harness.calculateSalt(args, saltNonce))
    );
  }

  function test_createModule_0() public {
    hatId = 0;
    otherArgs = hex"00";
    bytes memory args = harness.encodeArgs(implementation, hatId, otherArgs);
    saltNonce = 1;
    instance = harness.createModule(implementation, hatId, otherArgs, saltNonce);
    assertEq(
      address(instance), harness.getHatsModuleAddress(implementation, args, harness.calculateSalt(args, saltNonce))
    );
  }

  function test_createModule_max() public {
    hatId = type(uint256).max;
    otherArgs = largeBytes;
    bytes memory args = harness.encodeArgs(implementation, hatId, otherArgs);
    saltNonce = 1;
    instance = harness.createModule(implementation, hatId, otherArgs, saltNonce);
    assertEq(
      address(instance), harness.getHatsModuleAddress(implementation, args, harness.calculateSalt(args, saltNonce))
    );
  }

  function test_createModule_validHat() public {
    hatId = hat1_1;
    otherArgs = hex"01";
    bytes memory args = harness.encodeArgs(implementation, hatId, otherArgs);
    saltNonce = 1;
    instance = harness.createModule(implementation, hatId, otherArgs, saltNonce);
    assertEq(
      address(instance), harness.getHatsModuleAddress(implementation, args, harness.calculateSalt(args, saltNonce))
    );
  }

  function test_createModule_redeployWithNewNonce() public {
    hatId = hat1_1;
    otherArgs = hex"01";
    bytes memory args = harness.encodeArgs(implementation, hatId, otherArgs);
    saltNonce = 1;
    instance = harness.createModule(implementation, hatId, otherArgs, saltNonce);
    assertEq(
      address(instance), harness.getHatsModuleAddress(implementation, args, harness.calculateSalt(args, saltNonce))
    );
    // redeploy with a new nonce
    uint256 newNonce = 2;
    address instance2 = harness.createModule(implementation, hatId, otherArgs, newNonce);
    assertEq(instance2, harness.getHatsModuleAddress(implementation, args, harness.calculateSalt(args, newNonce)));
    assertNotEq(instance, instance2);
  }
}

contract WithImplementationTest is HatsModuleFactoryTest {
  function setUp() public virtual override {
    super.setUp();
    // deploy new implementation
    implementation = address(new HatsModule(MODULE_VERSION));
  }
}

contract CreateHatsModule is WithImplementationTest {
  function setUp() public virtual override {
    super.setUp();

    hatId = hat1_1;
    otherArgs = hex"00";
    initData = hex"00";
    saltNonce = 0;
  }

  function test_createHatsModule() public {
    vm.expectEmit(true, true, true, true);
    emit HatsModuleFactory_ModuleDeployed(
      implementation,
      factory.getHatsModuleAddress(implementation, hatId, otherArgs, saltNonce),
      hatId,
      otherArgs,
      initData,
      saltNonce
    );
    instance = factory.createHatsModule(implementation, hatId, otherArgs, initData, saltNonce);

    assertEq(HatsModule(instance).hatId(), hat1_1, "hat");
    assertEq(HatsModule(instance).IMPLEMENTATION(), implementation, "IMPLEMENTATION");
    assertEq(address(HatsModule(instance).HATS()), address(hats), "HATS");
    assertEq(HatsModule(instance).version(), MODULE_VERSION, "version");

    // instance should be initialized even if initData is empty, so Initializable should cause {setUp} to revert
    vm.expectRevert("Initializable: contract is already initialized");
    HatsModule(instance).setUp(initData);
  }

  function test_createHatsModule_alreadyDeployed_reverts() public {
    factory.createHatsModule(implementation, hatId, otherArgs, initData, saltNonce);
    vm.expectRevert(
      abi.encodeWithSelector(
        HatsModuleFactory_ModuleAlreadyDeployed.selector, implementation, hatId, otherArgs, saltNonce
      )
    );
    factory.createHatsModule(implementation, hatId, otherArgs, initData, saltNonce);
  }

  function test_createHatsModule_redeployWithNewNonce() public {
    // initial deploy
    instance = factory.createHatsModule(implementation, hatId, otherArgs, initData, saltNonce);
    assertEq(HatsModule(instance).hatId(), hat1_1, "hat");
    assertEq(HatsModule(instance).IMPLEMENTATION(), implementation, "IMPLEMENTATION");
    assertEq(address(HatsModule(instance).HATS()), address(hats), "HATS");
    assertEq(HatsModule(instance).version(), MODULE_VERSION, "version");

    // try to redeploy with a new nonce
    uint256 newNonce = 1;
    vm.expectEmit(true, true, true, true);
    emit HatsModuleFactory_ModuleDeployed(
      implementation,
      factory.getHatsModuleAddress(implementation, hatId, otherArgs, newNonce),
      hatId,
      otherArgs,
      initData,
      newNonce
    );
    address instance2 = factory.createHatsModule(implementation, hatId, otherArgs, initData, newNonce);
    assertEq(HatsModule(instance2).hatId(), hat1_1, "hat");
    assertEq(HatsModule(instance2).IMPLEMENTATION(), implementation, "IMPLEMENTATION");
    assertEq(address(HatsModule(instance2).HATS()), address(hats), "HATS");
    assertEq(HatsModule(instance2).version(), MODULE_VERSION, "version");
  }
}

contract GetHatsModuleAddress is WithImplementationTest {
  function setUp() public virtual override {
    super.setUp();

    hatId = hat1_1;
    otherArgs = hex"00";
    initData = hex"00";
    saltNonce = 0;
  }

  function test_getHatsModuleAddress_validHat() public {
    bytes memory args = abi.encodePacked(address(implementation), hats, hatId, otherArgs);
    address expected = LibClone.predictDeterministicAddress(
      address(implementation), args, keccak256(abi.encodePacked(args, block.chainid, saltNonce)), address(factory)
    );
    assertEq(factory.getHatsModuleAddress(implementation, hatId, otherArgs, saltNonce), expected);
  }
}

contract Deployed is InternalTest {
  function setUp() public virtual override {
    super.setUp();
    // deploy new implementation
    implementation = address(new HatsModule(MODULE_VERSION));

    hatId = hat1_1;
    otherArgs = hex"00";
    initData = hex"00";
    saltNonce = 0;
  }
  // uses the FactoryHarness version for easy access to the internal _createHatsModule function

  function test_deployed_true() public {
    harness.createHatsModule(implementation, hatId, otherArgs, initData, saltNonce);
    assertTrue(harness.deployed(implementation, hatId, otherArgs, saltNonce));
  }

  function test_deployed_false() public {
    assertFalse(harness.deployed(implementation, hatId, otherArgs, saltNonce));

    harness.createHatsModule(implementation, hatId, otherArgs, initData, saltNonce);
    assertFalse(harness.deployed(implementation, hatId, otherArgs, saltNonce + 1));
  }

  function testFuzz_deployed_false(uint256 _saltNonce) public {
    _saltNonce = bound(_saltNonce, 1, type(uint256).max);

    // deploy with nonce = 0
    harness.createHatsModule(implementation, hatId, otherArgs, initData, 0);

    // expect false for any nonce > 0
    assertFalse(harness.deployed(implementation, hatId, otherArgs, _saltNonce));
  }
}
