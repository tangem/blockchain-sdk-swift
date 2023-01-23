//
//  TONContract.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 18.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSdk
import Foundation

public struct TONContractOption {
    public let code: TONCell?
    public let address: TONAddress?
    public let walletId: String?
    public let wc: Int?
}

public struct TONStateInit {
    public let code: TONCell
    public let address: TONAddress
    public let wc: Int
}

open class TONContract {
    
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
    public func createStateInit() throws -> TONStateInit {
        let codeCell = try self.createCodeCell()
        let dataCell = try self.createDataCell()
        let stateInit = try TONContract.createStateInit(code: codeCell, data: dataCell);
        let stateInitHash = try stateInit.hash()
        
        return try TONStateInit(
            code: codeCell,
            address: .init("\(self.options?.wc ?? 0):\(Data(stateInitHash).hexString)"),
            wc: options?.wc ?? 0
        )
    }

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
        
        try stateInit.raw.append(
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
        
        stateInit.raw.append(bytes: [UInt8](repeating: 0, count: 127))
        
        return stateInit
    }
    
}

// MARK: - Create Message Implementation

extension TONContract {
    
    //ext_in_msg_info$10 src:MsgAddressExt dest:MsgAddressInt
    //import_fee:Grams = CommonMsgInfo;
    /**
     * @param dest  {Address | string}
     * @param src  {Address | string}
     * @param importFee  {number | BN}
     * @return {Cell}
     */
    static func createExternalMessageHeader(
        dest: String,
        src: String,
        importFee: Int = 0
    ) throws -> TONCell {
        throw NSError()
    }
    
    //int_msg_info$0 ihr_disabled:Bool bounce:Bool
    //src:MsgAddressInt dest:MsgAddressInt
    //value:CurrencyCollection ihr_fee:Grams fwd_fee:Grams
    //created_lt:uint64 created_at:uint32 = CommonMsgInfo;
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
        createdLt: UInt64 = 0,
        createdAt: UInt64 = 0
    ) throws -> TONCell {
        let message = TONCell()
        try message.raw.write(bit: false)
        try message.raw.write(bit: ihrDisabled)
        
        if let bounce = bounce {
            try message.raw.write(bit: bounce)
        } else {
            try message.raw.write(bit: dest.generateTONAddress().isBounceable);
        }
        
        // MARK: - TODO
        
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
        header: TONCell?,
        stateInit: TONCell? = nil,
        body: TONCell? = nil
    ) throws -> TONCell {
        throw NSError()
    }
    
}
