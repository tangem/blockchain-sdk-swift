//
//  HederaTargetConfigurationFactory.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 02.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct HederaTargetConfigurationFactory {
    let isTestnet: Bool
    let sdkConfig: BlockchainSdkConfig
    let mirrorNodeAPIVersion: APIVersion

    func makeTargetConfigurations() -> [HederaTargetConfiguration] {
        if isTestnet {
            return [
                HederaTargetConfiguration(
                    baseURL: URL(string: "https://testnet.mirrornode.hedera.com/api/\(mirrorNodeAPIVersion.rawValue)")!
                ),
                HederaTargetConfiguration(
                    baseURL: URL(string: "https://pool.arkhia.io/hedera/testnet/api/\(mirrorNodeAPIVersion.rawValue)")!,
                    apiKeyHeaderName: Constants.xApiKeyHeaderName,
                    apiKeyHeaderValue: sdkConfig.hederaArkhiaApiKey
                ),
            ]
        }

        return [
            HederaTargetConfiguration(
                baseURL: URL(string: "https://mainnet-public.mirrornode.hedera.com/api/\(mirrorNodeAPIVersion.rawValue)")!
            ),
            HederaTargetConfiguration(
                baseURL: URL(string: "https://pool.arkhia.io/hedera/mainnet/api/\(mirrorNodeAPIVersion.rawValue)")!,
                apiKeyHeaderName: Constants.xApiKeyHeaderName,
                apiKeyHeaderValue: sdkConfig.hederaArkhiaApiKey
            ),
        ]
    }
}

// MARK: - Auxiliary types

extension HederaTargetConfigurationFactory {
    enum APIVersion {
        fileprivate var rawValue: String {
            switch self {
            case .v1:
                return "v1"
            }
        }

        case v1
    }
}
