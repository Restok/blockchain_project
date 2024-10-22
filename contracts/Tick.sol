// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Tick is ERC721, ERC721Burnable, Ownable {
    uint256 private _nextTokenId;
    mapping(uint256 => int256) private _tokenValues;
    mapping(uint256 => uint256) private _lastUpdateTime;
    ZKPVerifier public zkpVerifier;

    struct TokenParams {
        uint8 p;
        uint256 updateInterval;
        int256 incrementAmount;
    }
    mapping(uint256 => TokenParams) private _tokenParams;

    constructor(
        address initialOwner,
        uint8 initialP
    ) ERC721("Tick", "TICK") Ownable(initialOwner) {}

    function verifyValueProof(
        uint256 tokenId,
        uint256 threshold,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[3] memory input
    ) public view returns (bool) {
        require(_isValidToken(tokenId), "Token does not exist");
        require(
            input[0] == uint256(uint160(ownerOf(tokenId))),
            "Invalid owner"
        );
        require(input[1] == tokenId, "Invalid token ID");
        require(input[2] == threshold, "Invalid threshold");

        return zkpVerifier.verifyProof(a, b, c, input);
    }

    function safeMint(
        address to,
        uint8 tokenP,
        uint256 tokenUpdateInterval,
        int256 tokenIncrementAmount
    ) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _tokenValues[tokenId] = 0;
        _lastUpdateTime[tokenId] = block.timestamp;
        _tokenParams[tokenId] = TokenParams(
            tokenP,
            tokenUpdateInterval,
            tokenIncrementAmount
        );
    }

    function _calculateCurrentValue(
        uint256 tokenId
    ) internal view returns (int256) {
        TokenParams memory params = _tokenParams[tokenId];
        uint256 timePassed = block.timestamp - _lastUpdateTime[tokenId];
        uint256 updates = timePassed / params.updateInterval;
        int256 currentValue = _tokenValues[tokenId];

        // for (uint256 i = 0; i < updates; i++) {
        if (_random(tokenId, updates) < params.p) {
            currentValue += params.incrementAmount * int256(updates);
        } else {
            currentValue -= params.incrementAmount * int256(updates);
        }
        // }

        return currentValue;
    }

    function _isValidToken(uint256 tokenId) internal view returns (bool) {
        return tokenId < _nextTokenId && _ownerOf(tokenId) != address(0);
    }

    // generate pseudo-random number
    function _random(
        uint256 tokenId,
        uint256 nonce
    ) internal view returns (uint8) {
        return
            uint8(
                uint256(
                    keccak256(abi.encodePacked(block.timestamp, tokenId, nonce))
                ) % 100
            );
    }

    function tokenValue(uint256 tokenId) public view returns (int256) {
        require(_isValidToken(tokenId), "Token does not exist");
        return _calculateCurrentValue(tokenId);
    }
}
