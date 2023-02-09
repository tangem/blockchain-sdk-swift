//
//  CardanoWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct CardanoWalletAssembly: WalletAssemblyProtocol {
    
    static func make(with input: BlockchainAssemblyInput) throws -> AssemblyWallet {
        return CardanoWalletManager(wallet: input.wallet).then {
            $0.txBuilder = CardanoTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey, shelleyCard: input.blockchain.shelly)
            let service = CardanoNetworkService(providers: [
                AdaliteNetworkProvider(
                    baseUrl: .main,
                    configuration: input.networkConfig
                ).eraseToAnyCardanoNetworkProvider(),
                RosettaNetworkProvider(
                    baseUrl: .tangemRosetta,
                    configuration: input.networkConfig
                ).eraseToAnyCardanoNetworkProvider()
            ])
            $0.networkService = service
        }
    }
    
}
