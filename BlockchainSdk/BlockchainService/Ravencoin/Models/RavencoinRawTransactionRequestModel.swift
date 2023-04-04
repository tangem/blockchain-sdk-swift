//
//  RavencoinRawTransactionRequestModel.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 03.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct RavencoinRawTransactionRequestModel: Encodable {
    let rawtx: String
}
