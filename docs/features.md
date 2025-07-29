## Smart contract features

# 1. Minting NFTs with Royalties & Listing Price

# The mintnft function is the Minting NFTs with Royalties and Listing Price.

# Its purpose is to :

# -allow any user to mint an NFT and define creator royalty,

# -initial listing price,

# -metadata via IPFS URI ,

# -platform that collects a small minting fee.

# 2. Buying NFTs with Creator & Platform Royalties

# The buynft function here shows buying NFTs with Creator & Platform Royalties. The purpose is to allow buyers to purchase listed NFTs. During the sale, creator gets a royalty cut, platform takes a small cut and seller receives the rest.

# 3. Accessing Premium Content via Micro-payment

# The access media function is for accessing Premium Content via Micro-payment. Even if a user doesn’t own the NFT, they can pay a small access fee like to stream a video or listen to a song.

# 4. Platform Admin Controls

function updateMintingFee(uint256 newFee) public onlyOwner {
}

function updatePlatformRoyalty(uint256 newRoyalty) public onlyOwner {
}

function withdrawPlatformEarnings() public onlyOwner {
}

# These functions shows the Platform Controls only for Admin. It is for the contract owner to update minting fees, adjust platform royalties and withdraw earnings.
