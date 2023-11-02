//
//  NEARProtocolConfig.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 23.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct NEARProtocolConfig {
    struct Costs {
        /// `transfer_cost.execution` + `action_receipt_creation_config.execution`.
        let cumulativeExecutionCost: Decimal
        /// `transfer_cost.send_not_sir` + `action_receipt_creation_config.send_not_sir` or
        /// `transfer_cost.send_sir` + `action_receipt_creation_config.send_sir`.
        let cumulativeSendCost: Decimal
    }

    let senderIsReceiver: Costs
    let senderIsNotReceiver: Costs
}
