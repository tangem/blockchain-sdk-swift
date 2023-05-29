//
//  SmartContractProviderType.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 29.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol SmartContractProviderType: HostProvider {
    var url: URL { get }
}
