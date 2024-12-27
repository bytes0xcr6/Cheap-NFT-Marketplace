// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract NFTMarketplace {
    using ECDSA for bytes32;

    struct Listing {
        address nftContract;
        uint256 tokenId;
        address erc20Token;
        uint256 minPrice;
        address seller;
        uint256 deadline;
    }

    struct Bid {
        address bidder;
        uint256 amount;
        uint256 listingId;
        uint256 deadline;
    }

    mapping(bytes32 => bool) public usedSignatures;
    uint256 public listingCounter;

    event ListingCreated(
        uint256 indexed listingId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 minPrice
    );

    event TradeSettled(
        uint256 indexed listingId,
        address indexed seller,
        address indexed buyer,
        uint256 amount
    );

    function createListingHash(
        uint256 listingId,
        address nftContract,
        uint256 tokenId,
        address erc20Token,
        uint256 minPrice,
        uint256 deadline
    ) public pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                listingId,
                nftContract,
                tokenId,
                erc20Token,
                minPrice,
                deadline
            )
        );
    }

    function createBidHash(
        uint256 listingId,
        uint256 amount,
        uint256 deadline
    ) public pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                listingId,
                amount,
                deadline
            )
        );
    }

    function settleTrade(
        uint256 listingId,
        address nftContract,
        uint256 tokenId,
        address erc20Token,
        uint256 amount,
        uint256 listingDeadline,
        uint256 bidDeadline,
        bytes memory sellerSignature,
        bytes memory buyerSignature,
        address buyer
    ) external {
        require(block.timestamp <= listingDeadline, "Listing expired");
        require(block.timestamp <= bidDeadline, "Bid expired");

        bytes32 listingHash = createListingHash(
            listingId,
            nftContract,
            tokenId,
            erc20Token,
            amount,
            listingDeadline
        );
        
        bytes32 bidHash = createBidHash(
            listingId,
            amount,
            bidDeadline
        );

        address seller = listingHash.toEthSignedMessageHash().recover(sellerSignature);
        require(
            bidHash.toEthSignedMessageHash().recover(buyerSignature) == buyer,
            "Invalid buyer signature"
        );

        bytes32 tradeHash = keccak256(abi.encodePacked(sellerSignature, buyerSignature));
        require(!usedSignatures[tradeHash], "Trade already settled");
        usedSignatures[tradeHash] = true;

        // Transfer NFT from seller to buyer
        IERC721(nftContract).transferFrom(seller, buyer, tokenId);
        
        // Transfer tokens from buyer to seller
        require(
            IERC20(erc20Token).transferFrom(buyer, seller, amount),
            "Token transfer failed"
        );

        emit TradeSettled(listingId, seller, buyer, amount);
    }
} 