//
//  FeeResourceRestrictable.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 06.06.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol FeeResourceRestrictable {
    func validateFeeResource(amount: Amount, fee: Amount) throws
}

extension FeeResourceRestrictable where Self: WalletProvider {
    func validateFeeResource(amount: Amount, fee: Amount) throws {
        guard case let .feeResource(type) = fee.type else {
            throw ValidationError.invalidFee
        }
        
        let currentFeeResource = wallet.amounts[fee.type]?.value ?? .zero
        let maxFeeResource = wallet.amounts[amount.type]?.value ?? .zero
        let availableBalanceForTransfer = currentFeeResource - fee.value
        
        if amount.value == maxFeeResource {
            throw ValidationError.invalidMaxAmount(validMax: availableBalanceForTransfer)
        }
        
        if amount.value > availableBalanceForTransfer {
            throw ValidationError.insufficientFeeResource(
                type: type,
                current: currentFeeResource,
                max: maxFeeResource
            )
        }
    }
}
