//
//  Page.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 26.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct Page {
    public let number: Int
    public let size: Int
    
    public init(number: Int, size: Int = 20) {
        self.number = number
        self.size = size
    }
}
