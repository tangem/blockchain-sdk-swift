//
//  ChiaAddressService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 10.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore

public struct ChiaAddressService: AddressService {
    // MARK: - Private Properties
    
    private(set) var isTestnet: Bool
    
    // MARK: - Implementation
    
    public func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> PlainAddress {
        let puzzle = Data(hex: "ff02ffff01ff02ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff0bff80808080ff80808080ff0b80ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b0") + (publicKey.blockchainKey) + Data(hex: "ff018080")
        
        let puzzleHash = try ClvmNode.Decoder(programBytes: puzzle.bytes).deserialize().hash()
        let encodeValue = Bech32(isBech32m: true).encode(HRP(isTestnet: isTestnet).rawValue, values: puzzleHash)
        
        return .init(value: encodeValue, publicKey: publicKey, type: addressType)
    }
    
    public func validate(_ address: String) -> Bool {
        do {
            try Bech32(isBech32m: true).decode(address)
            return true
        } catch {
            assertionFailure(error.localizedDescription)
            return false
        }
    }
    
}

extension ChiaAddressService {
    public enum HRP: String {
        case txch, xch
        
        public init(isTestnet: Bool) {
            self = isTestnet ? .txch : .xch
        }
    }
}

extension ChiaAddressService {
    public enum ChiaAddressError: Error {
        case invalidHumanReadablePart
    }
}
