//
//  NetworkProviderConfiguration.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 25.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Moya
import TangemSdk

public struct NetworkProviderConfiguration {
    let logger: LoggerType
    let urlSessionConfiguration: URLSessionConfiguration
    let credentials: Credentials?

    public init(
        logger: LoggerType = .default,
        urlSessionConfiguration: URLSessionConfiguration = .standart,
        credentials: Credentials? = nil
    ) {
        self.logger = logger
        self.urlSessionConfiguration = urlSessionConfiguration
        self.credentials = credentials
    }
    
    var plugins: [PluginType] {
        var plugins: [PluginType] = []

        if let logOptions = logger.logOptions {
            let configuration = NetworkLoggerPlugin.Configuration(output: NetworkLoggerPlugin.tangemSdkLoggerOutput,
                                                                  logOptions: logOptions)
            plugins.append(NetworkLoggerPlugin(configuration: configuration))
        }

        if let credentials {
            plugins.append(CredentialsPlugin { _ -> URLCredential? in
                    .init(user: credentials.user,
                          password: credentials.password,
                          persistence: .none)
            })
        }
        
        return plugins
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
        configuration.timeoutIntervalForRequest = 100
        configuration.timeoutIntervalForResource = 30
        return configuration
    }()
}

// MARK: - Moya + TangemSdk

public extension NetworkLoggerPlugin {
    static func tangemSdkLoggerOutput(target: TargetType, items: [String]) {
        for item in items {
            Log.network(item)
        }
    }
}
