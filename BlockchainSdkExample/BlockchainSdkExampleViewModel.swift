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
    @Published var blockchains: [(String, String)] = []
    @Published var curves: [EllipticCurve] = []
    @Published var blockchainName: String = ""
    @Published var isTestnet: Bool = false
    @Published var curve: EllipticCurve = .ed25519

    private let sdk: TangemSdk
    private let walletManagerFactory = WalletManagerFactory(config: .init(blockchairApiKey: "", blockcypherTokens: [], infuraProjectId: ""))
    private var card: Card?
    private var blockchain: Blockchain?
    private let blockchainNameKey = "blockchainName"
    private let isTestnetKey = "isTestnet"
    private let curveKey = "curve"
    @Published private(set) var transactionSender: TransactionSender?
    
    private var bag: Set<AnyCancellable> = []

    
    init() {
        var config = Config()
        config.attestationMode = .offline

        self.sdk = TangemSdk(config: config)

        self.blockchains = Self.blockchainList()
        self.curves = EllipticCurve.allCases.sorted { $0.rawValue < $1.rawValue }

        self.blockchainName = UserDefaults.standard.string(forKey: blockchainNameKey) ?? ""
        self.isTestnet = UserDefaults.standard.bool(forKey: isTestnetKey)
        self.curve = EllipticCurve(rawValue: UserDefaults.standard.string(forKey: curveKey) ?? "") ?? self.curve
        
        $blockchainName
            .sink { [unowned self] in
                UserDefaults.standard.set($0, forKey: self.blockchainNameKey)
                self.updateBlockchain(from: $0, isTestnet: isTestnet, curve: curve)
                self.updateWalletManager()
            }
            .store(in: &bag)
        
        $isTestnet
            .sink { [unowned self] in
                UserDefaults.standard.set($0, forKey: isTestnetKey)
                self.updateBlockchain(from: blockchainName, isTestnet: $0, curve: curve)
                self.updateWalletManager()
            }
            .store(in: &bag)
        
        $curve
            .sink { [unowned self] in
                UserDefaults.standard.set($0.rawValue, forKey: curveKey)
                self.updateBlockchain(from: blockchainName, isTestnet: isTestnet, curve: $0)
                self.updateWalletManager()
            }
            .store(in: &bag)
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
        guard
            let amount = parseAmount(),
            let blockchain = blockchain
        else {
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
    
    private func updateBlockchain(from blockchainName: String, isTestnet: Bool, curve: EllipticCurve) {
        struct BlockchainInfo: Codable {
            let key: String
            let curve: String
            let testnet: Bool
        }
        
        do {
            let blockchainInfo = BlockchainInfo(key: blockchainName, curve: curve.rawValue, testnet: isTestnet)
            let encodedInfo = try JSONEncoder().encode(blockchainInfo)
            self.blockchain = try JSONDecoder().decode(Blockchain.self, from: encodedInfo)
        } catch {
            print(error)
        }
    }
    
    private func updateWalletManager() {
        guard
            let card = card,
            let blockchain = blockchain,
            let wallet = card.wallets.first(where: { $0.curve == blockchain.curve })
        else {
            self.transactionSender = nil
            return
        }

        do {
            let walletManager = try walletManagerFactory.makeWalletManager(cardId: card.cardId, blockchain: blockchain, walletPublicKey: wallet.publicKey)
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
        guard
            let value = Decimal(string: amountToSend),
            let blockchain = blockchain
        else {
            return nil
        }
        
        return Amount(with: blockchain, value: value)
    }
    
    static private func blockchainList() -> [(String, String)] {
        let blockchains: [Blockchain] = [
            .bitcoin(testnet: false),
            .litecoin,
            .stellar(testnet: false),
            .ethereum(testnet: false),
            .rsk,
            .bitcoinCash(testnet: false),
            .binance(testnet: false),
            .cardano(shelley: false),
            .xrp(curve: .ed25519),
            .ducatus,
            .tezos(curve: .ed25519),
            .dogecoin,
            .bsc(testnet: false),
            .polygon(testnet: false),
            .avalanche(testnet: false),
            .solana(testnet: false),
            .fantom(testnet: false),
            .polkadot(testnet: false),
            .kusama,
        ]
        
        return blockchains.map { ($0.displayName, $0.codingKey) }
    }
}
