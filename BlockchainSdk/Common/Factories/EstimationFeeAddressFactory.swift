//
//  EstimationFeeAddressFactory.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 19.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct EstimationFeeAddressFactory {
    func makeAddress(for blockchain: Blockchain) throws -> String {
        switch blockchain {
        case .cardano:
            return "addr1q9svm389hgtksjvawpt9nfd9twk4kfckhs23wxrdfspynw9g3emv6k6njzwqvdmtff4426vy2pfg0ngu9t6pr9xmd0ass48agt"
        case .chia:
            // Can not generate and doesn't depend on destination
            return ""
        case .xrp, 
             .stellar,
             .binance,
             .solana,
             .veChain:
            // Doesn't depend on amount and destination
            return ""
        case .tezos:
            // Tezos has a fixed fee. See: `TezosFee.transaction`
            return ""
        case .kaspa,
             .hedera:
            // Doesn't depend on destination
            return ""
        case .ducatus:
            // Unsupported
            return ""

        // We have to generate a new dummy address for
        case
                // UTXO-like
                .bitcoin,
                .litecoin,
                .bitcoinCash,
                .dogecoin,
                .dash,
                .ravencoin,
                // EVM-like
                .ethereum,
                .ethereumPoW,
                .ethereumFair,
                .ethereumClassic,
                .rsk,
                .bsc,
                .polygon,
                .avalanche,
                .fantom,
                .arbitrum,
                .gnosis,
                .optimism,
                .kava,
                .cronos,
                .telos,
                .octa,
                .decimal,
                .xdc,
                .shibarium,
                // Polkadot-like
                .polkadot, .kusama, .azero,
                // Cosmos-like
                .cosmos, .terraV1, .terraV2,
                // Others
                .tron,
                .ton,
                .near,
                .algorand,
                .aptos:
            // For old blockchain with the ed25519 curve except `Cardano`
            // We have to use the new `ed25519_slip0010` curve that the `AnyMasterKeyFactory` works correctly
            let curve = blockchain.curve == .ed25519 ? .ed25519_slip0010 : blockchain.curve

            let mnemonic = try Mnemonic()
            let factory = AnyMasterKeyFactory(mnemonic: mnemonic, passphrase: "")
            let masterKey = try factory.makeMasterKey(for: curve)
            let extendedPublicKey = try masterKey.makePublicKey(for: curve)
            let service = AddressServiceFactory(blockchain: blockchain).makeAddressService()
            let publicKey = Wallet.PublicKey(seedKey: extendedPublicKey.publicKey, derivationType: .none)
            let estimationFeeAddress = try service.makeAddress(for: publicKey, with: .default).value
            return estimationFeeAddress
        }
    }
}
