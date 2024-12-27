# Cheap NFT Marketplace

> A gas-efficient NFT marketplace using signature-based listings and bids.

## Table of Contents

- [Deployment](#deployment)
- [Features](#features)
- [Quick Start](#quick-start)
- [Usage Guide](#usage-guide)
  - [For NFT Sellers](#for-nft-sellers)
  - [For NFT Buyers](#for-nft-buyers)
  - [For Trade Executors](#for-trade-executors)
- [Technical Details](#technical-details)
  - [Architecture](#architecture)
  - [Security](#security)
  - [Development](#development)
- [Testing](#testing)

## Deployment

Current deployments:

| Network          | Contract       | Address                                                                                                                      |
| ---------------- | -------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Arbitrum Sepolia | NFTMarketplace | [0x67f0f3b6a70aac231c7660e56ea63d73fd57be36](https://sepolia.arbiscan.io/address/0x67f0f3b6a70aac231c7660e56ea63d73fd57be36) |
| Arbitrum Sepolia | TestNFT        | [0xf42b64907cefef5972851b6475913c3981d7be32](https://sepolia.arbiscan.io/address/0xf42b64907cefef5972851b6475913c3981d7be32) |
| Arbitrum Sepolia | TestToken      | [0x678429e8e98fd5eae872a163a30b7ef6693bb2d7](https://sepolia.arbiscan.io/address/0x678429e8e98fd5eae872a163a30b7ef6693bb2d7) |

## Features

- ✨ Gasless listings and bids (pay gas only when trading)
- 🔒 Non-custodial - assets stay in users' wallets
- ⚡ Single-transaction settlement
- 🤝 Trustless trading with signature verification
- 📝 Support for any ERC721 and ERC20 tokens

## Quick Start

```bash
# Install dependencies
forge install

# Run tests
forge test

# Deploy to Arbitrum Sepolia
forge script script/Deploy.s.sol:DeployScript \
    --rpc-url "https://sepolia-rollup.arbitrum.io/rpc" \
    --broadcast \
    --verify \
    --chain arbitrum-sepolia \
    --etherscan-api-key $ARBISCAN_API_KEY \
    --private-key $PRIVATE_KEY \
    -vvvv
```

## Usage Guide

### For NFT Sellers

1. **Approve the Marketplace**

```typescript
const nftContract = new ethers.Contract(NFT_ADDRESS, NFT_ABI, signer);
await nftContract.setApprovalForAll(MARKETPLACE_ADDRESS, true);
```

2. **Create & Sign Listing**

```typescript
const listing = {
  listingId: 1,
  nftContract: NFT_ADDRESS,
  tokenId: 123,
  erc20Token: TOKEN_ADDRESS,
  minPrice: ethers.utils.parseEther("1.0"),
  deadline: Math.floor(Date.now() / 1000) + 86400, // 24h
};

const listingHash = await marketplace.createListingHash(
  listing.listingId,
  listing.nftContract,
  listing.tokenId,
  listing.erc20Token,
  listing.minPrice,
  listing.deadline
);
const signature = await signer.signMessage(ethers.utils.arrayify(listingHash));
```

### For NFT Buyers

1. **Approve Token Spending**

```typescript
const tokenContract = new ethers.Contract(TOKEN_ADDRESS, TOKEN_ABI, signer);
await tokenContract.approve(MARKETPLACE_ADDRESS, ethers.constants.MaxUint256);
```

2. **Create & Sign Bid**

```typescript
const bid = {
  listingId: 1,
  amount: ethers.utils.parseEther("1.0"),
  deadline: Math.floor(Date.now() / 1000) + 3600, // 1h
};

const bidHash = await marketplace.createBidHash(
  bid.listingId,
  bid.amount,
  bid.deadline
);
const signature = await signer.signMessage(ethers.utils.arrayify(bidHash));
```

### For Trade Executors

1. **Validate Trade**

```typescript
const { buyerValid, sellerValid } = await marketplace.checkTradeValidity(
  buyerAddress,
  sellerAddress,
  nftContract,
  tokenId,
  tokenAddress,
  amount
);

if (!buyerValid || !sellerValid) {
  console.error("Trade validation failed");
  return;
}
```

2. **Execute Trade**

```typescript
await marketplace.settleTrade(
  listingId,
  nftContract,
  tokenId,
  erc20Token,
  amount,
  listingDeadline,
  bidDeadline,
  sellerSignature,
  buyerSignature,
  buyerAddress
);
```

## Technical Details

### Architecture

The marketplace operates through three main components:

1. **Listings**: Seller-signed intents to sell NFTs
2. **Bids**: Buyer-signed intents to purchase
3. **Settlement**: Valid trades can be executed by any party, though our microservice handles this process

### Security

- ✓ Signature replay protection
- ✓ Deadline-based expiration
- ✓ Non-custodial design
- ✓ No admin privileges
- ✓ Pre-trade validation
- ✓ Independent buyer/seller checks

### Development

```bash
# Install
forge install

# Test
forge test
forge test --match-test testSettleTrade
forge test --gas-report

# Coverage
forge coverage
```

## Testing

### Coverage Report

![Test Coverage](images/test-coverage.png)

### Gas Analysis

![Gas Report](images/gas-report.png)

## License

MIT License - see [LICENSE.md](LICENSE.md)
