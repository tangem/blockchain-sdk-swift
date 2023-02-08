//
//  CardanoWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import stellarsdk
import BitcoinCore

struct CardanoWalletAssembly: BlockchainAssemblyProtocol {
    
    // TODO: - Проверить shelly
    func assembly(with input: BlockchainAssemblyInput) throws -> AssemblyWallet {
        return CardanoWalletManager(wallet: input.wallet).then {
            $0.txBuilder = CardanoTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey, shelleyCard: false)
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
