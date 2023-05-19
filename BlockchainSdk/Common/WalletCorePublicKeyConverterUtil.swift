//
//  WalletCorePublicKeyConverterUtil.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 19.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSdk

enum WalletCorePublicKeyConverterUtil {
    static func convert(publicKey: Data, blockchain: Blockchain) -> Data {
        switch blockchain {
        case .bitcoin, .litecoin, .stellar, .ethereum, .ethereumPoW, .ethereumFair, .ethereumClassic, .rsk, .bitcoinCash, .binance, .cardano, .xrp, .ducatus, .tezos, .dogecoin, .bsc, .polygon, .avalanche, .solana, .fantom, .polkadot, .kusama, .tron, .arbitrum, .dash, .gnosis, .optimism, .saltPay, .ton, .kava, .kaspa, .ravencoin:
            return publicKey
        case .cosmos, .terraV1, .terraV2, .cronos:
            return compressedSecp256k1Key(publicKey)
        }
    }
    
    private static func compressedSecp256k1Key(_ publicKey: Data) -> Data {
        guard let compressedPublicKey = try? Secp256k1Key(with: publicKey).compress() else {
            return publicKey
        }
            
        return compressedPublicKey
    }
}
