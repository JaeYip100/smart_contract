// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MediaRights {
    struct MediaItem {
        string title;
        address owner;
        string ipfsHash;
        uint256 timestamp;
    }

    // Unique ID mapped to each MediaItem
    mapping(bytes32 => MediaItem) private mediaLibrary;
    bytes32[] private mediaKeys;

    event MediaRegistered(bytes32 indexed mediaId, address indexed owner, string title, string ipfsHash);

    /// @notice Registers a new media item with a unique identifier
    /// @param _title The title of the media item
    /// @param _ipfsHash The IPFS hash pointing to the media content
    function registerMedia(string memory _title, string memory _ipfsHash) public {
        require(bytes(_title).length > 0, "Title is required");
        require(bytes(_ipfsHash).length > 0, "IPFS hash is required");

        bytes32 mediaId = keccak256(abi.encodePacked(_title, _ipfsHash, msg.sender));
        require(mediaLibrary[mediaId].owner == address(0), "Media already registered");

        mediaLibrary[mediaId] = MediaItem({
            title: _title,
            owner: msg.sender,
            ipfsHash: _ipfsHash,
            timestamp: block.timestamp
        });

        mediaKeys.push(mediaId);
        emit MediaRegistered(mediaId, msg.sender, _title, _ipfsHash);
    }

    /// @notice Get media metadata by ID
    /// @param _mediaId The unique identifier of the media
    function getMedia(bytes32 _mediaId) public view returns (string memory title, address owner, string memory ipfsHash, uint256 timestamp) {
        MediaItem memory item = mediaLibrary[_mediaId];
        require(item.owner != address(0), "Media not found");
        return (item.title, item.owner, item.ipfsHash, item.timestamp);
    }

    /// @notice Returns all media IDs for listing
    function getAllMediaIds() public view returns (bytes32[] memory) {
        return mediaKeys;
    }

    /// @notice Get all media uploaded by a specific user
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
                result[idx] = mediaKeys[i];
                idx++;
            }
        }

        return result;
    }
}
