//
//  BlockchainSdkError.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 27/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public enum BlockchainSdkError: Int, LocalizedError {
	case signatureCountNotMatched = 0
	case failedToCreateMultisigScript = 1
	case failedToConvertPublicKey = 2
	case notImplemented = -1000
    case decodingFailed
    case failedToLoadFee
    case failedToLoadTxDetails
    case failedToFindTransaction
    case failedToFindTxInputs
    case feeForPushTxNotEnough
    case networkProvidersNotSupportsRbf
    case wrongKey
    case wrongDerivationPath
	
	public var errorDescription: String? {
		switch self {
		case .signatureCountNotMatched, .notImplemented:
			// TODO: Replace with proper error message. Android sending instead of message just code, and client app decide what message to show to user
			return "\(rawValue)"
        case .failedToLoadFee:
            return "failed_to_load_fee_error".localized
        case .failedToFindTransaction:
            return "failed_to_find_transaction".localized
        case .failedToFindTxInputs:
            return "failed_to_find_tx_inputs".localized
        case .feeForPushTxNotEnough:
            return "fee_for_push_tx_not_enough".localized
        case .networkProvidersNotSupportsRbf:
            return "network_providers_not_supports_rbf".localized
		default:
			return "\(rawValue)"
		}
	}
}

public enum NetworkServiceError: Error {
    case notAvailable
}
