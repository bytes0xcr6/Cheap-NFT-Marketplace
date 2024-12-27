// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol"; 

/**
 * @title Test Token
 * @author 0xCR6 - https://www.0xcr6.dev
 * @dev A simple ERC20 token with open minting functionality
 * @notice This contract is used for testing purposes only - [!] PLEASE DON'T USE IT IN PRODUCTION [!]
 */
contract TestToken is ERC20 {
    constructor() ERC20("TestToken", "TT") {
        _mint(msg.sender, 1000000 * 10**decimals());
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
} 