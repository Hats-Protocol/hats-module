// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { Test, console2 } from "forge-std/Test.sol";
import { HatsTogglesChain } from "../src/HatsTogglesChain.sol";
import { IHats, HatsModuleFactory, deployModuleFactory, deployModuleInstance } from "../src/utils/DeployFunctions.sol";
import { DeployImplementation } from "../script/HatsTogglesChain.s.sol";
import { TestToggleAlwaysActive, TestToggleAlwaysNotActive } from "./utils/TestModules.sol";
import { HatsToggleModule } from "../src/HatsToggleModule.sol";
import { Hats } from "hats-protocol/Hats.sol";

contract DeployImplementationTest is DeployImplementation, Test {
  uint256 public fork;
  uint256 public BLOCK_NUMBER = 9_395_052; // the block number where hats module factory was deployed on Goerli;
  Hats public constant HATS = Hats(0x3bc1A0Ad72417f2d411118085256fC53CBdDd137); // v1.hatsprotocol.eth
  HatsModuleFactory constant FACTORY = HatsModuleFactory(0x60f7bE2ffc5672934146713fAe20Df350F21d8E2);

  HatsTogglesChain public instance;
  uint256 public tophat;
  uint256 public chainedToggleHat;
  address public eligibility = makeAddr("eligibility");
  address public toggle = makeAddr("toggle");
  address public dao = makeAddr("dao");
  address public wearer = makeAddr("wearer");

  uint256[] clauseLengths;
  address module1;
  address module2;
  address module3;

  address[] expectedModules;

  function deployInstanceTwoModules(
    uint256 targetHat,
    uint256 numClauses,
    uint256[] memory lengths,
    address _module1,
    address _module2
  ) public returns (HatsTogglesChain) {
    bytes memory otherImmutableArgs = abi.encodePacked(numClauses, lengths, _module1, _module2);
    // deploy the instance
    return HatsTogglesChain(deployModuleInstance(FACTORY, address(implementation), targetHat, otherImmutableArgs, ""));
  }

  function deployInstanceThreeModules(
    uint256 targetHat,
    uint256 numClauses,
    uint256[] memory lengths,
    address _module1,
    address _module2,
    address _module3
  ) public returns (HatsTogglesChain) {
    bytes memory otherImmutableArgs = abi.encodePacked(numClauses, lengths, _module1, _module2, _module3);
    // deploy the instance
    return HatsTogglesChain(deployModuleInstance(FACTORY, address(implementation), targetHat, otherImmutableArgs, ""));
  }

  function setUp() public virtual {
    // create and activate a fork, at BLOCK_NUMBER
    fork = vm.createSelectFork(vm.rpcUrl("goerli"), BLOCK_NUMBER);

    // deploy via the script
    DeployImplementation.prepare(version, false); // set last arg to true to log deployment
    DeployImplementation.run();

    // set up hats
    tophat = HATS.mintTopHat(dao, "tophat", "dao.eth/tophat");
    vm.startPrank(dao);
    chainedToggleHat =
      HATS.createHat(tophat, "chainedToggleHat", 50, eligibility, toggle, true, "dao.eth/chainedToggleHat");
    vm.stopPrank();
  }
}

/**
 * Scenario with 2 modules.
 * Chaining type: module1 || module2
 * Module1 returns true
 * Module2 returns true
 * Expected result: true
 */
contract Setup1 is DeployImplementationTest {
  function setUp() public virtual override {
    super.setUp();

    module1 = address(new TestToggleAlwaysActive("test"));
    module2 = address(new TestToggleAlwaysActive("test"));

    clauseLengths.push(1);
    clauseLengths.push(1);

    instance = deployInstanceTwoModules(chainedToggleHat, 2, clauseLengths, module1, module2);

    // update hat eligibilty to the new instance
    vm.prank(dao);
    HATS.changeHatToggle(chainedToggleHat, address(instance));
  }
}

