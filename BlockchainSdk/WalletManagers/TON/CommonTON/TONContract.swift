//
//  TONContract.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 18.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

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
        return TONCell()
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
        throw NSError()
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
        
        stateInit.bytes.append(
            contentsOf: [
                isSplitDepth,
                isTicktock,
                isCode, isData,
                isLibrary
            ].bytes()
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
