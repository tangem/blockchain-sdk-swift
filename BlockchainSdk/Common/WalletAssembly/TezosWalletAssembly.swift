//
//  TezosWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import stellarsdk
import BitcoinCore

struct TezosWalletAssembly: BlockchainAssemblyProtocol {
    
    static func canAssembly(blockchain: Blockchain) -> Bool {
        blockchain == .tezos(curve: blockchain.curve)
    }
    
    static func assembly(with input: BlockchainAssemblyInput) throws -> AssemblyWallet {
        return try TezosWalletManager(wallet: input.wallet).then {
            $0.txBuilder = try TezosTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey, curve: input.blockchain.curve)
            $0.networkService = TezosNetworkService(
                providers: TezosApi.makeAllProviders(configuration: input.networkConfig)
            )
        }
    }
    
}
