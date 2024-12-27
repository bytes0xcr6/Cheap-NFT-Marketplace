// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @notice Interface for the NFT marketplace contract
 * @dev Defines the core functionality and events for the marketplace
 * @author 0xCR6 - https://www.0xcr6.dev
 */
interface INFTMarketplace {
    /**
     * @notice Emitted when a trade is successfully settled
     * @param listingId The ID of the listing that was settled
     * @param seller The address of the NFT seller
     * @param buyer The address of the NFT buyer
     * @param amount The amount of ERC20 tokens paid
     */
    event TradeSettled(
        uint256 indexed listingId,
        address indexed seller,
        address indexed buyer,
        uint256 amount
    );

    /**
     * @notice Error thrown when a listing has expired
     */
    error ListingExpired();

    /**
     * @notice Error thrown when a bid has expired
     */
    error BidExpired();

    /**
     * @notice Error thrown when the buyer's signature is invalid
     */
    error InvalidBuyerSignature();

    /**
     * @notice Error thrown when a trade has already been settled
     */
    error TradeAlreadySettled();

    /**
     * @notice Error thrown when token transfer fails
     */
    error TokenTransferFailed();

    /**
     * @notice Error thrown when buyer has insufficient funds
     * @param buyer The address of the buyer
     * @param required The amount required
     * @param available The amount available
     */
    error InsufficientFunds(address buyer, uint256 required, uint256 available);

    /**
     * @notice Error thrown when buyer has insufficient allowance
     * @param buyer The address of the buyer
     * @param required The amount required
     * @param available The amount available
     */
    error InsufficientAllowance(address buyer, uint256 required, uint256 available);
} 