contract TestSetup1 is Setup1 {
  function setUp() public virtual override {
    super.setUp();
    expectedModules.push(module1);
    expectedModules.push(module2);
  }

  function test_deployImplementation() public {
    assertEq(implementation.version_(), "0.1.0");
  }

  function test_instanceNumClauses() public {
    assertEq(instance.NUM_CONJUCTION_CLAUSES(), uint256(2));
  }

  function test_instanceClauseLengths() public {
    assertEq(instance.CONJUCTION_CLAUSE_LENGTHS(), clauseLengths);
  }

  function test_instanceModules() public {
    assertEq(instance.MODULES(), expectedModules);
  }

  function test_hatStatusInModule() public {
    bool active = instance.getHatStatus(chainedToggleHat);
    assertEq(active, true);
  }

  function test_hatStatusInHats() public {
    bool active = HATS.isActive(chainedToggleHat);
    assertEq(active, true);
  }
}

/**
 * Scenario with 2 modules.
 * Chaining type: module1 || module2
 * Module1 returns false
 * Module2 returns true
 * Expectesd results: true
 */
contract Setup2 is DeployImplementationTest {
  function setUp() public virtual override {
    super.setUp();

    module1 = address(new TestToggleAlwaysNotActive("test"));
    module2 = address(new TestToggleAlwaysActive("test"));

    clauseLengths.push(1);
    clauseLengths.push(1);

    instance = deployInstanceTwoModules(chainedToggleHat, 2, clauseLengths, module1, module2);

    // update hat eligibilty to the new instance
    vm.prank(dao);
    HATS.changeHatToggle(chainedToggleHat, address(instance));
  }
}

contract TestSetup2 is Setup2 {
  function setUp() public virtual override {
    super.setUp();
    expectedModules.push(module1);
    expectedModules.push(module2);
  }

  function test_deployImplementation() public {
    assertEq(implementation.version_(), "0.1.0");
  }

  function test_instanceNumClauses() public {
    assertEq(instance.NUM_CONJUCTION_CLAUSES(), uint256(2));
  }

  function test_instanceClauseLengths() public {
    assertEq(instance.CONJUCTION_CLAUSE_LENGTHS(), clauseLengths);
  }

  function test_instanceModules() public {
    assertEq(instance.MODULES(), expectedModules);
  }

  function test_hatStatusInModule() public {
    bool active = instance.getHatStatus(chainedToggleHat);
    assertEq(active, true);
  }

  function test_hatStatusInHats() public {
    bool active = HATS.isActive(chainedToggleHat);
    assertEq(active, true);
  }
}

/**
 * Scenario with 2 modules.
 * Chaining type: module1 || module2
 * Module1 returns true
 * Module2 returns false
 * Expectesd results: true
 */
contract Setup3 is DeployImplementationTest {
  function setUp() public virtual override {
    super.setUp();

    module1 = address(new TestToggleAlwaysActive("test"));
    module2 = address(new TestToggleAlwaysNotActive("test"));

    clauseLengths.push(1);
    clauseLengths.push(1);

    instance = deployInstanceTwoModules(chainedToggleHat, 2, clauseLengths, module1, module2);

    // update hat eligibilty to the new instance
    vm.prank(dao);
    HATS.changeHatToggle(chainedToggleHat, address(instance));
  }
}

contract TestSetup3 is Setup3 {
  function setUp() public virtual override {
    super.setUp();
    expectedModules.push(module1);
    expectedModules.push(module2);
  }

  function test_deployImplementation() public {
    assertEq(implementation.version_(), "0.1.0");
  }

  function test_instanceNumClauses() public {
    assertEq(instance.NUM_CONJUCTION_CLAUSES(), uint256(2));
  }

  function test_instanceClauseLengths() public {
    assertEq(instance.CONJUCTION_CLAUSE_LENGTHS(), clauseLengths);
  }

  function test_instanceModules() public {
    assertEq(instance.MODULES(), expectedModules);
  }

  function test_hatStatusInModule() public {
    bool active = instance.getHatStatus(chainedToggleHat);
    assertEq(active, true);
  }

  function test_hatStatusInHats() public {
    bool active = HATS.isActive(chainedToggleHat);
    assertEq(active, true);
  }
}

/**
 * Scenario with 2 modules.
 * Chaining type: module1 || module2
 * Module1 returns false
 * Module2 returns false
 * Expectesd results: false
 */
