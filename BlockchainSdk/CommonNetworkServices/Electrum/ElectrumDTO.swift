//
//  ElectrumDTO.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 11.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum ElectrumDTO {
    enum Response {
        struct Balance: Decodable {
            let confirmed: Int
            let unconfirmed: Int
        }
        
        struct History: Decodable {
            let height: Int
            let txHash: String
        }
        
        struct ListUnspent: Decodable {
            let txPos: Int
            let txHash: String
            let value: Int
            let height: String
        }
        
        struct Broadcast: Decodable {
            let txPos: Int
            let txHash: String
            let value: Int
            let height: String
        }
    }
}
