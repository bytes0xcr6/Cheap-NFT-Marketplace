// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {INFTMarketplace} from "./interfaces/INFTMarketplace.sol";

/**
 * @notice A gas-efficient NFT marketplace that enables trading between ERC721 and ERC20 tokens using off-chain signatures
 * @dev Implements signature-based trading with replay protection and deadline-based expiration
 * @author 0xCR6 - https://www.0xcr6.dev
 */
contract NFTMarketplace is INFTMarketplace {
    /**
     * @notice Tracks used signatures to prevent replay attacks
     * @dev Maps the hash of combined signatures to a boolean indicating if they've been used
     */
    mapping(bytes32 => bool) public usedSignatures;
    
    /**
     * @notice Counter for listing IDs
     * @dev Increments with each new listing to ensure unique IDs
     */
    uint256 public listingCounter;

    /**
     * @notice Creates a hash of the listing parameters that will be signed by the seller
     * @param listingId Unique identifier for the listing
     * @param nftContract Address of the NFT contract
     * @param tokenId ID of the NFT being sold
     * @param erc20Token Address of the ERC20 token used for payment
     * @param minPrice Minimum price in ERC20 tokens
     * @param deadline Timestamp after which the listing expires
     * @return Hash of the listing parameters
     */
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

    /**
     * @notice Creates a hash of the bid parameters that will be signed by the buyer
     * @param listingId ID of the listing being bid on
     * @param amount Amount of ERC20 tokens offered
     * @param deadline Timestamp after which the bid expires
     * @return Hash of the bid parameters
     */
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

    /**
     * @notice Checks if both bid and listing are valid by verifying balances and approvals
     * @param buyer Address of the buyer
     * @param seller Address of the seller
     * @param nftContract Address of the NFT contract
     * @param tokenId ID of the NFT
     * @param erc20Token Address of the payment token
     * @param amount Amount of tokens to be transferred
     * @return buyerValid True if buyer has sufficient balance and approval
     * @return sellerValid True if seller owns the NFT and has given approval
     */
    function checkTradeValidity(
        address buyer,
        address seller,
        address nftContract,
        uint256 tokenId,
        address erc20Token,
        uint256 amount
    ) external view returns (bool buyerValid, bool sellerValid) {
        // Check buyer's token balance and approval
        IERC20 token = IERC20(erc20Token);
        buyerValid = token.balanceOf(buyer) >= amount && 
                     token.allowance(buyer, address(this)) >= amount;
        
        // Check seller's NFT ownership and approval
        IERC721 nft = IERC721(nftContract);
        sellerValid = nft.ownerOf(tokenId) == seller &&
                      (nft.getApproved(tokenId) == address(this) || 
                       nft.isApprovedForAll(seller, address(this)));
    }

    /**
     * @notice Settles a trade by verifying signatures and executing transfers
     * @param listingId Unique identifier for the listing
     * @param nftContract Address of the NFT contract
     * @param tokenId ID of the NFT being traded
     * @param erc20Token Address of the payment token
     * @param amount Amount of tokens to be transferred
     * @param listingDeadline Expiration timestamp for the listing
     * @param bidDeadline Expiration timestamp for the bid
     * @param sellerSignature Signature from the seller
     * @param buyerSignature Signature from the buyer
     * @param buyer Address of the buyer
     */
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
        if (block.timestamp > listingDeadline) revert ListingExpired();
        if (block.timestamp > bidDeadline) revert BidExpired();

        // Verify signatures and get seller address
        address seller = _verifySignatures(
            listingId,
            nftContract,
            tokenId,
            erc20Token,
            amount,
            listingDeadline,
            bidDeadline,
            sellerSignature,
            buyerSignature,
            buyer
        );

        // Execute transfers
        _executeTransfers(nftContract, tokenId, erc20Token, amount, seller, buyer);

        emit TradeSettled(listingId, seller, buyer, amount);
    }

    /**
     * @notice Internal function to verify signatures and prevent replay attacks
     * @param listingId Unique identifier for the listing
     * @param nftContract Address of the NFT contract
     * @param tokenId ID of the NFT being traded
     * @param erc20Token Address of the payment token
     * @param amount Amount of tokens to be transferred
     * @param listingDeadline Expiration timestamp for the listing
     * @param bidDeadline Expiration timestamp for the bid
     * @param sellerSignature Signature from the seller
     * @param buyerSignature Signature from the buyer
     * @param buyer Address of the buyer
     * @return seller Address of the seller, derived from the signature
     */
    function _verifySignatures(
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
    ) internal returns (address seller) {
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

        bytes32 ethSignedListingHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", listingHash));
        bytes32 ethSignedBidHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", bidHash));

        seller = ECDSA.recover(ethSignedListingHash, sellerSignature);
        if (ECDSA.recover(ethSignedBidHash, buyerSignature) != buyer) revert InvalidBuyerSignature();

        bytes32 tradeHash = keccak256(abi.encodePacked(sellerSignature, buyerSignature));
        if (usedSignatures[tradeHash]) revert TradeAlreadySettled();
        usedSignatures[tradeHash] = true;
    }

    /**
     * @notice Internal function to execute NFT and token transfers
     * @param nftContract Address of the NFT contract
     * @param tokenId ID of the NFT being traded
     * @param erc20Token Address of the payment token
     * @param amount Amount of tokens to be transferred
     * @param seller Address of the seller
     * @param buyer Address of the buyer
     */
    function _executeTransfers(
        address nftContract,
        uint256 tokenId,
        address erc20Token,
        uint256 amount,
        address seller,
        address buyer
    ) internal {
        IERC20 token = IERC20(erc20Token);
        
        // Check balance and allowance first
        if (token.balanceOf(buyer) < amount) {
            revert InsufficientFunds(buyer, amount, token.balanceOf(buyer));
        }
        if (token.allowance(buyer, address(this)) < amount) {
            revert InsufficientAllowance(buyer, amount, token.allowance(buyer, address(this)));
        }

        // Execute transfers
        IERC721(nftContract).transferFrom(seller, buyer, tokenId);
        bool success = token.transferFrom(buyer, seller, amount);
        if (!success) revert TokenTransferFailed();
    }
} 