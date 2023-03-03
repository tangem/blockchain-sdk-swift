//
//  XRPWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct XRPWalletAssembly: WalletAssemblyProtocol {
    
    static func make(with input: BlockchainAssemblyInput) throws -> WalletAssembly {
        return try XRPWalletManager(wallet: input.wallet).then {
            $0.txBuilder = try XRPTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey, curve: input.blockchain.curve)
            $0.networkService = XRPNetworkService(providers: [
                XRPNetworkProvider(baseUrl: .xrpLedgerFoundation, configuration: input.networkConfig),
                XRPNetworkProvider(baseUrl: .ripple, configuration: input.networkConfig),
                XRPNetworkProvider(baseUrl: .rippleReserve, configuration: input.networkConfig)
            ])
        }
    }
    
}
