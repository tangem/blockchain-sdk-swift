//
//  FeeResourceRestrictable.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 06.06.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol FeeResourceRestrictable {
    var feeResourceType: FeeResourceType { get }
    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws
}
