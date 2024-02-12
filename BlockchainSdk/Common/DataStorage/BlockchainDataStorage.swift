//
//  BlockchainDataStorage.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 10.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol BlockchainDataStorage {
    associatedtype BlockchainData

    func get(key: String) async -> BlockchainData?
    func store(key: String, value: BlockchainData?) async
}
