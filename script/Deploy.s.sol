// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";
import {TestNFT} from "../src/TestNFT.sol";
import {TestToken} from "../src/TestToken.sol";

contract DeployScript is Script {
    bool public deployed;

    function run() external {
        // The broadcaster is supplied by forge --account / --keystore.
        address deployerAddress = vm.envAddress("DEPLOYER_ADDRESS");
        
        // Deploy NFTMarketplace
        vm.startBroadcast();
        NFTMarketplace marketplace = new NFTMarketplace();
        vm.stopBroadcast();
        console.log("NFTMarketplace deployed to:", address(marketplace));

        // Deploy TestNFT
        vm.startBroadcast();
        TestNFT nft = new TestNFT();
        vm.stopBroadcast();
        console.log("TestNFT deployed to:", address(nft));

        // Deploy TestToken
        vm.startBroadcast();
        TestToken token = new TestToken();
        vm.stopBroadcast();
        console.log("TestToken deployed to:", address(token));

        console.log("Deployer address:", deployerAddress);
        deployed = true;
    }
} 