//
//  HederaNetworkParams.CreateAccount.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 08.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension HederaNetworkParams {
    struct CreateAccount: Encodable {
        let networkId: String
        let publicWalletKey: String
    }
}
