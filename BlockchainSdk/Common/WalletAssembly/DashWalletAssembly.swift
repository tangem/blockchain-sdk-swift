//
//  DashWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

struct DashWalletAssembly: BlockchainAssemblyProtocol {
    
    static func canAssembly(blockchain: Blockchain) -> Bool {
        blockchain == .dash(testnet: blockchain.isTestnet)
    }
    
    static func assembly(with input: BlockchainAssemblyInput) throws -> AssemblyWallet {
        try DashWalletManager(wallet: input.wallet).then {
            let compressed = try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress()
            
            let bitcoinManager = BitcoinManager(
                networkParams: input.blockchain.isTestnet ? DashTestNetworkParams() : DashMainNetworkParams(),
                walletPublicKey: input.wallet.publicKey.blockchainKey,
                compressedWalletPublicKey: compressed,
                bip: .bip44
            )
            
            // TODO: Add CryptoAPIs for testnet
            
            $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: input.wallet.addresses)
            
            var providers: [AnyBitcoinNetworkProvider] = []
            
            providers.append(makeBlockBookUtxoProvider(with: input, for: .NowNodes).eraseToAnyBitcoinNetworkProvider())
            providers.append(makeBlockBookUtxoProvider(with: input, for: .GetBlock).eraseToAnyBitcoinNetworkProvider())
            providers.append(contentsOf: makeBlockchairNetworkProviders(endpoint: .dash, with: input))
            providers.append(makeBlockcypherNetworkProvider(endpoint: .dash, with: input).eraseToAnyBitcoinNetworkProvider())
            
            $0.networkService = BitcoinNetworkService(providers: providers)
        }
    }
    
}
