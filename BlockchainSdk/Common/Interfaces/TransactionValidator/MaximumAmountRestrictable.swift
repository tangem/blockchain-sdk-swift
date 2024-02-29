//
//  MaximumAmountRestrictable.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 29.02.2024.
//

import Foundation

protocol MaximumAmountRestrictable {
    func validateMaximumAmountRestrictable(amount: Amount, fee: Amount) throws
}
