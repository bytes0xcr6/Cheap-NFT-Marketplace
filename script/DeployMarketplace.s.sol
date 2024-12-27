// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";

contract DeployMarketplaceScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        NFTMarketplace marketplace = new NFTMarketplace();
        vm.stopBroadcast();

        console.log("NFTMarketplace deployed to:", address(marketplace));
    }
} 