//
//  BlockchainSdkExampleViewModel.swift
//  BlockchainSdkExample
//
//  Created by Andrey Chukavin on 08.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

import BlockchainSdk
import TangemSdk

class BlockchainSdkExampleViewModel: ObservableObject {
    @AppStorage("destination") var destination: String = ""
    @AppStorage("amount") var amountToSend: String = ""
    @Published var feeDescription: String = ""
    @Published var transactionResult: String = ""

    private let sdk: TangemSdk
    private let walletManagerFactory = WalletManagerFactory(config: .init(blockchairApiKey: "", blockcypherTokens: [], infuraProjectId: ""))
    private var card: Card?
    private var blockchain: Blockchain
    @Published private(set) var transactionSender: TransactionSender?
    
    private var bag: Set<AnyCancellable> = []

    
    init() {
        var config = Config()
        config.attestationMode = .offline

        self.sdk = TangemSdk(config: config)
        
        self.blockchain = .solana(testnet: true)
    }
    
    func scanCardAndGetInfo() {
        sdk.scanCard { [weak self] result in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let card):
                self?.card = card
                self?.updateWalletManager()
            }
        }
    }
    
    func checkFee() {
        guard let amount = parseAmount() else {
            feeDescription = "Invalid amount"
            return
        }
        
        feeDescription = ""
        
        transactionSender?
            .getFee(amount: amount, destination: destination)
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                switch $0 {
                case .failure(let error):
                    print(error)
                    self?.feeDescription = error.localizedDescription
                case .finished:
                    break
                }
            } receiveValue: { [weak self] in
                self?.feeDescription = $0.map { $0.description }.joined(separator: "; ")
            }
            .store(in: &bag)
    }
    
    func sendTransaction() {
        guard let amount = parseAmount() else {
            transactionResult = "Invalid amount"
            return
        }
                
        let walletManager = transactionSender as! WalletManager
        walletManager.wallet.add(coinValue: 100)
        
        do {
            let transaction = try walletManager.createTransaction(
                amount: amount,
                fee: Amount(with: blockchain, value: 0),
                destinationAddress: destination
            ).get()
            
            transactionSender?
                .send(transaction, signer: sdk)
                .receive(on: RunLoop.main)
                .sink { [weak self] in
                    switch $0 {
                    case .failure(let error):
                        print(error)
                        self?.transactionResult = error.localizedDescription
                    case .finished:
                        self?.transactionResult = "OK"
                    }
                } receiveValue: {

                }
                .store(in: &bag)
        } catch {
            print(error)
            transactionResult = error.localizedDescription
        }
    }
    
    private func updateWalletManager() {
        guard let card = card else {
            return
        }

        let wallet = card.wallets.first {
            $0.curve == blockchain.curve
        }
        
        do {
            let walletManager = try walletManagerFactory.makeWalletManager(cardId: card.cardId, blockchain: blockchain, walletPublicKey: wallet!.publicKey)
            if let transactionSender = walletManager as? TransactionSender {
                self.transactionSender = transactionSender
            } else {
                print("Wallet manager cannot send transactions")
            }
        } catch {
            print(error)
        }
    }
    
    private func parseAmount() -> Amount? {
        guard let value = Decimal(string: amountToSend) else {
            return nil
        }
        
        return Amount(with: blockchain, value: value)
    }
}
