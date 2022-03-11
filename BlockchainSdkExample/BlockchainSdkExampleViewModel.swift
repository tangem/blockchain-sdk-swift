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
    @Published var destination: String = ""
    @Published var amountToSend: String = ""
    @Published var feeDescription: String = "--"
    @Published var transactionResult: String = "--"
    @Published var blockchains: [(String, String)] = []
    @Published var curves: [EllipticCurve] = []
    @Published var blockchainName: String = ""
    @Published var isTestnet: Bool = false
    @Published var isShelley: Bool = false
    @Published var curve: EllipticCurve = .ed25519
    @Published var sourceAddresses: [Address] = []
    @Published var balance: String = "--"
    
    let blockchainsWithCurveSelection: [String]
    let blockchainsWithShelleySelection: [String]

    private let sdk: TangemSdk
    private let walletManagerFactory = WalletManagerFactory(config: .init(blockchairApiKey: "", blockcypherTokens: [], infuraProjectId: ""))
    @Published private(set) var card: Card?
    @Published private(set) var walletManager: WalletManager?
    private var blockchain: Blockchain?
    private let destinationKey = "destination"
    private let amountKey = "amount"
    private let blockchainNameKey = "blockchainName"
    private let isTestnetKey = "isTestnet"
    private let isShelleyKey = "isShelley"
    private let curveKey = "curve"
    
    private var bag: Set<AnyCancellable> = []

    
    init() {
        var config = Config()
        config.attestationMode = .offline

        self.sdk = TangemSdk(config: config)

        self.blockchains = Self.blockchainList()
        self.curves = EllipticCurve.allCases.sorted { $0.rawValue < $1.rawValue }
        self.blockchainsWithCurveSelection = [
            Blockchain.xrp(curve: .ed25519),
            Blockchain.tezos(curve: .ed25519),
        ].map { $0.codingKey }
        self.blockchainsWithShelleySelection = [
            Blockchain.cardano(shelley: false),
        ].map { $0.codingKey }

        self.destination = UserDefaults.standard.string(forKey: destinationKey) ?? ""
        self.amountToSend = UserDefaults.standard.string(forKey: amountKey) ?? ""
        self.blockchainName = UserDefaults.standard.string(forKey: blockchainNameKey) ?? blockchains.first?.1 ?? ""
        self.isTestnet = UserDefaults.standard.bool(forKey: isTestnetKey)
        self.curve = EllipticCurve(rawValue: UserDefaults.standard.string(forKey: curveKey) ?? "") ?? self.curve
        self.isShelley = UserDefaults.standard.bool(forKey: isShelleyKey)
        
        $destination
            .sink {
                UserDefaults.standard.set($0, forKey: self.destinationKey)
            }
            .store(in: &bag)
        
        $amountToSend
            .sink {
                UserDefaults.standard.set($0, forKey: self.amountKey)
            }
            .store(in: &bag)
        
        $blockchainName
            .dropFirst()
            .sink { [unowned self] in
                UserDefaults.standard.set($0, forKey: self.blockchainNameKey)
                self.updateBlockchain(from: $0, isTestnet: isTestnet, curve: curve, isShelley: isShelley)
                self.updateWalletManager()
            }
            .store(in: &bag)
        
        $isTestnet
            .dropFirst()
            .sink { [unowned self] in
                UserDefaults.standard.set($0, forKey: isTestnetKey)
                self.updateBlockchain(from: blockchainName, isTestnet: $0, curve: curve, isShelley: isShelley)
                self.updateWalletManager()
            }
            .store(in: &bag)
        
        $curve
            .dropFirst()
            .sink { [unowned self] in
                UserDefaults.standard.set($0.rawValue, forKey: curveKey)
                self.updateBlockchain(from: blockchainName, isTestnet: isTestnet, curve: $0, isShelley: isShelley)
                self.updateWalletManager()
            }
            .store(in: &bag)
        
        $isShelley
            .dropFirst()
            .sink { [unowned self] in
                UserDefaults.standard.set($0, forKey: isShelleyKey)
                self.updateBlockchain(from: blockchainName, isTestnet: isTestnet, curve: curve, isShelley: $0)
                self.updateWalletManager()
            }
            .store(in: &bag)
    }
    
    func scanCardAndGetInfo() {
        sdk.scanCard { [unowned self] result in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let card):
                self.card = card
                self.updateBlockchain(from: blockchainName, isTestnet: isTestnet, curve: curve, isShelley: isShelley)
                self.updateWalletManager()
            }
        }
    }
    
    func updateBalance() {
        walletManager?.update { [weak self] result in
            let balanceDescription: String
            switch result {
            case .failure(let error):
                print(error)
                balanceDescription = error.localizedDescription
            case .success:
                if let balance = self?.walletManager?.wallet.amounts[.coin]?.description {
                    balanceDescription = balance
                } else {
                    balanceDescription = "--"
                }
            }
         
            DispatchQueue.main.async {
                self?.balance = balanceDescription
            }
        }   
    }
    
    func copySourceAddressToClipboard(_ sourceAddress: Address) {
        UIPasteboard.general.string = sourceAddress.value
    }
    
    func checkFee() {
        guard
            let amount = parseAmount(),
            let walletManager = walletManager
        else {
            feeDescription = "Invalid amount"
            return
        }
        
        feeDescription = "--"
        
        walletManager
            .getFee(amount: amount, destination: destination)
            .receive(on: RunLoop.main)
            .sink { [unowned self] in
                switch $0 {
                case .failure(let error):
                    print(error)
                    self.feeDescription = error.localizedDescription
                case .finished:
                    break
                }
            } receiveValue: { [unowned self] in
                self.feeDescription = $0.map { $0.description }.joined(separator: "; ")
            }
            .store(in: &bag)
    }
    
    func sendTransaction() {
        guard
            let amount = parseAmount(),
            let walletManager = walletManager
        else {
            transactionResult = "Invalid amount"
            return
        }
        
        transactionResult = "--"
                
        walletManager
            .getFee(amount: amount, destination: destination)
            .flatMap { fees -> AnyPublisher<Void, Error> in
                guard let fee = fees.first else {
                    return .anyFail(error: WalletError.failedToGetFee)
                }
                
                do {
                    let transaction = try walletManager.createTransaction(
                        amount: amount,
                        fee: fee,
                        destinationAddress: self.destination
                    )
                    return walletManager.send(transaction, signer: self.sdk).eraseToAnyPublisher()
                } catch {
                    return .anyFail(error: error)
                }
            }
            .receive(on: RunLoop.main)
            .sink { [unowned self] in
                switch $0 {
                case .failure(let error):
                    print(error)
                    self.transactionResult = error.localizedDescription
                case .finished:
                    self.transactionResult = "OK"
                }
            } receiveValue: {
                
            }
            .store(in: &bag)
    }
    
    private func updateBlockchain(
        from blockchainName: String,
        isTestnet: Bool,
        curve: EllipticCurve,
        isShelley: Bool
    ) {
        struct BlockchainInfo: Codable {
            let key: String
            let curve: String
            let testnet: Bool
            let shelley: Bool
        }
        
        do {
            let blockchainInfo = BlockchainInfo(key: blockchainName, curve: curve.rawValue, testnet: isTestnet, shelley: isShelley)
            let encodedInfo = try JSONEncoder().encode(blockchainInfo)
            self.blockchain = try JSONDecoder().decode(Blockchain.self, from: encodedInfo)
        } catch {
            print(error)
        }
    }
    
    private func updateWalletManager() {
        self.walletManager = nil
        self.sourceAddresses = []
        self.feeDescription = "--"
        self.transactionResult = "--"
        
        guard
            let card = card,
            let blockchain = blockchain,
            let wallet = card.wallets.first(where: { $0.curve == blockchain.curve })
        else {
            return
        }

        do {
            let walletManager = try walletManagerFactory.makeWalletManager(cardId: card.cardId, blockchain: blockchain, walletPublicKey: wallet.publicKey)
            self.walletManager = walletManager
            self.sourceAddresses = walletManager.wallet.addresses
            updateBalance()
        } catch {
            print(error)
        }
    }
    
    private func parseAmount() -> Amount? {
        let numberFormatter = NumberFormatter()
        guard
            let value = numberFormatter.number(from: amountToSend)?.decimalValue,
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
