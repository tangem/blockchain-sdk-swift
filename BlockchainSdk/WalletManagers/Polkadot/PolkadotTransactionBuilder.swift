//
//  PolkadotTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 28.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
//import ScaleCodec

class PolkadotTransactionBuilder {
    private let walletPublicKey: Data
    
    init(walletPublicKey: Data) {
        self.walletPublicKey = walletPublicKey
    }
    
    func buildForSign(transaction: Transaction, walletAmount: Decimal, isEstimated: Bool) {
        
    }
}
