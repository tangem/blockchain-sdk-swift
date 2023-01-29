//
//  TONWallet.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 18.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import CryptoSwift
import Foundation

public class TONWallet: TONContract {
    
    /// Wallet public key
    public var publicKey: Data
    
    // MARK: - Init
    
    public init(
        publicKey: Data,
        walletId: UInt32? = nil,
        wc: Int = 0
    ) throws {
        self.publicKey = publicKey
        
        try super.init(
            options: .init(
                code: TONCell.oneFromBoc(Data(hexString: TONCellBocWallet).bytes),
                address: nil,
                walletId: walletId ?? (TONCellWalletId + UInt32(wc)),
                wc: wc
            )
        )
    }
    
    override func createDataCell() throws -> TONCell {
        let cell = TONCell()
        try cell.raw.write(uint: 0, 32)
        try cell.raw.write(bits: TONCellWalletId.bits.reversed())
        try cell.raw.write(bytes: publicKey.bytes)
        try cell.raw.write(uint: 0, 1)
        return cell
    }
    
    /**
     * @param secretKey {Uint8Array}  nacl.KeyPair.secretKey
     * @param address   {Address | string}
     * @param amount    {BN | number} in nanograms
     * @param seqno {number}
     * @param payload?   {string | Uint8Array | Cell}
     * @param sendMode?  {number}
     * @param dummySignature?    {boolean}
     * @param stateInit? {Cell}
     * @param expireAt? {number}
     * @return {Promise<{address: Address, signature: Uint8Array, message: Cell, cell: Cell, body: Cell, resultMessage: Cell}>}
     */
    func createTransferMessage(
        address: String,
        amount: UInt,
        payload: String? = nil,
        seqno: Int,
        sendMode: Int = 3,
        dummySignature: Bool = false,
        stateInit: TONCell? = nil,
        expireAt: UInt? = nil
    ) throws -> TONCell {
        let payloadCell = TONCell()
        
        let orderHeader = try TONContract.createInternalMessageHeader(
            dest: address,
            gramValue: amount,
            src: getAddress().toString(isUserFriendly: true, isUrlSafe: true, isBounceable: true)
        )
        
        let order = try TONContract.createCommonMsgInfo(
            header: orderHeader,
            stateInit: stateInit,
            body: payloadCell
        )
        
        let signingMessage = try createSigningMessage(
            seqno: seqno,
            expireAt: expireAt
        )
        
        try signingMessage.raw.write(int: sendMode, 8)
        signingMessage.refs.append(order)
        
        return signingMessage
    }
    
    func signTransferMessage(_ signingMessage: TONCell, _ seqno: Int, signature: Array<UInt8>) throws -> TONExternalMessage {
        try self.createExternalMessage(
            signingMessage: signingMessage,
            signature: signature,
            seqno: seqno
        )
    }
    
    // MARK: - Private Implementation
    
    /**
     * @override
     * @private
     * @param   seqno?   {number}
     * @param   expireAt? {number}
     * @param   withoutOp? {boolean}
     * @return {Cell}
     */
    func createSigningMessage(seqno: Int? = 0, expireAt: UInt?, withoutOp: Bool? = nil) throws -> TONCell {
        let seqno = seqno ?? 0
        let expireAt = expireAt ?? (UInt(floor((Date().timeIntervalSince1970) / 1e3)) + 60)
        
        let message = TONCell()
        
        guard let walletId = self.options?.walletId else {
            throw TONError.exception("TON WalletID is empty")
        }
        
        try message.raw.write(uint: UInt(walletId), 32)
        
        if seqno == 0 {
            // message.bits.writeInt(-1, 32);// todo: dont work
            try [Int](repeating: 1, count: 32).forEach { _ in
                try message.raw.write(bit: .one)
            }
        } else {
            try message.raw.write(uint: expireAt, 32)
        }
        
        try message.raw.write(int: seqno, 32)
        
        if withoutOp == nil {
            try message.raw.write(uint: 0, 8) // op
        }
        
        return message
    }
    
    /**
     * External message for initialization
     * @param secretKey  {Uint8Array} nacl.KeyPair.secretKey
     * @return {{address: Address, message: Cell, body: Cell, sateInit: Cell, code: Cell, data: Cell}}
     */
    func createInitExternalMessage(
        signingMessage: TONCell,
        signature: Array<UInt8>
    ) throws -> TONExternalMessage {
        let stateInit = try createStateInit()

        let body = TONCell()
        try body.raw.write(bytes: signature)
        try body.write(cell: signingMessage)

        let header = try TONContract.createExternalMessageHeader(dest: stateInit.address)
        
        let externalMessage = try TONContract.createCommonMsgInfo(
            header: header,
            stateInit: stateInit.stateInit,
            body: body
        )

        return .init(
            address: stateInit.address,
            message: externalMessage,
            body: body,
            signature: signature,
            stateInit: stateInit.stateInit,
            code: stateInit.code,
            data: stateInit.data
        )
    }
    
    /**
     * @protected
     * @param signingMessage {Cell}
     * @param secretKey {Uint8Array}  nacl.KeyPair.secretKey
     * @param seqno {number}
     * @return {Promise<{address: Address, signature: Uint8Array, message: Cell, cell: Cell, body: Cell, resultMessage: Cell}>}
     */
    func createExternalMessage(
        signingMessage: TONCell,
        signature: Array<UInt8>,
        seqno: Int
    ) throws  -> TONExternalMessage {
        let body = TONCell()
        try body.raw.write(bytes: signature)
        try body.write(cell: signingMessage)
        
        var stateInit: TONCell?
        var code: TONCell?
        var data: TONCell?

        if seqno == 0 {
            let deploy = try createStateInit()
            stateInit = deploy.stateInit
            code = deploy.code
            data = deploy.data
        }
        
        let selfAddress = try self.getAddress()
        let header = try TONContract.createExternalMessageHeader(dest: selfAddress)
        
        let resultMessage = try TONContract.createCommonMsgInfo(
            header: header,
            stateInit: stateInit,
            body: body
        )
        
        return .init(
            address: selfAddress,
            message: resultMessage,
            body: body,
            signature: signature,
            stateInit: stateInit,
            code: code,
            data: data
        )
    }
    
}
