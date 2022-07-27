//
//  NetworkProviderConfiguration.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 25.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Moya

public struct NetworkProviderConfiguration {
    let logger: LoggerType
    let urlSessionConfiguration: URLSessionConfiguration

    public init(
        logger: LoggerType = .default,
        urlSessionConfiguration: URLSessionConfiguration = .standart
    ) {
        self.logger = logger
        self.urlSessionConfiguration = urlSessionConfiguration
    }
    
    var plugins: [PluginType] {
        if let logOptions = logger.logOptions {
            return [NetworkLoggerPlugin(configuration: .init(logOptions: logOptions))]
        }
        
        return []
    }
}

public extension NetworkProviderConfiguration {
    enum LoggerType {
        case none
        case `default`
        case verbose
        
        var logOptions: NetworkLoggerPlugin.Configuration.LogOptions? {
            switch self {
            case .none: return nil
            case .default: return .default
            case .verbose: return .verbose
            }
        }
    }
}

public extension URLSessionConfiguration {
    static let standart: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 30
        return configuration
    }()
}
