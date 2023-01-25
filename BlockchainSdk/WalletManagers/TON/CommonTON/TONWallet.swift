//
//  TONWallet.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 18.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import CryptoSwift
import Foundation
import TweetNacl

public class TONWallet: TONContract {
    
    /// Wallet public key
    public var publicKey: Data
    
    /// Signer for build transaction
    public weak var signer: TONSigner?
    
    // MARK: - Init
    
    public init(
        publicKey: Data,
        signer: TONSigner?,
        walletId: UInt32? = nil,
        wc: Int = 0
    ) throws {
        self.publicKey = publicKey
        self.signer = signer
        
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
    public func createTransferMessage(
        address: String,
        amount: Int,
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
            gramValue: 1,
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
    
    public func signTransferMessage(_ signingMessage: TONCell, _ seqno: Int) throws -> TONExternalMessage {
        try self.createExternalMessage(
            signingMessage: signingMessage,
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
    func createSigningMessage(seqno: Int?, expireAt: UInt?, withoutOp: Bool? = nil) throws -> TONCell {
        let seqno = seqno ?? 0
        let expireAt = expireAt ?? (UInt(floor((Date().timeIntervalSince1970) / 1e3)) + 60)
        
        let message = TONCell()
        
        guard let walletId = self.options?.walletId else {
            throw NSError()
        }
        
        try message.raw.write(uint: UInt(walletId), 32)
        
        if seqno == 0 {
            // message.bits.writeInt(-1, 32);// todo: dont work
            try [Int](repeating: 1, count: 32).forEach {
                try message.raw.write(int: $0, 1)
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
     * @protected
     * @param signingMessage {Cell}
     * @param secretKey {Uint8Array}  nacl.KeyPair.secretKey
     * @param seqno {number}
     * @param dummySignature?    {boolean}
     * @return {Promise<{address: Address, signature: Uint8Array, message: Cell, cell: Cell, body: Cell, resultMessage: Cell}>}
     */
    func createExternalMessage(
        signingMessage: TONCell,
        seqno: Int,
        dummySignature: Bool = false
    ) throws  -> TONExternalMessage {
        let signMsgHash = try signingMessage.hash()
        let signature = try dummySignature ? [UInt8](repeating: 0, count: 64) : NaclSign.signDetached(
            message: Data(signMsgHash),
            secretKey: Data(hex: "3bab423792cc6d5df5efc96eb800af9c83ac9761548e5c1f472e63ac5a406de6995b3e6c86d4126f52a19115ea30d869da0b2e5502a19db1855eeb13081b870b")
        ).bytes
        
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
