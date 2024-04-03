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
            let networkConfig = input.networkConfig

            var providers = [AnyCardanoNetworkProvider]()
            let linkResolver = APILinkResolver(blockchain: input.blockchain, config: input.blockchainSdkConfig)
            providers = input.apiInfo.compactMap {
                guard 
                    let link = linkResolver.resolve(for: $0),
                    let url = URL(string: link),
                    let api = $0.api
                else {
                    return nil
                }

                switch api {
                case .getblock, .tangemRosetta:
                    return RosettaNetworkProvider(
                        url: url,
                        configuration: networkConfig,
                        cardanoResponseMapper: cardanoResponseMapper
                    )
                    .eraseToAnyCardanoNetworkProvider()
                case .adalite:
                    return AdaliteNetworkProvider(
                        url: url,
                        configuration: networkConfig, 
                        cardanoResponseMapper: cardanoResponseMapper
                    ).eraseToAnyCardanoNetworkProvider()
                default:
                    return nil
                }
            }

            $0.networkService = CardanoNetworkService(providers: providers)
        }
    }    
}
