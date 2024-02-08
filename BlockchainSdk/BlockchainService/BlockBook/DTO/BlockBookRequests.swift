//
//  BlockBookRequests.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 08.02.2024.
//

import Foundation

struct SendTransactionRequest: Encodable {
    let jsonrpc = "2.0"
    let id: String
    let method: String
    let params: [String]
    
    init(signedTransaction: String) {
        self.id = "id"
        self.method = "sendrawtransaction"
        self.params = [signedTransaction]
    }
}