contract Setup4 is DeployImplementationTest {
  function setUp() public virtual override {
    super.setUp();

    module1 = address(new TestToggleAlwaysNotActive("test"));
    module2 = address(new TestToggleAlwaysNotActive("test"));

    clauseLengths.push(1);
    clauseLengths.push(1);

    instance = deployInstanceTwoModules(chainedToggleHat, 2, clauseLengths, module1, module2);

    // update hat eligibilty to the new instance
    vm.prank(dao);
    HATS.changeHatToggle(chainedToggleHat, address(instance));
  }
}

contract TestSetup4 is Setup4 {
  function setUp() public virtual override {
    super.setUp();
    expectedModules.push(module1);
    expectedModules.push(module2);
  }

  function test_deployImplementation() public {
    assertEq(implementation.version_(), "0.1.0");
  }

  function test_instanceNumClauses() public {
    assertEq(instance.NUM_CONJUCTION_CLAUSES(), uint256(2));
  }

  function test_instanceClauseLengths() public {
    assertEq(instance.CONJUCTION_CLAUSE_LENGTHS(), clauseLengths);
  }

  function test_instanceModules() public {
    assertEq(instance.MODULES(), expectedModules);
  }

  function test_hatStatusInModule() public {
    bool active = instance.getHatStatus(chainedToggleHat);
    assertEq(active, false);
  }

  function test_hatStatusInHats() public {
    bool active = HATS.isActive(chainedToggleHat);
    assertEq(active, false);
  }
}

/**
 * Scenario with 2 modules.
 * Chaining type: module1 && module2
 * Module1 returns true
 * Module2 returns true
 * Expectesd results: true
 */
contract Setup5 is DeployImplementationTest {
  function setUp() public virtual override {
    super.setUp();

    module1 = address(new TestToggleAlwaysActive("test"));
    module2 = address(new TestToggleAlwaysActive("test"));

    clauseLengths.push(2);

    instance = deployInstanceTwoModules(chainedToggleHat, 1, clauseLengths, module1, module2);

    // update hat eligibilty to the new instance
    vm.prank(dao);
    HATS.changeHatToggle(chainedToggleHat, address(instance));
  }
}

contract TestSetup5 is Setup5 {
  function setUp() public virtual override {
    super.setUp();
    expectedModules.push(module1);
    expectedModules.push(module2);
  }

  function test_deployImplementation() public {
    assertEq(implementation.version_(), "0.1.0");
  }

  function test_instanceNumClauses() public {
    assertEq(instance.NUM_CONJUCTION_CLAUSES(), uint256(1));
  }

  function test_instanceClauseLengths() public {
    assertEq(instance.CONJUCTION_CLAUSE_LENGTHS(), clauseLengths);
  }

  function test_instanceModules() public {
    assertEq(instance.MODULES(), expectedModules);
  }

  function test_hatStatusInModule() public {
    bool active = instance.getHatStatus(chainedToggleHat);
    assertEq(active, true);
  }

  function test_hatStatusInHats() public {
    bool active = HATS.isActive(chainedToggleHat);
    assertEq(active, true);
  }
}

/**
 * Scenario with 2 modules.
 * Chaining type: module1 && module2
 * Module1 returns false
 * Module2 returns true
 * Expectesd results: false
 */
contract Setup6 is DeployImplementationTest {
  function setUp() public virtual override {
    super.setUp();

    module1 = address(new TestToggleAlwaysNotActive("test"));
    module2 = address(new TestToggleAlwaysActive("test"));

    clauseLengths.push(2);

    instance = deployInstanceTwoModules(chainedToggleHat, 1, clauseLengths, module1, module2);

    // update hat eligibilty to the new instance
    vm.prank(dao);
    HATS.changeHatToggle(chainedToggleHat, address(instance));
  }
}

contract TestSetup6 is Setup6 {
  function setUp() public virtual override {
    super.setUp();
    expectedModules.push(module1);
    expectedModules.push(module2);
  }

  function test_deployImplementation() public {
    assertEq(implementation.version_(), "0.1.0");
  }

  function test_instanceNumClauses() public {
    assertEq(instance.NUM_CONJUCTION_CLAUSES(), uint256(1));
  }

  function test_instanceClauseLengths() public {
    assertEq(instance.CONJUCTION_CLAUSE_LENGTHS(), clauseLengths);
  }

  function test_instanceModules() public {
    assertEq(instance.MODULES(), expectedModules);
  }

  function test_hatStatusInModule() public {
    bool active = instance.getHatStatus(chainedToggleHat);
    assertEq(active, false);
  }

  function test_hatStatusInHats() public {
    bool active = HATS.isActive(chainedToggleHat);
    assertEq(active, false);
  }
}

