//
//  FilecoinTransactionBodyConverter.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 27.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum FilecoinDTOMapper {
    static func convertTransactionBody(from transactionInfo: FilecoinTxInfo) -> FilecoinTransactionBody {
        FilecoinTransactionBody(
            sourceAddress: transactionInfo.sourceAddress,
            destinationAddress: transactionInfo.destinationAddress,
            amount: "\(transactionInfo.amount)",
            nonce: transactionInfo.nonce,
            gasUnitPrice: nil,
            gasLimit: nil,
            gasPremium: nil
        )
    }
}
