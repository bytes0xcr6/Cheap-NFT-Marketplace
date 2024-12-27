// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

/**
 * @title Test NFT
 * @author 0xCR6 - https://www.0xcr6.dev
 * @dev A simple ERC721 token with open minting functionality
 * @notice This contract is used for testing purposes only - [!] PLEASE DON'T USE IT IN PRODUCTION [!]
 */
contract TestNFT is ERC721 {
    /// @notice Counter for token IDs
    uint256 private _tokenIdCounter;

    constructor() ERC721("TestNFT", "TNFT") {}

    function mint() public {
        _safeMint(msg.sender, _tokenIdCounter);
        _tokenIdCounter++;
    }
} 