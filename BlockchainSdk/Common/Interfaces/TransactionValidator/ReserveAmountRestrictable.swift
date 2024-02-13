//
//  ReserveAmountRestrictable.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 12.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol ReserveAmountRestrictable {
    func validateReserveAmountRestrictable(amount: Amount, addressType: ReserveAmountRestrictableAddressType) async throws
}

enum ReserveAmountRestrictableAddressType {
    case address(String)
    case new
}
