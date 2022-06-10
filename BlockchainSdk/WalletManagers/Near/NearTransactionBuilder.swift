//
//  NearTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 11.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class NearTransactionBuilder {
    func build(from tx: Transaction) {
    }
}

fileprivate struct NearTransaction: Encodable {
    let signerId: String
    let signerPublicKey: [UInt8]
    let receiverId: String
    /// Call Access view list key
    let nonceForPublicKey: UUID = UUID()
    let action: String = "Transfer"
    /// Call Last block request, decode from base58 last hash
    let blockHash: [UInt8]
}
