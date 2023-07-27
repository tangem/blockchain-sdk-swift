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
    
    // MARK: - Implementation
    
    public func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> PlainAddress {
        let puzzle = ChiaConstant.getPuzzle(walletPublicKey: publicKey.blockchainKey)
        let puzzleHash = try ClvmNode.Decoder(programBytes: puzzle.bytes).deserialize().hash()
        let hrp = ChiaConstant.HRP(isTestnet: isTestnet).rawValue
        let encodeValue = Bech32(variant: .bech32m).encode(hrp, values: puzzleHash)
        
        return .init(value: encodeValue, publicKey: publicKey, type: addressType)
    }
    
    public func validate(_ address: String) -> Bool {
        do {
            let result = try Bech32(variant: .bech32m).decode(address)
            return ChiaConstant.HRP(isTestnet: isTestnet).rawValue == result.hrp
        } catch {
            assertionFailure(error.localizedDescription)
            return false
        }
    }
    
}

extension ChiaAddressService {
    enum ChiaAddressError: Error {
        case invalidHumanReadablePart
    }
}
