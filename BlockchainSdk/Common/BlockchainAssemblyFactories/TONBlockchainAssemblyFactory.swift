//
//  TONBlockchainFactory.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 31.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

struct TONBlockchainAssemblyFactory: BlockchainAssemblyFactoryProtocol {
    
    func canAssembly(blockchain: Blockchain, isTestnet: Bool = false) -> Bool {
        return blockchain == .ton(testnet: isTestnet)
    }
    
    func assembly(with input: BlockchainAssemblyFactoryInput, isTestnet: Bool = false) throws -> AssemblyWallet {
        try TONWalletManager(
            wallet: input.wallet,
            service: .init(
                providers: [
                    TONProvider(
                        host: TONNetworkUrl(isTestnet).host,
                        network: .init(configuration: input.networkConfig)
                    )
                ],
                blockchain: input.blockchain
            )
        )
    }
    
}
