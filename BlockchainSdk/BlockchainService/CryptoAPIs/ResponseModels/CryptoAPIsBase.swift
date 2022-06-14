//
//  CryptoAPIsBaseResponse.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 10.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct CryptoAPIsBase<T: Codable>: Codable {
    let apiVersion: String
    let requestId: String
    let context: String?
    let data: T
}

struct CryptoAPIsBaseItems<Item: Codable>: Codable {
    let limit: Int
    let offset: Int
    let total: Int
    let items: [Item]
}

struct CryptoAPIsBaseItem<Item: Codable>: Codable {
    let item: Item
}
