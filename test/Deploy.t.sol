// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {DeployScript} from "../script/Deploy.s.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";
import {TestNFT} from "../src/TestNFT.sol";
import {TestToken} from "../src/TestToken.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

contract DeployTest is Test {
    using Strings for address;

    DeployScript deployer;

    function setUp() public {
        deployer = new DeployScript();
    }

    function testDeploy() public {
        // Set up environment variables
        vm.setEnv("PRIVATE_KEY", "1234");
        vm.setEnv("DEPLOYER_ADDRESS", vm.toString(address(this)));

        // Run deployment
        deployer.run();

        // Verify contracts were deployed
        assertTrue(deployer.deployed(), "Deployment failed");
    }
} 