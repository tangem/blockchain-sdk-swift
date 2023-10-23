//
//  NEARTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 13.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore

final class NEARTransactionBuilder {
    private let blockchain: Blockchain

    init(
        blockchain: Blockchain
    ) {
        self.blockchain = blockchain
    }

    func buildForSign(transaction: Transaction) throws -> Data {
        // TODO: Andrey Fedorov - Add actual implementation (IOS-4071)
        return Data()
    }

    func buildForSend(transaction: Transaction, signature: Data) throws -> Data {
        // TODO: Andrey Fedorov - Add actual implementation (IOS-4071)
        return Data()
    }
}
