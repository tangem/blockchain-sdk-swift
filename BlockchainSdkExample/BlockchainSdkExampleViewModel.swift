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
    @Published var feeDescriptions: [String] = []
    @Published var transactionResult: String = "--"
    @Published var blockchains: [(String, String)] = []
    @Published var curves: [EllipticCurve] = []
    @Published var blockchainName: String = ""
    @Published var isTestnet: Bool = false
    @Published var isShelley: Bool = false
    @Published var curve: EllipticCurve = .ed25519
    @Published var tokenExpanded: Bool = false
    @Published var tokenEnabled = false
    @Published var tokenSymbol = ""
    @Published var tokenContractAddress = ""
    @Published var tokenDecimalPlaces = 0
    @Published var sourceAddresses: [Address] = []
    @Published var balance: String = "--"
    
    @Published var dummyExpanded: Bool = false
    @Published var dummyPublicKey: String = ""
    @Published var dummyAddress: String = ""
    
    var tokenSectionName: String {
        if let enteredToken = self.enteredToken {
            return "Token (\(enteredToken.symbol))"
        } else {
            return "Token"
        }
    }
    
    var enteredToken: BlockchainSdk.Token? {
        guard tokenEnabled else {
            return nil
        }
        
        guard !tokenContractAddress.isEmpty else {
            return nil
        }
        
        return BlockchainSdk.Token(name: tokenSymbol, symbol: tokenSymbol, contractAddress: tokenContractAddress, decimalCount: tokenDecimalPlaces)
    }
    
    let blockchainsWithCurveSelection: [String]
    let blockchainsWithShelleySelection: [String]

    private let sdk: TangemSdk
    private let walletManagerFactory = WalletManagerFactory(config: .init(blockchairApiKeys: [],
                                                                          blockcypherTokens: [],
                                                                          infuraProjectId: "",
                                                                          useBlockBookUtxoApis: true,
                                                                          nowNodesApiKey: "",
                                                                          getBlockApiKey: "",
                                                                          tronGridApiKey: "",
                                                                          tonCenterApiKeys: .init(mainnetApiKey: "", testnetApiKey: ""),
                                                                          quickNodeSolanaCredentials: .init(apiKey: "", subdomain: ""),
                                                                          quickNodeBscCredentials: .init(apiKey: "", subdomain: ""),
                                                                          blockscoutCredentials: .init(login: "", password: ""),
                                                                          defaultNetworkProviderConfiguration: .init(logger: .verbose)))
    @Published private(set) var card: Card?
    @Published private(set) var walletManager: WalletManager?
    private var blockchain: Blockchain?
    private let destinationKey = "destination"
    private let amountKey = "amount"
    private let blockchainNameKey = "blockchainName"
    private let isTestnetKey = "isTestnet"
    private let isShelleyKey = "isShelley"
    private let curveKey = "curve"
    private let tokenEnabledKey = "tokenEnabled"
    private let tokenSymbolKey = "tokenSymbol"
    private let tokenContractAddressKey = "tokenContractAddress"
    private let tokenDecimalPlacesKey = "tokenDecimalPlaces"
    
    private var bag: Set<AnyCancellable> = []

    
    init() {
        var config = Config()
        config.logConfig = .verbose
        // initialize at start to handle all logs
        Log.config = config.logConfig
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
        self.tokenEnabled = UserDefaults.standard.bool(forKey: tokenEnabledKey)
        self.tokenSymbol = UserDefaults.standard.string(forKey: tokenSymbolKey) ?? ""
        self.tokenContractAddress = UserDefaults.standard.string(forKey: tokenContractAddressKey) ?? ""
        self.tokenDecimalPlaces = UserDefaults.standard.integer(forKey: tokenDecimalPlacesKey)
        
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
        
        $tokenEnabled
            .dropFirst()
            .debounce(for: 1, scheduler: RunLoop.main)
            .sink { [unowned self] in
                UserDefaults.standard.set($0, forKey: tokenEnabledKey)
                self.updateWalletManager()
            }
            .store(in: &bag)
        
        $tokenSymbol
            .dropFirst()
            .debounce(for: 1, scheduler: RunLoop.main)
            .sink { [unowned self] in
                UserDefaults.standard.set($0, forKey: tokenSymbolKey)
                self.updateWalletManager()
            }
            .store(in: &bag)
        
        $tokenContractAddress
            .dropFirst()
            .debounce(for: 1, scheduler: RunLoop.main)
            .sink { [unowned self] in
                UserDefaults.standard.set($0, forKey: tokenContractAddressKey)
                self.updateWalletManager()
            }
            .store(in: &bag)
        
        $tokenDecimalPlaces
            .dropFirst()
            .debounce(for: 1, scheduler: RunLoop.main)
            .sink { [unowned self] in
                UserDefaults.standard.set($0, forKey: tokenDecimalPlacesKey)
                self.updateWalletManager()
            }
            .store(in: &bag)

        if ProcessInfo.processInfo.environment["SCAN_ON_START"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.scanCardAndGetInfo()
            }
        }
    }
    
    func scanCardAndGetInfo() {
        sdk.scanCard { [unowned self] result in
            switch result {
            case .failure(let error):
                Log.error(error)
            case .success(let card):
                self.card = card
                self.updateBlockchain(from: blockchainName, isTestnet: isTestnet, curve: curve, isShelley: isShelley)
                self.updateWalletManager()
            }
        }
    }
    
    func updateDummyAction() {
        updateWalletManager()
    }
    
    func clearDummyAction() {
        dummyPublicKey = ""
        dummyAddress = ""
        updateWalletManager()
    }
    
    func updateBalance() {
        balance = "--"
        
        walletManager?.update { [weak self] result in
            let balanceDescription: String
            switch result {
            case .failure(let error):
                Log.error(error)
                balanceDescription = error.localizedDescription
            case .success:
                var balances: [String] = []
                if let balance = self?.walletManager?.wallet.amounts[.coin]?.description {
                    balances = [balance]
                } else {
                    balances = ["--"]
                }
            
                let tokens = self?.walletManager?.cardTokens ?? []
                for token in tokens {
                    if let tokenAmount = self?.walletManager?.wallet.amounts[.token(value: token)] {
                        balances.append(tokenAmount.description)
                    } else {
                        balances.append("--- \(token.symbol)")
                    }
                }
                
                balanceDescription = balances.joined(separator: "\n")
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
        feeDescriptions = []
        
        guard
            let amount = parseAmount(),
            let walletManager = walletManager
        else {
            feeDescriptions = ["Invalid amount"]
            return
        }
        
        walletManager
            .getFee(amount: amount, destination: destination)
            .receive(on: RunLoop.main)
            .sink { [unowned self] in
                switch $0 {
                case .failure(let error):
                    Log.error(error)
                    self.feeDescriptions = [error.localizedDescription]
                case .finished:
                    break
                }
            } receiveValue: { [unowned self] in
                self.feeDescriptions = $0.map { $0.amount.description }
            }
            .store(in: &bag)
    }
    
    func sendTransaction() {
        transactionResult = "--"

        guard
            let amount = parseAmount(),
            let walletManager = walletManager
        else {
            transactionResult = "Invalid amount"
            return
        }
        
        walletManager
            .getFee(amount: amount, destination: destination)
            .flatMap { [unowned self] fees -> AnyPublisher<TransactionSendResult, Error> in
                guard let fee = fees.first else {
                    return .anyFail(error: WalletError.failedToGetFee)
                }
                
                do {
                    let transaction = try walletManager.createTransaction(
                        amount: amount,
                        fee: fee,
                        destinationAddress: self.destination
                    )
                    let signer = CommonSigner(sdk: self.sdk)
                    return walletManager.send(transaction, signer: signer).eraseToAnyPublisher()
                } catch {
                    return .anyFail(error: error)
                }
            }
            .receive(on: RunLoop.main)
            .sink { [unowned self] in
                switch $0 {
                case .failure(let error):
                    Log.error(error)
                    self.transactionResult = error.localizedDescription
                case .finished:
                    self.transactionResult = "OK"
                }
            } receiveValue: { _ in
                
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
            let newBlockchain = try JSONDecoder().decode(Blockchain.self, from: encodedInfo)
            
            if let blockchain = blockchain, newBlockchain != blockchain {
                self.destination = ""
                self.amountToSend = ""
            }
            
            self.blockchain = newBlockchain
        } catch {
            Log.error(error)
        }
    }
    
    private func updateWalletManager() {
        self.walletManager = nil
        self.sourceAddresses = []
        self.feeDescriptions = []
        self.transactionResult = "--"
        self.balance = "--"
        
        guard
            let card = card,
            let blockchain = blockchain,
            let wallet = card.wallets.first(where: { $0.curve == blockchain.curve })
        else {
            return
        }

        do {
            let walletManager = try createWalletManager(blockchain: blockchain, wallet: wallet)
            self.walletManager = walletManager
            self.sourceAddresses = walletManager.wallet.addresses
            if let enteredToken = enteredToken {
                walletManager.addToken(enteredToken)
            }
            updateBalance()
        } catch {
            Log.error(error)
        }
    }
    
    private func createWalletManager(blockchain: Blockchain, wallet: Card.Wallet) throws -> WalletManager {
        return try walletManagerFactory.makeStubWalletManager(
            blockchain: blockchain,
            walletPublicKey: dummyPublicKey.isEmpty ? wallet.publicKey : Data(hex: dummyPublicKey),
            addresses: dummyAddress.isEmpty ? [] : [dummyAddress]
        )
    }
    
    private func parseAmount() -> Amount? {
        let numberFormatter = NumberFormatter()
        guard
            let value = numberFormatter.number(from: amountToSend)?.decimalValue,
            let blockchain = blockchain
        else {
            return nil
        }
        
        if let enteredToken = enteredToken {
            return Amount(with: enteredToken, value: value)
        } else {
            return Amount(with: blockchain, value: value)
        }
    }
    
    static private func blockchainList() -> [(String, String)] {
        let blockchains: [Blockchain] = [
            .bitcoin(testnet: false),
            .litecoin,
            .stellar(testnet: false),
            .ethereum(testnet: false),
            .ethereumClassic(testnet: false),
            .ethereumPoW(testnet: false),
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
            .tron(testnet: false),
            .ton(testnet: false),
            .arbitrum(testnet: false),
            .dash(testnet: false),
            .gnosis,
            .saltPay,
            .optimism(testnet: false),
            .kava(testnet: false),
        ]
        
        return blockchains.map { ($0.displayName, $0.codingKey) }
    }
}
