//
//  DucatusWalletManager.swift
//  Alamofire
//
//  Created by Alexander Osokin on 28.09.2020.
//

import Foundation

class DucatusWalletManager: BitcoinWalletManager {
    override func updateWallet(with response: [BitcoinResponse]) {
        let singleResponse = response.first!
        wallet.add(coinValue: singleResponse.balance)
        txBuilder.unspentOutputs = singleResponse.unspentOutputs
        loadedUnspents = singleResponse.unspentOutputs
        if singleResponse.hasUnconfirmed {
            if wallet.pendingTransactions.isEmpty {
                wallet.addDummyPendingTransaction()
            }
        } else {
            wallet.clearPendingTransaction(older: 30)
        }
    }
}
