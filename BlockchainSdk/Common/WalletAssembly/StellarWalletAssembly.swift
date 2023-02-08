//
//  StellarWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import stellarsdk
import BitcoinCore

struct StellarWalletAssembly: BlockchainAssemblyProtocol {
    
    func assembly(with input: BlockchainAssemblyInput) throws -> AssemblyWallet {
        return StellarWalletManager(wallet: input.wallet).then {
            let url = input.blockchain.isTestnet ? "https://horizon-testnet.stellar.org" : "https://horizon.stellar.org"
            let stellarSdk = StellarSDK(withHorizonUrl: url)
            $0.stellarSdk = stellarSdk
            $0.txBuilder = StellarTransactionBuilder(stellarSdk: stellarSdk, walletPublicKey: input.wallet.publicKey.blockchainKey, isTestnet: input.blockchain.isTestnet)
            $0.networkService = StellarNetworkService(isTestnet: input.blockchain.isTestnet, stellarSdk: stellarSdk)
        }
    }
    
}
