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
        case .chia:
            // Can not generate and doesn't depend on destination
            return ""
        case .xrp, 
             .stellar,
             .binance:
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
        // UTXO-like
        case .bitcoin:
            return "bc1qqekp00msl3fnran4as60h33zk6fmhsg9tptngs"
        case .litecoin:
            return "ltc1qn7zu6luzkzdej6lnurwzmejd3hq44gz68e42ue"
        case .bitcoinCash:
            return "bitcoincash:qqnn890smge9v5925du75qqg0h704lfgeg67g43kgx"
        case .dogecoin:
            return "D96Dokgv74S3t7wR7yxPanQb72fru6kGiu"
        case .dash:
            return "Xp7sgRiThFmtmfw496pyDhHimCXhrEuKy5"
        case .ravencoin:
            return "R9zMQh2AxUXNDfXtH3iLDEG7LWTZpVhLfQ"
        // EVM-like
        case .ethereum, .ethereumPoW, .ethereumClassic, .rsk, .polygon,
                .avalanche, .bsc, .fantom, .arbitrum, .gnosis, .optimism,
                .kava, .cronos, .telos, .octa, .shibarium, .disChain,
                .areon, .playa3ullGames, .pulsechain, .aurora, .manta,
                .zkSync, .moonbeam, .polygonZkEVM:
            return "0x55Bf9cD444c4F28F31d027Cdf8849aD27a30Ae78"
        case .decimal:
            return "d012klee4zycneg7vwsylxl3py66farptnc6jnlg0"
        // Polkadot-like
        case .polkadot:
            return "13GJBhfDps1ChmjEusovTYc2hRQGa2Ae4YDtVHZWrKYWRvVS"
        case .kusama:
            return "DfzUMCsTdZFFNyYic1MbTDBJE5btqGLkumUUWRY4FFcArPc"
        case .azero:
            return "5DiDnUGN7ze3JX9YhiikXoqrLYqqyRcYJwHLC8fqVcCwYHyP"
        // Others
        case .cardano:
            return "addr1vxkgxehrx5c049azfalr9mxhr5u3njvuqu6da95qtyuwj2s0fazfp"
        case .solana:
            return "A9QYzDX8xwp46CV5AxvSPtpC4wD1xRJL6K5n2CWfYa8e"
        case .cosmos:
            return "cosmos158wfklcdcs2vhjh3rekcnh5dj2yx74rky7d0zf"
        case .tron:
            return "TWx1TJNZdCvhPkLNKy1Zn9JN6rPqFDD9FB"
        case .near:
            return "957cc38c539423ccc2ec871b2514229be76df3076b34f262889a6598d5be8d49"
        case .xdc:
            return "xdce0BaA45196cf702D62c5bc21aACf165A63a5b987"
        case .veChain:
            return "0x9f63AF9203E296c91F4ECE80B1E899a951FF6813"
        case .aptos:
            return "0x8e5cc778f9e44ef1d67b487564bb86fbfe0a4ac734fbf29e091c27cdc5b7dea0"
        case .algorand:
            return "TP7ASBKT5ELXLAIX55PQOSQSK5RYLQGBBI2KFPE4FVQONFK5K22J2PBYX4"
        // We have to generate a new dummy address for
        case .terraV1, .terraV2, .ton:
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
