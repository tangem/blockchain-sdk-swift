//
//  VeChainFeeCalculator.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 22.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import class TangemSdk.Log

struct VeChainFeeCalculator {
    let blockchain: Blockchain

    func fee(for input: Input, amountType: Amount.AmountType) -> Fee {
        // See https://learn.vechain.energy/Vechain/How-to/Calculate-Gas-Fees/#priority--gaspricecoef for details
        let gasPriceCoefficient = Decimal(1) + ((Decimal(1) / Decimal(Constants.maxGasPriceCoefficient)) * Decimal(input.gasPriceCoefficient))
        let totalGas = Decimal(gas(for: input.clauses))
        let value = (totalGas * gasPriceCoefficient) / Constants.gasPrice
        let amount = Amount(with: blockchain, type: amountType, value: value)
        let priority = transactionPriority(from: input.gasPriceCoefficient)
        let parameters = priority.flatMap(VeChainFeeParams.init)

        return Fee(amount, parameters: parameters)
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

        // The official VeChain wallets (VeWorld, Sync2) double the amount of gas for transactions with 
        // virtual machine invocation (30k instead of 15k as stated in the gas calculation guide above)
        //
        // Replicating this behavior here just to be on the safe side
        let vmInvocationCost = payloadCost > 0 ? 15000 * 2 : 0

        return baseCost + clausesCost + payloadCost + vmInvocationCost
    }

    func gasPriceCoefficient(from priority: VeChainFeeParams.TransactionPriority) -> UInt {
        switch priority {
        case .low:
            return Constants.lowGasPriceCoefficient
        case .medium:
            return Constants.mediumGasPriceCoefficient
        case .high:
            return Constants.highGasPriceCoefficient
        }
    }

    private func transactionPriority(from gasPriceCoefficient: UInt) -> VeChainFeeParams.TransactionPriority? {
        switch gasPriceCoefficient {
        case Constants.lowGasPriceCoefficient:
            return .low
        case Constants.mediumGasPriceCoefficient:
            return .medium
        case Constants.highGasPriceCoefficient:
            return .high
        default:
            let message = "VeChainFeeCalculator: unknown 'gasPriceCoefficient' value '\(gasPriceCoefficient)' received"
            assertionFailure(message)
            Log.error(message)
            return nil
        }
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

// MARK: - Constants

private extension VeChainFeeCalculator {
    enum Constants {
        /// Actual base gas price value for the time being, for details visit
        /// https://docs.vechain.org/introduction-to-vechain/dual-token-economic-model/vethor-vtho#vtho-transaction-cost-formula
        static let gasPrice: Decimal = 100_000

        static let lowGasPriceCoefficient: UInt = 0
        static let mediumGasPriceCoefficient: UInt = 127
        static let highGasPriceCoefficient: UInt = 255
        static var maxGasPriceCoefficient: UInt { highGasPriceCoefficient }
    }
}