/**
 * Scenario with 2 modules.
 * Chaining type: module1 && module2
 * Module1 returns true
 * Module2 returns false
 * Expectesd results: false
 */
contract Setup7 is DeployImplementationTest {
  function setUp() public virtual override {
    super.setUp();

    module1 = address(new TestToggleAlwaysActive("test"));
    module2 = address(new TestToggleAlwaysNotActive("test"));

    clauseLengths.push(2);

    instance = deployInstanceTwoModules(chainedToggleHat, 1, clauseLengths, module1, module2);

    // update hat eligibilty to the new instance
    vm.prank(dao);
    HATS.changeHatToggle(chainedToggleHat, address(instance));
  }
}

contract TestSetup7 is Setup7 {
  function setUp() public virtual override {
    super.setUp();
    expectedModules.push(module1);
    expectedModules.push(module2);
  }

  function test_deployImplementation() public {
    assertEq(implementation.version_(), "0.1.0");
  }

  function test_instanceNumClauses() public {
    assertEq(instance.NUM_CONJUCTION_CLAUSES(), uint256(1));
  }

  function test_instanceClauseLengths() public {
    assertEq(instance.CONJUCTION_CLAUSE_LENGTHS(), clauseLengths);
  }

  function test_instanceModules() public {
    assertEq(instance.MODULES(), expectedModules);
  }

  function test_hatStatusInModule() public {
    bool active = instance.getHatStatus(chainedToggleHat);
    assertEq(active, false);
  }

  function test_hatStatusInHats() public {
    bool active = HATS.isActive(chainedToggleHat);
    assertEq(active, false);
  }
}

/**
 * Scenario with 2 modules.
 * Chaining type: module1 && module2
 * Module1 returns false
 * Module2 returns false
 * Expectesd results: false
 */
contract Setup8 is DeployImplementationTest {
  function setUp() public virtual override {
    super.setUp();

    module1 = address(new TestToggleAlwaysNotActive("test"));
    module2 = address(new TestToggleAlwaysNotActive("test"));

    clauseLengths.push(2);

    instance = deployInstanceTwoModules(chainedToggleHat, 1, clauseLengths, module1, module2);

    // update hat eligibilty to the new instance
    vm.prank(dao);
    HATS.changeHatToggle(chainedToggleHat, address(instance));
  }
}

contract TestSetup8 is Setup8 {
  function setUp() public virtual override {
    super.setUp();
    expectedModules.push(module1);
    expectedModules.push(module2);
  }

  function test_deployImplementation() public {
    assertEq(implementation.version_(), "0.1.0");
  }

  function test_instanceNumClauses() public {
    assertEq(instance.NUM_CONJUCTION_CLAUSES(), uint256(1));
  }

  function test_instanceClauseLengths() public {
    assertEq(instance.CONJUCTION_CLAUSE_LENGTHS(), clauseLengths);
  }

  function test_instanceModules() public {
    assertEq(instance.MODULES(), expectedModules);
  }

  function test_hatStatusInModule() public {
    bool active = instance.getHatStatus(chainedToggleHat);
    assertEq(active, false);
  }

  function test_hatStatusInHats() public {
    bool active = HATS.isActive(chainedToggleHat);
    assertEq(active, false);
  }
}

/**
 * Scenario with 3 modules.
 * Chaining type: (module1 && module2) || module3
 * Module1 returns true
 * Module2 returns true
 * Module3 returns true
 * Expectesd results: true
 */
contract Setup9 is DeployImplementationTest {
  function setUp() public virtual override {
    super.setUp();

    module1 = address(new TestToggleAlwaysActive("test"));
    module2 = address(new TestToggleAlwaysActive("test"));
    module3 = address(new TestToggleAlwaysActive("test"));

    clauseLengths.push(2);
    clauseLengths.push(1);

    instance = deployInstanceThreeModules(chainedToggleHat, 2, clauseLengths, module1, module2, module3);

    // update hat eligibilty to the new instance
    vm.prank(dao);
    HATS.changeHatToggle(chainedToggleHat, address(instance));
  }
}

