//
//  HederaCreateAccountRequest.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 08.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct HederaCreateAccountRequest {
    struct CardInfo {
        let cardId: String
        let cardPublicKey: String
    }

    let cardInfo: CardInfo
    let publicKey: Wallet.PublicKey
}
