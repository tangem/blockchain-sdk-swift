//
//  CryptoAPIsBaseResponse.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 10.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct CryptoAPIsBaseResponse: Codable {
    let apiVersion: String?
    let requestId: String?
    let context: String?
    let data: CryptoAPIsDataResponse?
}
