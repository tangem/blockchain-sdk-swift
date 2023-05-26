//
//  ETHError.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 17.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ETHError: Error, LocalizedError, DetailedError {
    case failedToParseBalance(value: String, address: String, decimals: Int)
    case gasRequiredExceedsAllowance
    case unsupportedFeature
    
    public var errorDescription: String? {
        switch self {
        case .failedToParseBalance:
            return WalletError.failedToParseNetworkResponse.errorDescription
        case .gasRequiredExceedsAllowance:
            return "eth_gas_required_exceeds_allowance".localized
        case .unsupportedFeature:
            return "unsupportedFeature"
        }
    }
    
    public var detailedDescription: String? {
        switch self {
        case .failedToParseBalance(let value, let address, let decimals):
            return "value:\(value), address:\(address), decimals:\(decimals)"
        default:
            return nil
        }
    }
}
