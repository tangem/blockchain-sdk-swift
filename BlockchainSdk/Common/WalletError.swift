//
//  WalletError.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 05.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public enum WalletError: Error, LocalizedError {
    case noAccount(message: String)
    case failedToGetFee
    case failedToBuildTx
    case failedToParseNetworkResponse
    case failedToSendTx
    case failedToCalculateTxSize
    case empty
    case blockchainUnavailable(underlyingError: Error)
    
    public var errorDescription: String? {
        switch self {
        case .noAccount(let message):
            return message
        case .failedToGetFee:
            return "common_fee_error".localized
        case .failedToBuildTx:
            return "common_build_tx_error".localized
        case .failedToSendTx:
            return "common_send_tx_error".localized
        case .empty:
            return "Empty"
        case .failedToCalculateTxSize, 
             .failedToParseNetworkResponse,
             .blockchainUnavailable:
            return "generic_error_code".localized(errorCodeDescription)
        }
    }
    
    private var errorCodeDescription: String {
        return "wallet_error \(errorCode)"
    }
    
    private var errorCode: Int {
        switch self {
        case .noAccount:
            return 1
        case .failedToGetFee:
            return 2
        case .failedToBuildTx:
            return 3
        case .failedToParseNetworkResponse:
            return 4
        case .failedToSendTx:
            return 5
        case .failedToCalculateTxSize:
            return 6
        case .empty:
            return 7
        case .blockchainUnavailable:
            return 8
        }
    }
}
