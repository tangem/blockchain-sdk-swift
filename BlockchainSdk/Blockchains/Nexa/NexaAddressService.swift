//
//  NexaAddressService.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 19.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

import class BitcoinCore.CashAddrBech32

public class NexaAddressService {
    private let cashAddrService: CashAddrService
    
    private let prefix = "nexa"
    private let version: NexaAddressComponents.NexaAddressType = .TEMPLATE
    private let scriptChunkHelper = ScriptChunkHelper()
    
    init(cashAddrService: CashAddrService) {
        self.cashAddrService = cashAddrService
    }

    func parse(_ address: String) -> NexaAddressComponents? {
        guard
            let (prefix, data) = CashAddrBech32.decode(address),
            !data.isEmpty,
            let firstByte = data.first,
            let type = NexaAddressComponents.NexaAddressType(rawValue: firstByte)
        else {
            return nil
        }

        return NexaAddressComponents(
            prefix: prefix,
            type: type,
            hash: data.dropFirst()
        )
    }
}


// MARK: - AddressProvider

@available(iOS 13.0, *)
extension NexaAddressService: AddressProvider {
    public func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let compressedKey = try Secp256k1Key(with: publicKey.blockchainKey).compress()
        
        let constraint = scriptChunkHelper.scriptData(for: compressedKey, preferredLengthEncoding: -1)!
        let constraintHash = constraint.sha256Ripemd160
        let resultHash = Data(0x11)
        
        let address = CashAddrBech32.encode(resultHash, prefix: prefix)
        return PlainAddress(value: address, publicKey: publicKey, type: addressType)
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension NexaAddressService: AddressValidator {
    public func validate(_ address: String) -> Bool {
        guard
            let components = parse(address),
            components.prefix == prefix
        else {
            return false
        }

        let validStartLetters = ["q", "p", "n"]
        guard
            let firstAddressLetter = address.dropFirst(prefix.count + 1).first,
            validStartLetters.contains(String(firstAddressLetter))
        else {
            return false
        }

        return true
    }
}

extension NexaAddressService {
    struct NexaAddressComponents {
        let prefix: String
        let type: NexaAddressType
        let hash: Data
        
        enum NexaAddressType: UInt8 {
            case P2PKH = 0
            case SCRIPT = 8
            case TEMPLATE = 152
            case GROUP = 88
        }
    }
}
