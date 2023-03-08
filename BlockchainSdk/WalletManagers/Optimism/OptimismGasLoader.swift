//
//  OptimismGasLoader.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 14.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol OptimismGasLoader {
    func getLayer1GasPrice() -> AnyPublisher<BigUInt, Error>
    func getLayer1GasLimit(data: String) -> AnyPublisher<BigUInt, Error>
}
