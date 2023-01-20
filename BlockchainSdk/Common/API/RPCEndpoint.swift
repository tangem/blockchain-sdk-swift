//
//  RPCEndpoint.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 22.12.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public struct RPCEndpoint: Hashable, Codable {
    public let url: URL
    
    public let apiKeyHeaderName: String?
    public let apiKeyHeaderValue: String?
    
    public init(url: URL, apiKeyHeaderName: String? = nil, apiKeyHeaderValue: String? = nil) {
        self.url = url
        
        self.apiKeyHeaderName = apiKeyHeaderName
        self.apiKeyHeaderValue = apiKeyHeaderValue
    }
}
