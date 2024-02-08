//
//  HederaNetworkResult.CreateAccount.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 08.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension HederaNetworkResult {
    struct CreateAccount: Decodable {
        struct AccountData: Decodable {
            let accountId: String
            let publicWalletKey: String
        }

        struct Error: Decodable {
            let code: Int
            let message: String?
        }

        let status: Bool
        let data: AccountData?
        let error: Error?
    }
}
