//
//  NetworkProviderConfiguration.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 25.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Moya

struct NetworkProviderConfiguration {
    let shouldAddNetworkLogger: Bool
    let urlSessionConfiguration: URLSessionConfiguration

    init(
        shouldAddNetworkLogger: Bool = true,
        urlSessionConfiguration: URLSessionConfiguration = .standart
    ) {
        self.shouldAddNetworkLogger = shouldAddNetworkLogger
        self.urlSessionConfiguration = urlSessionConfiguration
    }
    
    var plugins: [PluginType] {
        if shouldAddNetworkLogger {
            return [NetworkLoggerPlugin()]
        }
        
        return []
    }
}

private extension URLSessionConfiguration {
    static let standart: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 30
        return configuration
    }()
}