contract TestSetup9 is Setup9 {
  function setUp() public virtual override {
    super.setUp();
    expectedModules.push(module1);
    expectedModules.push(module2);
    expectedModules.push(module3);
  }

  function test_deployImplementation() public {
    assertEq(implementation.version_(), "0.1.0");
  }

  function test_instanceNumClauses() public {
    assertEq(instance.NUM_CONJUCTION_CLAUSES(), uint256(2));
  }

  function test_instanceClauseLengths() public {
    assertEq(instance.CONJUCTION_CLAUSE_LENGTHS(), clauseLengths);
  }

  function test_instanceModules() public {
    assertEq(instance.MODULES(), expectedModules);
  }

  //function test_hatStatusInModule() public {
  //  bool active = instance.getHatStatus(chainedToggleHat);
  //  assertEq(active, true);
  //}

  function test_hatStatusInHats() public {
    bool active = HATS.isActive(chainedToggleHat);
    assertEq(active, true);
  }
}

/**
 * Scenario with 3 modules.
 * Chaining type: (module1 && module2) || module3
 * Module1 returns false
 * Module2 returns true
 * Module3 returns true
 * Expectesd results: true
 */
contract Setup10 is DeployImplementationTest {
  function setUp() public virtual override {
    super.setUp();

    module1 = address(new TestToggleAlwaysNotActive("test"));
    module2 = address(new TestToggleAlwaysActive("test"));
    module3 = address(new TestToggleAlwaysActive("test"));

    clauseLengths.push(2);
    clauseLengths.push(1);

    instance = deployInstanceThreeModules(chainedToggleHat, 2, clauseLengths, module1, module2, module3);

    // update hat eligibilty to the new instance
    vm.prank(dao);
    HATS.changeHatToggle(chainedToggleHat, address(instance));
  }
}

contract TestSetup10 is Setup10 {
  function setUp() public virtual override {
    super.setUp();
    expectedModules.push(module1);
    expectedModules.push(module2);
    expectedModules.push(module3);
  }

  function test_deployImplementation() public {
    assertEq(implementation.version_(), "0.1.0");
  }

  function test_instanceNumClauses() public {
    assertEq(instance.NUM_CONJUCTION_CLAUSES(), uint256(2));
  }

  function test_instanceClauseLengths() public {
    assertEq(instance.CONJUCTION_CLAUSE_LENGTHS(), clauseLengths);
  }

  function test_instanceModules() public {
    assertEq(instance.MODULES(), expectedModules);
  }

  function test_hatStatusInModule() public {
    bool active = instance.getHatStatus(chainedToggleHat);
    assertEq(active, true);
  }

  function test_hatStatusInHats() public {
    bool active = HATS.isActive(chainedToggleHat);
    assertEq(active, true);
  }
}

/**
 * Scenario with 3 modules.
 * Chaining type: (module1 && module2) || module3
 * Module1 returns true)
 * Module2 returns true
 * Module3 returns false
 * Expectesd results: true
 */
contract Setup11 is DeployImplementationTest {
  function setUp() public virtual override {
    super.setUp();

    module1 = address(new TestToggleAlwaysActive("test"));
    module2 = address(new TestToggleAlwaysActive("test"));
    module3 = address(new TestToggleAlwaysNotActive("test"));

    clauseLengths.push(2);
    clauseLengths.push(1);

    instance = deployInstanceThreeModules(chainedToggleHat, 2, clauseLengths, module1, module2, module3);

    // update hat eligibilty to the new instance
    vm.prank(dao);
    HATS.changeHatToggle(chainedToggleHat, address(instance));
  }
}

