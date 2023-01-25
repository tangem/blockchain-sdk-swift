//
//  TONContract.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 18.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import CryptoSwift
import TangemSdk
import Foundation

open class TONContract {
    
    // MARK: - Typealias
    
    typealias Bit = CryptoSwift.Bit
    
    // MARK: - Public Properties
    
    public var options: TONContractOption?
    public var address: TONAddress?
    public var wc: Int?
    
    /**
     * @param provider    {HttpProvider}
     * @param options    {{code?: Cell, address?: Address | string, wc?: number}}
     */
    public init(options: TONContractOption) {
        self.options = options
        self.address = options.address
        self.wc = self.address?.wc ?? 0
    }

    /**
     * @return {Promise<Address>}
     */
    public func getAddress() throws -> TONAddress {
        if let address = self.address {
            return address
        } else {
            return try self.createStateInit().address
        }
    }

    /**
     * @private
     * @return {Cell} cell contains contact code
     */
    func createCodeCell() throws -> TONCell {
        guard let code = self.options?.code else {
            throw NSError()
        }
        
        return code
    }

    /**
     * Method to override
     * @protected
     * @return {Cell} cell contains contract data
     */
    func createDataCell() throws -> TONCell {
        return TONCell(raw: .init())
    }

    /**
     * @protected
     * @return {Promise<{stateInit: Cell, address: Address, code: Cell, data: Cell}>}
     */
    func createStateInit() throws -> TONStateInit {
        let codeCell = try self.createCodeCell()
        let dataCell = try self.createDataCell()
        let stateInit = try TONContract.createStateInit(code: codeCell, data: dataCell);
        let stateInitHash = try stateInit.hash()
        
        return try TONStateInit(
            stateInit: stateInit,
            address: .init("\(self.options?.wc ?? 0):\(Data(stateInitHash).hexString)"),
            code: codeCell,
            data: dataCell
        )
    }
    
    /**
     * @protected
     * @param   seqno?   {number}
     * @return {Cell}
     */
    func createSigningMessage(seqno: Int?) throws -> TONCell {
        let seqno = seqno ?? 0
        let cell = TONCell()
        try cell.raw.write(uint: UInt(seqno), 32);
        return cell
    }
    
    // MARK: - Static Implementation

    // _ split_depth:(Maybe (## 5)) special:(Maybe TickTock)
    // code:(Maybe ^Cell) data:(Maybe ^Cell)
    // library:(Maybe ^Cell) = StateInit;
    /**
     * @param code  {Cell}
     * @param data  {Cell}
     * @param library {null}
     * @param splitDepth {null}
     * @param ticktock  {null}
     * @return {Cell}
     */
    static func createStateInit(
        code: TONCell?,
        data: TONCell?,
        library: TONCell? = nil,
        splitDepth: TONCell? = nil,
        ticktock: TONCell? = nil
    ) throws -> TONCell {
        if library != nil, splitDepth != nil, ticktock != nil {
            throw NSError()
        }

        let stateInit = TONCell()
        
        let isSplitDepth: Bit = library == nil ? .zero : .one
        let isTicktock: Bit = ticktock == nil ? .zero : .one
        let isLibrary: Bit = library == nil ? .zero : .one
        let isCode: Bit = code == nil ? .zero : .one
        let isData: Bit = data == nil ? .zero : .one
        
        try stateInit.raw.write(
            bits: [
                isSplitDepth,
                isTicktock,
                isCode, isData,
                isLibrary
            ]
        )
        
        if let code = code {
            stateInit.refs.append(code)
        }
        
        if let data = data {
            stateInit.refs.append(data)
        }
        
        return stateInit
    }
    
}

// MARK: - Create Message Implementation

extension TONContract {
    /**
     * @param dest  {Address | string}
     * @param gramValue  {number | BN}
     * @param ihrDisabled  {boolean}
     * @param bounce  {null | boolean}
     * @param bounced {boolean}
     * @param src  {Address | string}
     * @param currencyCollection  {null}
     * @param ihrFees  {number | BN}
     * @param fwdFees  {number | BN}
     * @param createdLt  {number | BN}
     * @param createdAt  {number | BN}
     * @return {Cell}
     */
    static func createInternalMessageHeader(
        dest: String,
        gramValue: Int = 0,
        ihrDisabled: Bool = true,
        bounce: Bool? = nil,
        bounced: Bool = false,
        src: String,
        ihrFees: Int = 0,
        fwdFees: Int = 0,
        createdLt: UInt = 0,
        createdAt: UInt = 0
    ) throws -> TONCell {
        let message = TONCell()
        try message.raw.write(bit: false)
        try message.raw.write(bit: ihrDisabled)
        
        if let bounce = bounce {
            try message.raw.write(bit: bounce)
        } else {
            try message.raw.write(bit: dest.generateTONAddress().isBounceable);
        }
        
        try message.raw.write(bit: bounced)
        
        let srcAddress = try? TONAddress.parseFriendlyAddress(src)
        let dstAddress = try TONAddress.parseFriendlyAddress(dest)
        
        try message.raw.write(address: nil)
        try message.raw.write(address: dstAddress)
        try message.raw.write(grams: gramValue)
        try message.raw.write(bit: false)
        try message.raw.write(grams: ihrFees)
        try message.raw.write(grams: fwdFees)
        try message.raw.write(uint: createdLt, 64)
        try message.raw.write(uint: createdAt, 32)
        return message
    }
    
    /**
     * @param dest  {Address | string}
     * @param src  {Address | string}
     * @param importFee  {number | BN}
     * @return {Cell}
     */
    static func createExternalMessageHeader(
        dest: TONAddress,
        src: TONAddress? = nil,
        importFee: Int = 0
    ) throws -> TONCell {
        let message = TONCell()
        try message.raw.write(uint: 2, 2)
        try message.raw.write(address: src)
        try message.raw.write(address: dest)
        try message.raw.write(grams: importFee)
        return message
    }
    
    /**
     * Create CommonMsgInfo contains header, stateInit, body
     * @param header {Cell}
     * @param stateInit?  {Cell}
     * @param body?  {Cell}
     * @return {Cell}
     */
    static func createCommonMsgInfo(
        header: TONCell,
        stateInit: TONCell? = nil,
        body: TONCell? = nil
    ) throws -> TONCell {
        let commonMsgInfo = TONCell()
        try commonMsgInfo.write(cell: header)

        if let stateInit = stateInit {
            try commonMsgInfo.raw.write(bit: true)
            //-1:  need at least one bit for body
            // TODO we also should check for free refs here
            // TODO: temporary always push in ref because WalletQueryParser can parse only ref
            if false && (commonMsgInfo.raw.getFreeBits() - 1 >= stateInit.raw.getUsedBits()) {
                try commonMsgInfo.raw.write(bit: false)
                try commonMsgInfo.write(cell: stateInit)
            } else {
                try commonMsgInfo.raw.write(bit: true)
                commonMsgInfo.refs.append(stateInit)
            }
        } else {
            try commonMsgInfo.raw.write(bit: false)
        }
        
        // TODO we also should check for free refs here
        if let body = body {
            if commonMsgInfo.raw.getFreeBits() >= body.raw.getUsedBits() {
                try commonMsgInfo.raw.write(bit: false)
                try commonMsgInfo.write(cell: body)
            } else {
                try commonMsgInfo.raw.write(bit: true)
                commonMsgInfo.refs.append(body)
            }
        } else {
            try commonMsgInfo.raw.write(bit: false)
        }
        
        return commonMsgInfo
    }
    
}
