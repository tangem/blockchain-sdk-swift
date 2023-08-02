//
//  CardanoWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct CardanoWalletAssembly: WalletManagerAssembly {
    
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return CardanoWalletManager(wallet: input.wallet).then {
            $0.txBuilder = CardanoTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey)
            let service = CardanoNetworkService(providers: [
                RosettaNetworkProvider(
                    baseUrl: .getBlockRosetta(apiKey: input.blockchainSdkConfig.getBlockApiKey),
                    configuration: input.networkConfig
                ).eraseToAnyCardanoNetworkProvider(),
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
