// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol"; 

/**
 * @notice A simple ERC20 token used for testing the NFT marketplace
 * @dev Implements basic minting functionality with no restrictions
 * @author 0xCR6 - https://www.0xcr6.dev
 */
contract TestToken is ERC20 {
    /**
     * @notice Initializes the contract with name "TestToken" and symbol "TT"
     * @dev Mints initial supply to deployer
     */
    constructor() ERC20("TestToken", "TT") {
        _mint(msg.sender, 1000000 * 10**decimals());
    }

    /**
     * @notice Mints new tokens to a specified address
     * @param to The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
} 