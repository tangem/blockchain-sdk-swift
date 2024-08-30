//
//  FilecoinSignedTransactionBody.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 27.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct FilecoinSignedTransactionBody: Encodable {
    struct Signature: Encodable {
        let type: Int
        let signature: String
        
        enum CodingKeys: String, CodingKey {
            case type = "Type"
            case signature = "Data"
        }
    }
    
    let transactionBody: FilecoinTransactionBody
    let signature: Signature
    
    enum CodingKeys: String, CodingKey {
        case transactionBody = "Message"
        case signature = "Signature"
    }
}
