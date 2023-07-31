//
//  PageParameters.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 26.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct PageParameters {
    public let page: Int
    public let pageSize: Int
    
    public init(page: Int, pageSize: Int = 20) {
        self.page = page
        self.pageSize = pageSize
    }
}
