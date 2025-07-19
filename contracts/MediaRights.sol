// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract MediaRights is ERC721, ERC721URIStorage, Ownable, ReentrancyGuard {
    uint256 public tokenCount;
    uint256 public mintingFee = 0.001 ether; // Platform fee for minting (adjustable)
    uint256 public platformRoyalty = 250; // 2.5% platform fee on sales (in basis points)
    
    struct MediaDetails {
        uint256 creatorRoyalty;     // Creator royalty in basis points (e.g., 500 = 5%)
        address payable creator;    // Original creator
        uint256 salePrice;         // Current listing price (0 = not for sale)
        bool isForSale;           // Whether NFT is currently listed
    }
    
    // tokenId => MediaDetails
    mapping(uint256 => MediaDetails) public mediaData;
    
    event MediaMinted(
        uint256 indexed tokenId,
        address indexed creator,
        string metadataURI,
        uint256 creatorRoyalty,
        uint256 initialPrice
    );
    
    event MediaListed(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price
    );
    
    event MediaSold(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 price,
        uint256 creatorRoyalty,
        uint256 platformFee
    );
    
    event MediaAccessed(
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 amountPaid
    );
    
    constructor(address initialOwner)
        ERC721("MediaRights", "MNFT")
        Ownable(initialOwner)
    {}
    
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function _tokenExists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
    
    /// @notice Mint a new NFT with creator royalty and initial listing price
    /// @param recipient Address to receive the NFT
    /// @param metadataURI IPFS URI for metadata
    /// @param creatorRoyaltyBps Creator royalty in basis points (500 = 5%)
    /// @param initialSalePrice Initial listing price in wei (can be 0 for not listing immediately)
    function mintNFT(
        address recipient,
        string memory metadataURI,
        uint256 creatorRoyaltyBps,
        uint256 initialSalePrice
    ) public payable returns (uint256) {
        require(msg.value >= mintingFee, "Insufficient minting fee");
        require(creatorRoyaltyBps <= 1000, "Creator royalty cannot exceed 10%"); // Max 10%
        
        uint256 newTokenId = tokenCount;
        _mint(recipient, newTokenId);
        _setTokenURI(newTokenId, metadataURI);
        
        mediaData[newTokenId] = MediaDetails({
            creatorRoyalty: creatorRoyaltyBps,
            creator: payable(msg.sender),
            salePrice: initialSalePrice,
            isForSale: initialSalePrice > 0
        });
        
        tokenCount++;
        
        // Transfer minting fee to platform owner
        payable(owner()).transfer(msg.value);
        
        emit MediaMinted(newTokenId, msg.sender, metadataURI, creatorRoyaltyBps, initialSalePrice);
        
        if (initialSalePrice > 0) {
            emit MediaListed(newTokenId, recipient, initialSalePrice);
        }
        
        return newTokenId;
    }
    
    /// @notice List NFT for sale
    /// @param tokenId Token to list
    /// @param price Price in wei
    function listForSale(uint256 tokenId, uint256 price) public {
        require(_tokenExists(tokenId), "NFT does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        require(price > 0, "Price must be greater than 0");
        
        mediaData[tokenId].salePrice = price;
        mediaData[tokenId].isForSale = true;
        
        emit MediaListed(tokenId, msg.sender, price);
    }
    
    /// @notice Remove NFT from sale
    /// @param tokenId Token to unlist
    function unlistFromSale(uint256 tokenId) public {
        require(_tokenExists(tokenId), "NFT does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        
        mediaData[tokenId].salePrice = 0;
        mediaData[tokenId].isForSale = false;
    }
    
    /// @notice Purchase NFT from marketplace
    /// @param tokenId Token to purchase
    function buyNFT(uint256 tokenId) public payable nonReentrant {
        require(_tokenExists(tokenId), "NFT does not exist");
        MediaDetails storage media = mediaData[tokenId];
        require(media.isForSale, "NFT not for sale");
        require(msg.value >= media.salePrice, "Insufficient payment");
        
        address seller = ownerOf(tokenId);
        require(seller != msg.sender, "Cannot buy your own NFT");
        
        uint256 totalPrice = msg.value;
        
        // Calculate fees
        uint256 creatorRoyalty = (totalPrice * media.creatorRoyalty) / 10000;
        uint256 platformFee = (totalPrice * platformRoyalty) / 10000;
        uint256 sellerAmount = totalPrice - creatorRoyalty - platformFee;
        
        // Remove from sale
        media.isForSale = false;
        media.salePrice = 0;
        
        // Transfer payments
        if (creatorRoyalty > 0 && media.creator != seller) {
            media.creator.transfer(creatorRoyalty);
        } else {
            // If seller is creator, they get the royalty too
            sellerAmount += creatorRoyalty;
        }
        
        if (platformFee > 0) {
            payable(owner()).transfer(platformFee);
        }
        
        payable(seller).transfer(sellerAmount);
        
        // Transfer NFT
        _transfer(seller, msg.sender, tokenId);
        
        emit MediaSold(tokenId, seller, msg.sender, totalPrice, creatorRoyalty, platformFee);
    }
    
    /// @notice Pay to access media content (for premium content access)
    /// @param tokenId Token to access
    function accessMedia(uint256 tokenId) public payable returns (string memory) {
        require(_tokenExists(tokenId), "NFT does not exist");
        MediaDetails memory media = mediaData[tokenId];
        
        // For simplicity, using a fixed access fee. Could make this configurable per NFT
        uint256 accessFee = 0.0001 ether;
        require(msg.value >= accessFee, "Insufficient payment");
        
        // Transfer access fee to creator
        media.creator.transfer(msg.value);
        
        emit MediaAccessed(tokenId, msg.sender, msg.value);
        return tokenURI(tokenId);
    }
    
    /// @notice Get NFT sale information
    function getSaleInfo(uint256 tokenId) public view returns (
        bool isForSale,
        uint256 price,
        address owner,
        address creator,
        uint256 creatorRoyalty
    ) {
        require(_tokenExists(tokenId), "NFT does not exist");
        MediaDetails memory media = mediaData[tokenId];
        
        return (
            media.isForSale,
            media.salePrice,
            ownerOf(tokenId),
            media.creator,
            media.creatorRoyalty
        );
    }
    
    /// @notice Update platform settings (only owner)
    function updateMintingFee(uint256 newFee) public onlyOwner {
        mintingFee = newFee;
    }
    
    function updatePlatformRoyalty(uint256 newRoyalty) public onlyOwner {
        require(newRoyalty <= 1000, "Platform royalty cannot exceed 10%");
        platformRoyalty = newRoyalty;
    }
    
    /// @notice Withdraw platform earnings
    function withdrawPlatformEarnings() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}