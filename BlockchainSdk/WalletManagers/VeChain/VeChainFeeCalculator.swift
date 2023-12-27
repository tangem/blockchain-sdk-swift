//
//  VeChainFeeCalculator.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 22.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct VeChainFeeCalculator {
    let blockchain: Blockchain

    /// Actual base gas price value, for details visit
    /// https://docs.vechain.org/introduction-to-vechain/dual-token-economic-model/vethor-vtho#vtho-transaction-cost-formula
    private static let gasPrice: Decimal = 100_000

    func fee(for input: Input, amountType: Amount.AmountType) -> Fee {
        // See https://learn.vechain.energy/Vechain/How-to/Calculate-Gas-Fees/#priority--gaspricecoef for details
        let gasPriceCoefficient = Decimal(1) + ((Decimal(1) / Decimal(255)) * Decimal(input.gasPriceCoefficient))
        let totalGas = Decimal(gas(for: input.clauses))
        let value = (totalGas * gasPriceCoefficient) / Self.gasPrice
        let amount = Amount(with: blockchain, type: amountType, value: value)

        return Fee(amount)
    }

    func gas(for clauses: [Clause]) -> Int {
        // Intrinsic gas (bytes submitted w/o making changes by using a contract):
        // - The base fee for a transaction is 5000.
        // - Each clause in the transaction incurs a cost of 16000.
        // - Zero bytes in the transaction cost 4 each.
        // - Non-zero bytes in the transaction cost 68 each.
        // - Virtual machine invocation costs 15000.
        //
        // See https://learn.vechain.energy/Vechain/How-to/Calculate-Gas-Fees/#intrinsic-gas--bytes-submitted for details

        let baseCost = 5000

        let clausesCost = clauses.count * 16000

        let payloadCost = clauses.reduce(into: 0) { partialResult, element in
            partialResult += element.payload.reduce(into: 0) { partialResult, element in
                partialResult += element == 0x0 ? 4 : 68
            }
        }

        let vmInvocationCost = payloadCost > 0 ? 15000 : 0

        return baseCost + clausesCost + payloadCost + vmInvocationCost
    }
}

// MARK: - Auxiliary types

extension VeChainFeeCalculator {
    /// Just a shim for the `WalletCore.TW_VeChain_Proto_SigningInput` type 
    /// because we don't want to have `WalletCore` as a dependency here.
    struct Input {
        let gasPriceCoefficient: UInt
        let clauses: [Clause]
    }

    /// Just a shim for the `WalletCore.TW_VeChain_Proto_Clause` type 
    /// because we don't want to have `WalletCore` as a dependency here.
    struct Clause {
        let payload: Data
    }
}
