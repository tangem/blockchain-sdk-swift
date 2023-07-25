//
//  ChiaConstans.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 17.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/*
 - PuzzleHash Chia documentation - https://docs.chia.net/guides/crash-course/signatures/
 - Сurried and serialized signature.clsp (https://github.com/Chia-Network/chialisp-crash-course/blob/af620db2505db507b348d4f036dc4955fa81a004/signature.clsp)
 */

enum ChiaConstant: String {
    case puzzleReveal = "ff02ffff01ff02ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff0bff80808080ff80808080ff0b80ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b0"
    case fingerprint = "ff018080"
    case genesisChallengeMainnet = "ccd5bb71183532bff220ba46c268991a3ff07eb358e8255a65c30a2dce0e5fbb"
    case genesisChallengeTestnet = "ae83525ba8d1dd3f09b277de18ca3e43fc0af20d20c4b3e92ef2a48bd291ccb2"
    case AUG_SCHEME_DST = "BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_AUG_"
    
    static func getPuzzle(walletPublicKey: Data) -> Data {
        return Data(hex: ChiaConstant.puzzleReveal.rawValue) + walletPublicKey + Data(hex: ChiaConstant.fingerprint.rawValue)
    }
    
    static func getPuzzleHash(address: String) throws -> Data {
        let bech32 = Bech32(constant: .bech32m)
        let dataBytes = try bech32.decode(address).checksum
        return try Data(bech32.convertBits(data: dataBytes.bytes, fromBits: 5, toBits: 8, pad: false))
    }
    
    static func genesisChallenge(isTestnet: Bool) -> String {
        return isTestnet ? ChiaConstant.genesisChallengeTestnet.rawValue : ChiaConstant.genesisChallengeMainnet.rawValue
    }
}

extension ChiaConstant {
    enum HRP: String {
        case txch, xch
        
        init(isTestnet: Bool) {
            self = isTestnet ? .txch : .xch
        }
    }
}
