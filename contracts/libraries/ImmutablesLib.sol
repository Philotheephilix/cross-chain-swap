// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { IEscrowSrc } from "../interfaces/IEscrowSrc.sol";
import { IEscrowDst } from "../interfaces/IEscrowDst.sol";

/**
 * @title Library for escrow immutables.
 * @custom:security-contact security@1inch.io
 */
library ImmutablesLib {
    uint256 internal constant ESCROW_IMMUTABLES_SIZE = 0x100;
    uint256 internal constant ESCROW_IMMUTABLES_DST_SIZE = 0x180;

    /**
     * @notice Returns the hash of the immutables.
     * @param immutables The immutables to hash.
     * @return ret The computed hash.
     */
    function hash(IEscrowSrc.Immutables calldata immutables) internal pure returns(bytes32 ret) {
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            calldatacopy(ptr, immutables, ESCROW_IMMUTABLES_SIZE)
            ret := keccak256(ptr, ESCROW_IMMUTABLES_SIZE)
        }
    }

    /**
     * @notice Returns the hash of the immutables.
     * @param immutables The immutables to hash.
     * @return ret The computed hash.
     */
    function hashMem(IEscrowSrc.Immutables memory immutables) internal pure returns(bytes32 ret) {
        assembly ("memory-safe") {
            ret := keccak256(immutables, ESCROW_IMMUTABLES_SIZE)
        }
    }

    /**
     * @notice Returns the hash of the immutables on dst chain.
     * @param immutables The immutables to hash.
     * @return ret The computed hash.
     */
    function hash(IEscrowDst.ImmutablesDst calldata immutables) internal pure returns(bytes32 ret) {
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            calldatacopy(ptr, immutables, ESCROW_IMMUTABLES_DST_SIZE)
            ret := keccak256(ptr, ESCROW_IMMUTABLES_DST_SIZE)
        }
    }

    /**
     * @notice Returns the hash of the immutables.
     * @param immutables The immutables to hash.
     * @return ret The computed hash.
     */
    function hashMem(IEscrowDst.ImmutablesDst memory immutables) internal pure returns(bytes32 ret) {
        assembly ("memory-safe") {
            ret := keccak256(immutables, ESCROW_IMMUTABLES_DST_SIZE)
        }
    }
}
