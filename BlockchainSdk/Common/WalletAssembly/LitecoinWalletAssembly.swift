//
//  LitecoinWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

struct LitecoinWalletAssembly: BlockchainAssemblyProtocol {
    
    static func canAssembly(blockchain: Blockchain) -> Bool {
        return blockchain == .litecoin
    }
    
    static func assembly(with input: BlockchainAssemblyInput) throws -> AssemblyWallet {
        return try LitecoinWalletManager(wallet: input.wallet).then {
            let bitcoinManager = BitcoinManager(networkParams: LitecoinNetworkParams(),
                                                walletPublicKey: input.wallet.publicKey.blockchainKey,
                                                compressedWalletPublicKey: try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress(),
                                                bip: .bip84)
            
            $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: input.wallet.addresses)
            
            var providers = [AnyBitcoinNetworkProvider]()
            
            providers.append(makeBlockBookUtxoProvider(with: input, for: .NowNodes).eraseToAnyBitcoinNetworkProvider())
            providers.append(makeBlockBookUtxoProvider(with: input, for: .GetBlock).eraseToAnyBitcoinNetworkProvider())
            
            providers.append(
                contentsOf: makeBlockchairNetworkProviders(endpoint: .litecoin, with: input)
            )
            
            providers.append(
                makeBlockcypherNetworkProvider(endpoint: .litecoin, with: input).eraseToAnyBitcoinNetworkProvider()
            )
            
            $0.networkService = LitecoinNetworkService(providers: providers)
        }
    }
    
}
