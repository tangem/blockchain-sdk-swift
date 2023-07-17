//
//  ChiaConstans.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 17.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum ChiaConstant: String {
    case puzzleReveal = "ff02ffff01ff02ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff0bff80808080ff80808080ff0b80ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b0"
    case fingerprint = "ff018080"
    
    static func getPuzzle(walletPublicKey: Data) -> Data {
        return Data(hex: ChiaConstant.puzzleReveal.rawValue) + walletPublicKey + Data(hex: ChiaConstant.fingerprint.rawValue)
    }
}
