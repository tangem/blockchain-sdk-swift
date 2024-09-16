//
//  KaspaFeeParameters.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 29.07.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct KaspaFeeParameters: FeeParameters {
    public let mass: Decimal
    public let feeRate: Decimal
    
    public init(mass: Decimal, feeRate: Decimal) {
        self.mass = mass
        self.feeRate = feeRate
    }
}
