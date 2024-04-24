//
//  CardanoWithdrawalRestrictable.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 19.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol CardanoWithdrawalRestrictable {
    func validateCardanoWithdrawal(amount: Amount, fee: Amount) throws
}