contract TestSetup11 is Setup11 {
  function setUp() public virtual override {
    super.setUp();
    expectedModules.push(module1);
    expectedModules.push(module2);
    expectedModules.push(module3);
  }

  function test_deployImplementation() public {
    assertEq(implementation.version_(), "0.1.0");
  }

  function test_instanceNumClauses() public {
    assertEq(instance.NUM_CONJUCTION_CLAUSES(), uint256(2));
  }

  function test_instanceClauseLengths() public {
    assertEq(instance.CONJUCTION_CLAUSE_LENGTHS(), clauseLengths);
  }

  function test_instanceModules() public {
    assertEq(instance.MODULES(), expectedModules);
  }

  function test_hatStatusInModule() public {
    bool active = instance.getHatStatus(chainedToggleHat);
    assertEq(active, true);
  }

  function test_hatStatusInHats() public {
    bool active = HATS.isActive(chainedToggleHat);
    assertEq(active, true);
  }
}

/**
 * Scenario with 3 modules.
 * Chaining type: (module1 && module2) || module3
 * Module1 returns false
 * Module2 returns false
 * Module3 returns false
 * Expectesd results: false
 */
contract Setup12 is DeployImplementationTest {
  function setUp() public virtual override {
    super.setUp();

    module1 = address(new TestToggleAlwaysNotActive("test"));
    module2 = address(new TestToggleAlwaysNotActive("test"));
    module3 = address(new TestToggleAlwaysNotActive("test"));

    clauseLengths.push(2);
    clauseLengths.push(1);

    instance = deployInstanceThreeModules(chainedToggleHat, 2, clauseLengths, module1, module2, module3);

    // update hat eligibilty to the new instance
    vm.prank(dao);
    HATS.changeHatToggle(chainedToggleHat, address(instance));
  }
}

contract TestSetup12 is Setup12 {
  function setUp() public virtual override {
    super.setUp();
    expectedModules.push(module1);
    expectedModules.push(module2);
    expectedModules.push(module3);
  }

  function test_deployImplementation() public {
    assertEq(implementation.version_(), "0.1.0");
  }

  function test_instanceNumClauses() public {
    assertEq(instance.NUM_CONJUCTION_CLAUSES(), uint256(2));
  }

  function test_instanceClauseLengths() public {
    assertEq(instance.CONJUCTION_CLAUSE_LENGTHS(), clauseLengths);
  }

  function test_instanceModules() public {
    assertEq(instance.MODULES(), expectedModules);
  }

  function test_hatStatusInModule() public {
    bool active = instance.getHatStatus(chainedToggleHat);
    assertEq(active, false);
  }

  function test_hatStatusInHats() public {
    bool active = HATS.isActive(chainedToggleHat);
    assertEq(active, false);
  }
}

/**
 * Scenario with 3 modules.
 * Chaining type: module1 || module2 || module3
 * Module1 returns true
 * Module2 returns true
 * Module3 returns false
 * Expectesd results: true
 */
contract Setup13 is DeployImplementationTest {
  function setUp() public virtual override {
    super.setUp();

    module1 = address(new TestToggleAlwaysActive("test"));
    module2 = address(new TestToggleAlwaysActive("test"));
    module3 = address(new TestToggleAlwaysNotActive("test"));

    clauseLengths.push(1);
    clauseLengths.push(1);
    clauseLengths.push(1);

    instance = deployInstanceThreeModules(chainedToggleHat, 3, clauseLengths, module1, module2, module3);

    // update hat eligibilty to the new instance
    vm.prank(dao);
    HATS.changeHatToggle(chainedToggleHat, address(instance));
  }
}

contract TestSetup13 is Setup13 {
  function setUp() public virtual override {
    super.setUp();
    expectedModules.push(module1);
    expectedModules.push(module2);
    expectedModules.push(module3);
  }

  function test_deployImplementation() public {
    assertEq(implementation.version_(), "0.1.0");
  }

  function test_instanceNumClauses() public {
    assertEq(instance.NUM_CONJUCTION_CLAUSES(), uint256(3));
  }

  function test_instanceClauseLengths() public {
    assertEq(instance.CONJUCTION_CLAUSE_LENGTHS(), clauseLengths);
  }

  function test_instanceModules() public {
    assertEq(instance.MODULES(), expectedModules);
  }

  function test_hatStatusInModule() public {
    bool active = instance.getHatStatus(chainedToggleHat);
    assertEq(active, true);
  }

  function test_hatStatusInHats() public {
    bool active = HATS.isActive(chainedToggleHat);
    assertEq(active, true);
  }
}
