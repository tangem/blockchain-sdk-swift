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
        let cumulativeExecutionCost: Decimal
        let cumulativeSendCost: Decimal
    }

    let senderIsReceiver: Costs
    let senderIsNotReceiver: Costs
}
