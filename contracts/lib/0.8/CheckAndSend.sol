//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
  Copyright 2021 Flashbots: Scott Bigelow (scott@flashbots.net).
*/

contract CheckAndSend {
    function _check32BytesMulti(
        address[] calldata _targets,
        bytes[] calldata _payloads,
        bytes32[] calldata _resultMatches
    ) internal view {
        require(_targets.length == _payloads.length);
        require(_targets.length == _resultMatches.length);
        for (uint256 i = 0; i < _targets.length; i++) {
            _check32Bytes(_targets[i], _payloads[i], _resultMatches[i]);
        }
    }

    function _checkBytesMulti(
        address[] calldata _targets,
        bytes[] calldata _payloads,
        bytes[] calldata _resultMatches
    ) internal view {
        require(_targets.length == _payloads.length);
        require(_targets.length == _resultMatches.length);
        for (uint256 i = 0; i < _targets.length; i++) {
            _checkBytes(_targets[i], _payloads[i], _resultMatches[i]);
        }
    }

    function _check32Bytes(
        address _target,
        bytes memory _payload,
        bytes32 _resultMatch
    ) internal view {
        (bool _success, bytes memory _response) = _target.staticcall(_payload);
        require(_success, "!success");
        require(_response.length >= 32, "response less than 32 bytes");
        bytes32 _responseScalar;
        assembly {
            _responseScalar := mload(add(_response, 0x20))
        }
        require(_responseScalar == _resultMatch, "response mismatch");
    }

    function _checkBytes(
        address _target,
        bytes memory _payload,
        bytes memory _resultMatch
    ) internal view {
        (bool _success, bytes memory _response) = _target.staticcall(_payload);
        require(_success, "!success");
        require(
            keccak256(_resultMatch) == keccak256(_response),
            "response bytes mismatch"
        );
    }
}
