//
//  HederaTransactionIdConverter.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 16.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct HederaTransactionIdConverter {
    /// Conversion from `0.0.3573746@1714011910.250372802` to `0.0.3573746-1714011910-250372802`.
    func convertFromConsensusToMirror(_ transactionId: String) throws -> String {
        let firstStageParts = transactionId.split(separator: "@")

        guard firstStageParts.count == 2 else {
            throw ConversionError.conversionFromConsensusToMirrorFailed(transactionId: transactionId)
        }

        let intermediateResult = firstStageParts[0] + "-" + firstStageParts[1]
        let secondStageParts = intermediateResult.split(separator: ".")

        guard secondStageParts.count >= 2, let lastPart = secondStageParts.last else {
            throw ConversionError.conversionFromConsensusToMirrorFailed(transactionId: transactionId)
        }

        return secondStageParts.dropLast().joined() + "-" + lastPart
    }

    /// Conversion from `0.0.3573746-1714011910-250372802` to `0.0.3573746@1714011910.250372802`
    func convertFromMirrorToConsensus(_ transactionId: String) throws -> String {
        let firstStageParts = transactionId.split(separator: "-")

        guard firstStageParts.count >= 2, let lastPart = firstStageParts.last else {
            throw ConversionError.conversionFromMirrorToConsensusFailed(transactionId: transactionId)
        }

        let intermediateResult = firstStageParts.dropLast().joined() + "." + lastPart
        let secondStageParts = intermediateResult.split(separator: "-")

        guard secondStageParts.count == 2 else {
            throw ConversionError.conversionFromMirrorToConsensusFailed(transactionId: transactionId)
        }

        return secondStageParts[0] + "@" + secondStageParts[1]
    }
}

// MARK: - Auxiliary types

extension HederaTransactionIdConverter {
    enum ConversionError: Error {
        case conversionFromConsensusToMirrorFailed(transactionId: String)
        case conversionFromMirrorToConsensusFailed(transactionId: String)
    }
}
