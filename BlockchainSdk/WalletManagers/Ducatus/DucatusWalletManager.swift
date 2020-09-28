//
//  DucatusWalletManager.swift
//  Alamofire
//
//  Created by Alexander Osokin on 28.09.2020.
//

import Foundation

class DucatusWalletManager: BitcoinWalletManager {
    override func updateWallet(with response: BitcoinResponse) {
        wallet.add(coinValue: response.balance)
        txBuilder.unspentOutputs = response.txrefs
        if response.hasUnconfirmed {
            if wallet.transactions.isEmpty {
                wallet.addPendingTransaction()
            }
        } else {
            for index in wallet.transactions.indices {
                if let txDate = wallet.transactions[index].date {
                    let interval = Date().timeIntervalSince(txDate)
                    if interval > 30 {
                        wallet.transactions[index].status = .confirmed
                    }
                }
            }
        }
    }
}
