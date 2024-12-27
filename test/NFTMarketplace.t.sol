// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";
import {TestNFT} from "../src/TestNFT.sol";
import {TestToken} from "../src/TestToken.sol";

contract NFTMarketplaceTest is Test, NFTMarketplace {
    NFTMarketplace private marketplace;
    TestNFT private nft;
    TestToken private token;

    uint256 private constant SELLER_PRIVATE_KEY = 1;
    uint256 private constant BUYER_PRIVATE_KEY = 2;
    address private seller;
    address private buyer;
    uint256 private constant INITIAL_BALANCE = 1000 ether;

    function setUp() public {
        seller = vm.addr(SELLER_PRIVATE_KEY);
        buyer = vm.addr(BUYER_PRIVATE_KEY);

        marketplace = new NFTMarketplace();
        nft = new TestNFT();
        token = new TestToken();

        vm.startPrank(seller);
        nft.mint();
        nft.setApprovalForAll(address(marketplace), true);
        vm.stopPrank();

        vm.startPrank(buyer);
        token.mint(buyer, INITIAL_BALANCE);
        token.approve(address(marketplace), type(uint256).max);
        vm.stopPrank();
    }

    function _signListing(
        uint256 listingId,
        uint256 tokenId,
        uint256 amount,
        uint256 deadline
    ) internal view returns (bytes memory) {
        bytes32 listingHash = marketplace.createListingHash(
            listingId,
            address(nft),
            tokenId,
            address(token),
            amount,
            deadline
        );
        bytes32 ethSignedListingHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", listingHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(SELLER_PRIVATE_KEY, ethSignedListingHash);
        return abi.encodePacked(r, s, v);
    }

    function _signBid(
        uint256 listingId,
        uint256 amount,
        uint256 deadline
    ) internal view returns (bytes memory) {
        bytes32 bidHash = marketplace.createBidHash(
            listingId,
            amount,
            deadline
        );
        bytes32 ethSignedBidHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", bidHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(BUYER_PRIVATE_KEY, ethSignedBidHash);
        return abi.encodePacked(r, s, v);
    }

    function testCreateListingHash() public view {
        uint256 listingId = 1;
        uint256 tokenId = 0;
        uint256 minPrice = 1 ether;
        uint256 deadline = block.timestamp + 1 days;

        bytes32 listingHash = marketplace.createListingHash(
            listingId,
            address(nft),
            tokenId,
            address(token),
            minPrice,
            deadline
        );

        assertTrue(listingHash != bytes32(0), "Listing hash should not be empty");
    }

    function testCreateBidHash() public view {
        uint256 listingId = 1;
        uint256 amount = 1 ether;
        uint256 deadline = block.timestamp + 1 days;

        bytes32 bidHash = marketplace.createBidHash(
            listingId,
            amount,
            deadline
        );

        assertTrue(bidHash != bytes32(0), "Bid hash should not be empty");
    }

    function testSettleTrade() public {
        uint256 listingId = 1;
        uint256 tokenId = 0;
        uint256 amount = 1 ether;
        uint256 listingDeadline = block.timestamp + 1 days;
        uint256 bidDeadline = block.timestamp + 1 days;

        bytes memory sellerSignature = _signListing(listingId, tokenId, amount, listingDeadline);
        bytes memory buyerSignature = _signBid(listingId, amount, bidDeadline);

        marketplace.settleTrade(
            listingId,
            address(nft),
            tokenId,
            address(token),
            amount,
            listingDeadline,
            bidDeadline,
            sellerSignature,
            buyerSignature,
            buyer
        );

        assertEq(nft.ownerOf(tokenId), buyer);
        assertEq(token.balanceOf(seller), amount);
        assertEq(token.balanceOf(buyer), INITIAL_BALANCE - amount);
    }

    function testCannotSettleExpiredListing() public {
        uint256 listingId = 1;
        uint256 tokenId = 0;
        uint256 amount = 1 ether;
        uint256 listingDeadline = block.timestamp - 1;
        uint256 bidDeadline = block.timestamp + 1 days;

        bytes memory sellerSignature = _signListing(listingId, tokenId, amount, listingDeadline);
        bytes memory buyerSignature = _signBid(listingId, amount, bidDeadline);

        vm.expectRevert(ListingExpired.selector);
        marketplace.settleTrade(
            listingId,
            address(nft),
            tokenId,
            address(token),
            amount,
            listingDeadline,
            bidDeadline,
            sellerSignature,
            buyerSignature,
            buyer
        );
    }

    function testCannotSettleTradeWithInvalidSignatures() public {
        uint256 listingId = 1;
        uint256 tokenId = 0;
        uint256 amount = 1 ether;
        uint256 listingDeadline = block.timestamp + 1 days;
        uint256 bidDeadline = block.timestamp + 1 days;

        // Sign with wrong key
        bytes32 listingHash = marketplace.createListingHash(
            listingId,
            address(nft),
            tokenId,
            address(token),
            amount,
            listingDeadline
        );
        bytes32 ethSignedListingHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", listingHash));
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(999, ethSignedListingHash);
        bytes memory sellerSignature = abi.encodePacked(r1, s1, v1);

        bytes memory buyerSignature = _signBid(listingId, amount, bidDeadline);

        vm.expectRevert();
        marketplace.settleTrade(
            listingId,
            address(nft),
            tokenId,
            address(token),
            amount,
            listingDeadline,
            bidDeadline,
            sellerSignature,
            buyerSignature,
            buyer
        );
    }

    function testCannotSettleExpiredBid() public {
        uint256 listingId = 1;
        uint256 tokenId = 0;
        uint256 amount = 1 ether;
        uint256 listingDeadline = block.timestamp + 1 days;
        uint256 bidDeadline = block.timestamp - 1; // expired bid

        bytes memory sellerSignature = _signListing(listingId, tokenId, amount, listingDeadline);
        bytes memory buyerSignature = _signBid(listingId, amount, bidDeadline);

        vm.expectRevert(BidExpired.selector);
        marketplace.settleTrade(
            listingId,
            address(nft),
            tokenId,
            address(token),
            amount,
            listingDeadline,
            bidDeadline,
            sellerSignature,
            buyerSignature,
            buyer
        );
    }

    function testCannotReuseSignatures() public {
        uint256 listingId = 1;
        uint256 tokenId = 0;
        uint256 amount = 1 ether;
        uint256 listingDeadline = block.timestamp + 1 days;
        uint256 bidDeadline = block.timestamp + 1 days;

        bytes memory sellerSignature = _signListing(listingId, tokenId, amount, listingDeadline);
        bytes memory buyerSignature = _signBid(listingId, amount, bidDeadline);

        // First trade should succeed
        marketplace.settleTrade(
            listingId,
            address(nft),
            tokenId,
            address(token),
            amount,
            listingDeadline,
            bidDeadline,
            sellerSignature,
            buyerSignature,
            buyer
        );

        // Setup for second attempt
        vm.startPrank(seller);
        nft.mint();
        vm.stopPrank();

        vm.startPrank(buyer);
        token.mint(buyer, amount);
        vm.stopPrank();

        // Second trade with same signatures should fail
        vm.expectRevert(TradeAlreadySettled.selector);
        marketplace.settleTrade(
            listingId,
            address(nft),
            tokenId + 1,
            address(token),
            amount,
            listingDeadline,
            bidDeadline,
            sellerSignature,
            buyerSignature,
            buyer
        );
    }

    function testCannotTransferWithoutApproval() public {
        uint256 listingId = 1;
        uint256 tokenId = 0;
        uint256 amount = 1 ether;
        uint256 listingDeadline = block.timestamp + 1 days;
        uint256 bidDeadline = block.timestamp + 1 days;

        bytes memory sellerSignature = _signListing(listingId, tokenId, amount, listingDeadline);
        bytes memory buyerSignature = _signBid(listingId, amount, bidDeadline);

        // Remove NFT approval
        vm.startPrank(seller);
        nft.setApprovalForAll(address(marketplace), false);
        vm.stopPrank();

        // Updated error expectation for newer OpenZeppelin version
        vm.expectRevert(
            abi.encodeWithSignature(
                "ERC721InsufficientApproval(address,uint256)",
                address(marketplace),
                tokenId
            )
        );
        
        marketplace.settleTrade(
            listingId,
            address(nft),
            tokenId,
            address(token),
            amount,
            listingDeadline,
            bidDeadline,
            sellerSignature,
            buyerSignature,
            buyer
        );
    }

    function testSettleTradeWithInsufficientBalance() public {
        uint256 listingId = 1;
        uint256 tokenId = 0;
        uint256 amount = 1 ether;
        uint256 listingDeadline = block.timestamp + 1 days;
        uint256 bidDeadline = block.timestamp + 1 days;

        bytes memory sellerSignature = _signListing(listingId, tokenId, amount, listingDeadline);
        bytes memory buyerSignature = _signBid(listingId, amount, bidDeadline);

        // Transfer away buyer's tokens
        vm.startPrank(buyer);
        token.transfer(address(0x1), token.balanceOf(buyer));
        vm.stopPrank();

        vm.expectRevert(
            abi.encodeWithSelector(
                InsufficientFunds.selector,
                buyer,
                amount,
                0
            )
        );
        
        marketplace.settleTrade(
            listingId,
            address(nft),
            tokenId,
            address(token),
            amount,
            listingDeadline,
            bidDeadline,
            sellerSignature,
            buyerSignature,
            buyer
        );
    }

    function testSettleTradeWithInsufficientAllowance() public {
        uint256 listingId = 1;
        uint256 tokenId = 0;
        uint256 amount = 1 ether;
        uint256 listingDeadline = block.timestamp + 1 days;
        uint256 bidDeadline = block.timestamp + 1 days;

        bytes memory sellerSignature = _signListing(listingId, tokenId, amount, listingDeadline);
        bytes memory buyerSignature = _signBid(listingId, amount, bidDeadline);

        // Remove marketplace allowance
        vm.startPrank(buyer);
        token.approve(address(marketplace), 0);
        vm.stopPrank();

        vm.expectRevert(
            abi.encodeWithSelector(
                InsufficientAllowance.selector,
                buyer,
                amount,
                0
            )
        );
        
        marketplace.settleTrade(
            listingId,
            address(nft),
            tokenId,
            address(token),
            amount,
            listingDeadline,
            bidDeadline,
            sellerSignature,
            buyerSignature,
            buyer
        );
    }

    function testCheckTradeValidity() public {
        uint256 tokenId = 0;
        uint256 amount = 1 ether;
        
        // Should be valid initially with all approvals
        (bool buyerValid, bool sellerValid) = marketplace.checkTradeValidity(
            buyer,
            seller,
            address(nft),
            tokenId,
            address(token),
            amount
        );
        assertTrue(buyerValid && sellerValid, "Trade should be valid with all approvals");

        // Test invalid cases:
        
        // 1. Remove NFT approval
        vm.startPrank(seller);
        nft.setApprovalForAll(address(marketplace), false);
        vm.stopPrank();

        (buyerValid, sellerValid) = marketplace.checkTradeValidity(
            buyer,
            seller,
            address(nft),
            tokenId,
            address(token),
            amount
        );
        assertTrue(buyerValid, "Buyer should still be valid");
        assertFalse(sellerValid, "Seller should be invalid without NFT approval");

        // Restore NFT approval and remove token approval
        vm.startPrank(seller);
        nft.setApprovalForAll(address(marketplace), true);
        vm.stopPrank();

        vm.startPrank(buyer);
        token.approve(address(marketplace), 0);
        vm.stopPrank();

        (buyerValid, sellerValid) = marketplace.checkTradeValidity(
            buyer,
            seller,
            address(nft),
            tokenId,
            address(token),
            amount
        );
        assertFalse(buyerValid, "Buyer should be invalid without token approval");
        assertTrue(sellerValid, "Seller should still be valid");

        // Restore token approval but remove balance
        vm.startPrank(buyer);
        token.approve(address(marketplace), type(uint256).max);
        token.transfer(address(0x1), token.balanceOf(buyer));
        vm.stopPrank();

        (buyerValid, sellerValid) = marketplace.checkTradeValidity(
            buyer,
            seller,
            address(nft),
            tokenId,
            address(token),
            amount
        );
        assertFalse(buyerValid, "Buyer should be invalid without sufficient balance");
        assertTrue(sellerValid, "Seller should still be valid");

        // Test with wrong NFT owner
        vm.startPrank(buyer);
        token.mint(buyer, amount); // Restore balance
        vm.stopPrank();
 
        (buyerValid, sellerValid) = marketplace.checkTradeValidity(
            buyer,
            address(0x1), // Wrong seller address
            address(nft),
            tokenId,
            address(token),
            amount
        );
        assertTrue(buyerValid, "Buyer should be valid");
        assertFalse(sellerValid, "Seller should be invalid with wrong NFT owner");
    }

    function testCheckTradeValidityWithSingleTokenApproval() public {
        uint256 tokenId = 0;
        uint256 amount = 1 ether;
        
        // Remove blanket approval and set single token approval
        vm.startPrank(seller);
        nft.setApprovalForAll(address(marketplace), false);
        nft.approve(address(marketplace), tokenId);
        vm.stopPrank();

        (bool buyerValid, bool sellerValid) = marketplace.checkTradeValidity(
            buyer,
            seller,
            address(nft),
            tokenId,
            address(token),
            amount
        );
        assertTrue(buyerValid && sellerValid, "Trade should be valid with single token approval");
    }
} 