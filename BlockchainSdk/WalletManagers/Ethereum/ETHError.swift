//
//  ETHError.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 17.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ETHError: Error, LocalizedError, DetailedError {
    case failedToParseTxCount
    case failedToParseBalance(value: String, address: String, decimals: Int)
    case failedToParseGasLimit
    case failedToParseAllowance
    case gasRequiredExceedsAllowance
    case unsupportedFeature
    
    public var errorDescription: String? {
        switch self {
        case .failedToParseTxCount:
            return "eth_tx_count_parse_error".localized
        case .failedToParseBalance:
            return "eth_balance_parse_error".localized
        case .failedToParseGasLimit: // TODO: refactor
            return "failedToParseGasLimit"
        case .failedToParseAllowance:
            return "failedToParseAllowance"
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
