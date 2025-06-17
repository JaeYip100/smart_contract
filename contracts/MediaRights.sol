// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MediaRights {
    struct MediaItem {
        string title;
        address payable owner;
        string ipfsHash;
        uint256 timestamp;
        uint256 royaltyFee; // in wei
    }

    // Media ID => MediaItem
    mapping(bytes32 => MediaItem) private mediaLibrary;
    bytes32[] private mediaKeys;

    event MediaRegistered(
        bytes32 indexed mediaId,
        address indexed owner,
        string title,
        string ipfsHash,
        uint256 royaltyFee
    );

    event MediaAccessed(
        bytes32 indexed mediaId,
        address indexed user,
        uint256 amountPaid
    );

    /// @notice Register new media with optional royalty fee
    function registerMedia(
        string memory _title,
        string memory _ipfsHash,
        uint256 _royaltyFee
    ) public {
        require(bytes(_title).length > 0, "Title is required");
        require(bytes(_ipfsHash).length > 0, "IPFS hash is required");

        bytes32 mediaId = keccak256(abi.encodePacked(_title, _ipfsHash, msg.sender));
        require(mediaLibrary[mediaId].owner == address(0), "Media already registered");

        mediaLibrary[mediaId] = MediaItem({
            title: _title,
            owner: payable(msg.sender),
            ipfsHash: _ipfsHash,
            timestamp: block.timestamp,
            royaltyFee: _royaltyFee
        });

        mediaKeys.push(mediaId);
        emit MediaRegistered(mediaId, msg.sender, _title, _ipfsHash, _royaltyFee);
    }

    /// @notice Access media by paying the royalty fee
    function accessMedia(bytes32 _mediaId) public payable returns (string memory) {
        MediaItem storage item = mediaLibrary[_mediaId];
        require(item.owner != address(0), "Media not found");
        require(msg.value >= item.royaltyFee, "Insufficient payment");

        item.owner.transfer(msg.value); // Send royalty
        emit MediaAccessed(_mediaId, msg.sender, msg.value);
        return item.ipfsHash;
    }

    /// @notice Get metadata for a single media item
    function getMedia(bytes32 _mediaId)
        public
        view
        returns (
            string memory title,
            address owner,
            string memory ipfsHash,
            uint256 timestamp,
            uint256 royaltyFee
        )
    {
        MediaItem memory item = mediaLibrary[_mediaId];
        require(item.owner != address(0), "Media not found");
        return (item.title, item.owner, item.ipfsHash, item.timestamp, item.royaltyFee);
    }

    /// @notice List all media IDs
    function getAllMediaIds() public view returns (bytes32[] memory) {
        return mediaKeys;
    }

    /// @notice Get media items uploaded by a specific address
    function getMediaByOwner(address _owner) public view returns (bytes32[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < mediaKeys.length; i++) {
            if (mediaLibrary[mediaKeys[i]].owner == _owner) {
                count++;
            }
        }

        bytes32[] memory result = new bytes32[](count);
        uint256 idx = 0;
        for (uint256 i = 0; i < mediaKeys.length; i++) {
            if (mediaLibrary[mediaKeys[i]].owner == _owner) {
                result[idx++] = mediaKeys[i];
            }
        }

        return result;
    }

    /// @notice Get royalty fee for a specific media
    function getRoyaltyFee(bytes32 _mediaId) public view returns (uint256) {
        require(mediaLibrary[_mediaId].owner != address(0), "Media not found");
        return mediaLibrary[_mediaId].royaltyFee;
    }
}
