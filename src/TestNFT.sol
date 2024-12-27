// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestNFT is ERC721 {
    uint256 private _tokenIdCounter;

    constructor() ERC721("TestNFT", "TNFT") {}

    function mint() public {
        _safeMint(msg.sender, _tokenIdCounter);
        _tokenIdCounter++;
    }
} 