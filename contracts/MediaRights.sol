// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";




contract MediaRights is ERC721, ERC721URIStorage, Ownable {
    uint256 public tokenCount;

    struct MediaDetails {
        uint256 royaltyFee;       // Royalty fee in wei
        address payable creator;  // Original creator
    }

    // tokenId => MediaDetails
    mapping(uint256 => MediaDetails) public mediaData;

    event MediaMinted(
        uint256 indexed tokenId,
        address indexed creator,
        string metadataURI,
        uint256 royaltyFee
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

    /// @notice Mint a new NFT with royalty fee and metadata
    function mintNFT(
        address recipient,
        string memory metadataURI,
        uint256 royaltyFee
    ) public returns (uint256) {
        uint256 newTokenId = tokenCount;

        _mint(recipient, newTokenId);
        _setTokenURI(newTokenId, metadataURI);

        mediaData[newTokenId] = MediaDetails({
            royaltyFee: royaltyFee,
            creator: payable(msg.sender)
        });

        tokenCount++;

        emit MediaMinted(newTokenId, msg.sender, metadataURI, royaltyFee);
        return newTokenId;
    }

    /// @notice Pay to access media (simulate royalty system)
    function accessMedia(uint256 tokenId) public payable returns (string memory) {
        require(_exists(tokenId), "NFT does not exist");
        MediaDetails memory media = mediaData[tokenId];
        require(msg.value >= media.royaltyFee, "Insufficient payment");

        // Transfer royalty to creator
        media.creator.transfer(msg.value);

        emit MediaAccessed(tokenId, msg.sender, msg.value);
        return tokenURI(tokenId);
    }

    /// @notice Get royalty fee of NFT
    function getRoyaltyFee(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "NFT does not exist");
        return mediaData[tokenId].royaltyFee;
    }

    /// @notice Get creator of NFT
    function getCreator(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "NFT does not exist");
        return mediaData[tokenId].creator;
    }
}
function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
}

function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
{
    return super.tokenURI(tokenId);
}
