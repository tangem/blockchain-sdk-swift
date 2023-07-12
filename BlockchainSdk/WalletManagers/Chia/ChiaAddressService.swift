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
//        let puzzle = Data(hex: "ff02ffff01ff02ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff0bff80808080ff80808080ff0b80ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b0") + (publicKey.derivation?.derivedKey.publicKey ?? Data()) + Data(hex: "ff018080")
        
//        let puzzleHash = try ClvmNode.Decoder(programBytes: puzzle.bytes.map { UInt8($0) }).deserialize().hash()
//        let encodeValue = Bech32m(bech32m: true).encode(ChiaAddressService.HRP(isTestnet: isTestnet).rawValue, values: Data(puzzleHash))

//        return .init(value: encodeValue, publicKey: publicKey, type: addressType)
        
        throw NSError()
    }
    
    public func make() throws {
        let walletPublicKey = Data(hex: "b8f7dd239557ff8c49d338f89ac1a258a863fa52cd0a502e3aaae4b6738ba39ac8d982215aa3fa16bc5f8cb7e44b954d")
        
        let puzzle = (Data(hex: "ff02ffff01ff02ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff0bff80808080ff80808080ff0b80ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b0") + (walletPublicKey) + Data(hex: "ff018080")).bytes.map { Int8(bitPattern: $0) }
        
        let puzzleDeserialize = try ClvmNode.Decoder(programBytes: puzzle).deserialize()
        
        print(puzzleDeserialize.)
        
        print(puzzleHash.hex)
        
//        let encodeValue = Bech32m(bech32m: true).encode("txch", values: Data(hex: "aa0dc6276e519a604dd0a750b8efb53c5d65b55f189cc0ca29d498d45b69a216"))
//        
//        print(encodeValue)
    }
    
    public func validate(_ address: String) -> Bool {
        do {
            try Bech32m(bech32m: true).decode(address)
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
