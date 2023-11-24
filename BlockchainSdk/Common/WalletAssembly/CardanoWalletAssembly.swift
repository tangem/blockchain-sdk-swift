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
            $0.transactionBuilder = CardanoTransactionBuilder()
            let cardanoResponseMapper = CardanoResponseMapper()
            
            let service = CardanoNetworkService(providers: [
                RosettaNetworkProvider(
                    rosettaUrl: .getBlockRosetta(
                        apiKey: input.blockchainSdkConfig.getBlockAccessTokens.credential(for: input.blockchain, at: .rosseta)
                    ),
                    configuration: input.networkConfig,
                    cardanoResponseMapper: cardanoResponseMapper
                ).eraseToAnyCardanoNetworkProvider(),
                AdaliteNetworkProvider(
                    adaliteUrl: .main,
                    configuration: input.networkConfig,
                    cardanoResponseMapper: cardanoResponseMapper
                ).eraseToAnyCardanoNetworkProvider(),
                RosettaNetworkProvider(
                    rosettaUrl: .tangemRosetta,
                    configuration: input.networkConfig,
                    cardanoResponseMapper: cardanoResponseMapper
                ).eraseToAnyCardanoNetworkProvider(),
            ])
            $0.networkService = service
        }
    }    
}
