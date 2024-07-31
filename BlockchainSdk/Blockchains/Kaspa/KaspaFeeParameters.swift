//
//  KaspaFeeParameters.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 29.07.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct KaspaFeeParameters: FeeParameters {
    public let valuePerUtxo: Decimal
    public let utxoCount: Int
    
    public init(valuePerUtxo: Decimal, utxoCount: Int) {
        self.valuePerUtxo = valuePerUtxo
        self.utxoCount = utxoCount
    }
}
