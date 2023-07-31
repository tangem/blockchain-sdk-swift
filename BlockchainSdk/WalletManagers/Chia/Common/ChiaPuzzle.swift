//
//  ChiaPuzzle.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 31.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// PuzzleHash Chia documentation - https://docs.chia.net/guides/crash-course/signatures/
struct ChiaPuzzle {
    static func getPuzzle(walletPublicKey: Data) -> Data {
        return Data(hex: ChiaConstant.puzzleReveal) + walletPublicKey + Data(hex: ChiaConstant.fingerprint)
    }
    
    static func getPuzzleHash(address: String) throws -> Data {
        let bech32 = Bech32(variant: .bech32m)
        let dataBytes = try bech32.decode(address).checksum
        return try Data(bech32.convertBits(data: dataBytes.bytes, fromBits: 5, toBits: 8, pad: false))
    }
}
