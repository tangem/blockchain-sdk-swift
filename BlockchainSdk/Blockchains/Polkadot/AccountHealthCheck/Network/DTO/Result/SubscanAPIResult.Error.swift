//
//  SubscanAPIResult.Error.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 21.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// thrown on 4xx/5xx
extension SubscanAPIResult {
    struct Error: Swift.Error, Decodable {
        let code: Int
        let message: String?
    }
}
