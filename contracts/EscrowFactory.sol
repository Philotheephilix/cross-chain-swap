// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "solidity-utils/contracts/libraries/SafeERC20.sol";
import { Address, AddressLib } from "solidity-utils/contracts/libraries/AddressLib.sol";

import { BaseExtension } from "limit-order-settlement/contracts/extensions/BaseExtension.sol";
import { ResolverValidationExtension } from "limit-order-settlement/contracts/extensions/ResolverValidationExtension.sol";

import { ProxyHashLib } from "./libraries/ProxyHashLib.sol";
import { Timelocks, TimelocksLib } from "./libraries/TimelocksLib.sol";

import { BaseEscrowFactory } from "./BaseEscrowFactory.sol";
import { EscrowDst } from "./EscrowDst.sol";
import { EscrowSrc } from "./EscrowSrc.sol";
import { MerkleStorageInvalidator } from "./MerkleStorageInvalidator.sol";
import { IBaseEscrow } from "./interfaces/IBaseEscrow.sol";
import { ImmutablesLib } from "./libraries/ImmutablesLib.sol";


/**
 * @title Escrow Factory contract
 * @notice Contract to create escrow contracts for cross-chain atomic swap.
 * @custom:security-contact security@1inch.io
 */
contract EscrowFactory is BaseEscrowFactory {
    using AddressLib for Address;
    using ImmutablesLib for IBaseEscrow.Immutables;
    using SafeERC20 for IERC20;
    using TimelocksLib for Timelocks;

    constructor(
        address limitOrderProtocol,
        IERC20 feeToken,
        IERC20 accessToken,
        address owner,
        uint32 rescueDelaySrc,
        uint32 rescueDelayDst
    )
    BaseExtension(limitOrderProtocol)
    ResolverValidationExtension(feeToken, accessToken, owner)
    MerkleStorageInvalidator(limitOrderProtocol) {
        ESCROW_SRC_IMPLEMENTATION = address(new EscrowSrc(rescueDelaySrc));
        ESCROW_DST_IMPLEMENTATION = address(new EscrowDst(rescueDelayDst));
        _PROXY_SRC_BYTECODE_HASH = ProxyHashLib.computeProxyBytecodeHash(ESCROW_SRC_IMPLEMENTATION);
        _PROXY_DST_BYTECODE_HASH = ProxyHashLib.computeProxyBytecodeHash(ESCROW_DST_IMPLEMENTATION);
    }

    /**
     * @notice Creates a new escrow contract for maker on the source chain (for testing purposes).
     * @dev This function allows direct creation of source escrows without going through the Limit Order Protocol.
     * The caller must send the safety deposit in the native token and approve the source token to be transferred.
     * @param srcImmutables The immutables of the escrow contract that are used in deployment.
     * @return escrow The address of the created escrow contract.
     */
    function createSrcEscrow(IBaseEscrow.Immutables calldata srcImmutables) external payable returns (address escrow) {
        address token = srcImmutables.token.get();
        uint256 nativeAmount = srcImmutables.safetyDeposit;
        if (token == address(0)) {
            nativeAmount += srcImmutables.amount;
        }
        if (msg.value != nativeAmount) revert InsufficientEscrowBalance();

        IBaseEscrow.Immutables memory immutables = srcImmutables;
        immutables.timelocks = immutables.timelocks.setDeployedAt(block.timestamp);

        bytes32 salt = immutables.hashMem();
        escrow = _deployEscrow(salt, msg.value, ESCROW_SRC_IMPLEMENTATION);
        
        if (token != address(0)) {
            IERC20(token).safeTransferFrom(msg.sender, escrow, immutables.amount);
        }

        emit SrcEscrowCreated(immutables, DstImmutablesComplement({
            maker: immutables.maker,
            amount: immutables.amount,
            token: immutables.token,
            safetyDeposit: immutables.safetyDeposit,
            chainId: 0 // Will be set by the caller
        }));
        
        // Emit the escrow address for easier retrieval
        emit SrcEscrowCreatedDirect(escrow, immutables.hashlock, immutables.maker);
    }
}
