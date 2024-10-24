// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@iden3/contracts/lib/Poseidon.sol";

interface IGroth16Verifier {
    function verifyProof(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[1] calldata _pubSignals
    ) external view returns (bool);
}

contract Tick is ERC721, ERC721Burnable, Ownable {
    uint256 private _nextTokenId;
    mapping(uint256 => int256) private _tokenValues;
    mapping(uint256 => uint256) private _lastUpdateTime;

    struct TokenParams {
        uint8 p;
        uint256 updateInterval;
        int256 incrementAmount;
    }
    mapping(uint256 => TokenParams) private _tokenParams;
    IGroth16Verifier public verifier;

    constructor(
        address initialOwner,
        address _verifier
    ) ERC721("Tick", "TICK") Ownable(initialOwner) {
        verifier = IGroth16Verifier(_verifier);
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
        // uint256 updates = timePassed / params.updateInterval;
        int256 currentValue = _tokenValues[tokenId];
        require(timePassed >= params.updateInterval, "Not enough time passed");
        if (_random(tokenId, 1) < params.p) {
            currentValue += params.incrementAmount;
        } else {
            currentValue -= params.incrementAmount;
        }
        if (currentValue < 0) {
            currentValue = 0;
        }

        return currentValue;
    }

    function _isValidToken(uint256 tokenId) internal view returns (bool) {
        return tokenId < _nextTokenId && _ownerOf(tokenId) != address(0);
    }

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

    function submitProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) public view returns (bool) {
        bool result = verifier.verifyProof(a, b, c, input);
        require(result, "Invalid Proof");
        return true;
    }

    function tokenValue(uint256 tokenId) public view returns (int256) {
        require(_isValidToken(tokenId), "Token does not exist");
        return _tokenValues[tokenId];
    }

    function updateTokenValue(uint256 tokenId) public {
        _tokenValues[tokenId] = _calculateCurrentValue(tokenId);
        _lastUpdateTime[tokenId] = block.timestamp;
    }
}
