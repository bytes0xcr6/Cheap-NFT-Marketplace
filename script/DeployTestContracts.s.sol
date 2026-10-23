// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {TestNFT} from "../src/TestNFT.sol";
import {TestToken} from "../src/TestToken.sol";

contract DeployTestContractsScript is Script {
    function run() external {
        // The broadcaster is supplied by forge --account / --keystore.
        
        vm.startBroadcast();
        TestNFT nft = new TestNFT();
        TestToken token = new TestToken();
        vm.stopBroadcast();

        console.log("TestNFT deployed to:", address(nft));
        console.log("TestToken deployed to:", address(token));
    }
} 