//
//  AptosResponse+FeeParams.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 29.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension AptosResponse {
    struct Fee: Decodable {
        let deprioritizedGasEstimate: UInt64
        let gasEstimate: UInt64
        let prioritizedGasEstimate: UInt64
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            deprioritizedGasEstimate = try container.decode(UInt64.self, forKey: .deprioritizedGasEstimate)
            gasEstimate = try container.decode(UInt64.self, forKey: .gasEstimate)
            prioritizedGasEstimate = try container.decode(UInt64.self, forKey: .prioritizedGasEstimate)
        }

        private enum CodingKeys: String, CodingKey {
            case deprioritizedGasEstimate = "deprioritized_gas_estimate"
            case gasEstimate = "gas_estimate"
            case prioritizedGasEstimate = "prioritized_gas_estimate"
        }
    }
}
