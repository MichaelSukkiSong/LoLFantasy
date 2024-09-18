// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {ERC721} from "@solmate/tokens/ERC721.sol";

contract LoLNft is ERC721 {
    uint256 private s_tokenCount;
    mapping(uint256 => string) private s_tokenIdToTokenURI;

    constructor() ERC721("LoLNft", "LN") {
        s_tokenCount = 0;
    }

    function mint(string memory tokenUri) external {
        s_tokenIdToTokenURI[s_tokenCount] = tokenUri;
        _safeMint(msg.sender, s_tokenCount);

        s_tokenCount++;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return s_tokenIdToTokenURI[tokenId];
    }
}
