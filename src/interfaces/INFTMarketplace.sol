// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title INFTMarketplace
 * @author 0xCR6 - https://www.0xcr6.dev
 * @notice Interface for the NFT Marketplace contract
 */
interface INFTMarketplace {
    /// @notice Custom errors
    error ListingExpired();
    error BidExpired();
    error InvalidBuyerSignature();
    error TradeAlreadySettled();
    error TokenTransferFailed();
    error InsufficientFunds(address buyer, uint256 required, uint256 actual);
    error InsufficientAllowance(address buyer, uint256 required, uint256 actual);

    /// @notice Stores information about an NFT listing
    struct Listing {
        address nftContract;
        uint256 tokenId;
        address erc20Token;
        uint256 minPrice;
        address seller;
        uint256 deadline;
    }

    /// @notice Stores information about a bid
    struct Bid {
        address bidder;
        uint256 amount;
        uint256 listingId;
        uint256 deadline;
    }

    /// @notice Emitted when a new listing is created
    event ListingCreated(
        uint256 indexed listingId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 minPrice
    );

    /// @notice Emitted when a trade is settled
    event TradeSettled(
        uint256 indexed listingId,
        address indexed seller,
        address indexed buyer,
        uint256 amount
    );

    /// @notice Creates a hash of the listing parameters
    /// @dev This hash will be signed by the seller
    function createListingHash(
        uint256 listingId,
        address nftContract,
        uint256 tokenId,
        address erc20Token,
        uint256 minPrice,
        uint256 deadline
    ) external pure returns (bytes32);

    /// @notice Creates a hash of the bid parameters
    /// @dev This hash will be signed by the buyer
    function createBidHash(
        uint256 listingId,
        uint256 amount,
        uint256 deadline
    ) external pure returns (bytes32);

    /// @notice Checks if both bid and listing are valid
    /// @dev Returns separate validity status for buyer and seller
    /// @return buyerValid True if buyer has sufficient balance and approval
    /// @return sellerValid True if seller owns the NFT and has given approval
    function checkTradeValidity(
        address buyer,
        address seller,
        address nftContract,
        uint256 tokenId,
        address erc20Token,
        uint256 amount
    ) external view returns (bool buyerValid, bool sellerValid);

    /// @notice Settles a trade using signatures from both parties
    /// @dev Requires valid signatures and transfers both NFT and tokens
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
    ) external;

    /// @notice Returns whether a signature pair has been used
    /// @dev Used to prevent signature replay attacks
    function usedSignatures(bytes32 hash) external view returns (bool);

    /// @notice Returns the current listing counter
    function listingCounter() external view returns (uint256);
} 