# Smart Contract Features

## 1. Minting NFTs with Royalties & Listing Price

The `mintNFT` function is for Minting NFTs with Royalties and Listing Price.

Its purpose is to:

- Allow any user to mint an NFT and define creator royalty.
- Set the initial listing price.
- Attach metadata via IPFS URI.
- Enable the platform to collect a small minting fee.

## 2. Buying NFTs with Creator & Platform Royalties

The `buyNFT` function handles Buying NFTs with Creator & Platform Royalties.

Its purpose is to allow buyers to purchase listed NFTs. During the sale:

- The creator gets a royalty cut.
- The platform takes a small cut.
- The seller receives the rest.

## 3. Accessing Premium Content via Micro-payment

The `accessMedia` function is for Accessing Premium Content via Micro-payment.

Even if a user doesn’t own the NFT, they can pay a small access fee to stream a video or listen to a song.

## 4. Platform Admin Controls

```solidity
function updateMintingFee(uint256 newFee) public onlyOwner {
}

function updatePlatformRoyalty(uint256 newRoyalty) public onlyOwner {
}

function withdrawPlatformEarnings() public onlyOwner {
}
```

These functions shows the Platform Controls only for Admin. It is for the contract owner to update minting fees, adjust platform royalties and withdraw earnings.
