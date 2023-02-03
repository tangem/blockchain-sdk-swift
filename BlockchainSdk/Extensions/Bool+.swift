//
//  Bool+.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 23.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public extension Bool {
    
    static func ^ (left: Bool, right: Bool) -> Bool {
        return left != right
    }
    
}
