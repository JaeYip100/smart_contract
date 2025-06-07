// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MediaRights {
    struct MediaItem {
        string title;
        address owner;
        string ipfsHash; 
    }

    mapping(uint => MediaItem) public mediaLibrary;
    uint public mediaCount = 0;

    function registerMedia(string memory _title, string memory _ipfsHash) public {
        mediaLibrary[mediaCount] = MediaItem(_title, msg.sender, _ipfsHash);
        mediaCount++;
    }

    function getMedia(uint _id) public view returns (string memory, address, string memory) {
        MediaItem memory m = mediaLibrary[_id];
        return (m.title, m.owner, m.ipfsHash);
    }
}
