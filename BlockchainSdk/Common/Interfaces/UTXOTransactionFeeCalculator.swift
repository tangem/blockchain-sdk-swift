//
//  UTXOTransactionFeeCalculator.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 01.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol UTXOTransactionFeeCalculator {
    func calculateFee(satoshiPerByte: Int, amount: Amount, destination: String) -> Fee
}

