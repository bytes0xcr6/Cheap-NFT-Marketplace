// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

/**
 * @notice A simple ERC721 token used for testing the NFT marketplace
 * @dev Implements basic minting functionality with no restrictions
 * @author 0xCR6 - https://www.0xcr6.dev
 */
contract TestNFT is ERC721 {
    /**
     * @notice Counter for token IDs
     * @dev Increments with each new mint to ensure unique IDs
     */
    uint256 private _tokenIdCounter;

    /**
     * @notice Initializes the contract with name "TestNFT" and symbol "TNFT"
     */
    constructor() ERC721("TestNFT", "TNFT") {}

    /**
     * @notice Mints a new NFT to the caller's address
     * @dev Uses a counter to assign unique token IDs
     */
    function mint() public {
        _safeMint(msg.sender, _tokenIdCounter);
        _tokenIdCounter++;
    }
} 