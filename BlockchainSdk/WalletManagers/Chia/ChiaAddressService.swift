//
//  ChiaAddressService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 10.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/*
 PuzzleHash Chia documentation - https://docs.chia.net/guides/crash-course/signatures/
 */

public struct ChiaAddressService: AddressService {
    // MARK: - Private Properties
    
    private(set) var isTestnet: Bool
    
    private let constans = ChiaAddressService.Constans.self
    
    // MARK: - Implementation
    
    public func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> PlainAddress {
        let puzzle = Data(hex: constans.puzzleReveal.rawValue) + (publicKey.blockchainKey) + Data(hex: constans.fingerprint.rawValue)
        
        let puzzleHash = try ClvmNode.Decoder(programBytes: puzzle.bytes).deserialize().hash()
        let hrp = HRP(isTestnet: isTestnet).rawValue
        let encodeValue = Bech32(variant: .bech32m).encode(hrp, values: puzzleHash)
        
        return .init(value: encodeValue, publicKey: publicKey, type: addressType)
    }
    
    public func validate(_ address: String) -> Bool {
        do {
            let result = try Bech32(variant: .bech32m).decode(address)
            return HRP(isTestnet: isTestnet).rawValue == result.hrp
        } catch {
            assertionFailure(error.localizedDescription)
            return false
        }
    }
    
}

extension ChiaAddressService {
    enum HRP: String {
        case txch, xch
        
        init(isTestnet: Bool) {
            self = isTestnet ? .txch : .xch
        }
    }
}

extension ChiaAddressService {
    enum ChiaAddressError: Error {
        case invalidHumanReadablePart
    }
}

extension ChiaAddressService {
    enum Constans: String {
        case puzzleReveal = "ff02ffff01ff02ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff0bff80808080ff80808080ff0b80ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b0"
        case fingerprint = "ff018080"
    }
}
