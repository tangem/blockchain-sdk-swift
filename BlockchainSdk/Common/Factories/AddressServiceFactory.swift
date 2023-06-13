//
//  AddressServiceFactory.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 13.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore
import WalletCore

public struct AddressServiceFactory {
    private let blockchain: Blockchain

    public init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }

    public func makeAddressService() -> AddressService {
        let isTestnet = blockchain.isTestnet

        switch blockchain {
        case .bitcoin:
            let network: BitcoinNetwork = isTestnet ? .testnet : .mainnet
            let networkParams = network.networkParams
            return BitcoinAddressService(networkParams: networkParams)
        case .litecoin:
            return BitcoinAddressService(networkParams: LitecoinNetworkParams())
        case .stellar:
            return StellarAddressService()
        case .ethereum, .ethereumClassic, .ethereumPoW, .ethereumFair,
                .bsc, .polygon, .avalanche, .fantom, .arbitrum, .gnosis, .optimism, .saltPay, .kava, .cronos:
            return EthereumAddressService()
        case .rsk:
            return RskAddressService()
        case .bitcoinCash:
            let networkParams: INetwork = isTestnet ? BitcoinCashTestNetworkParams() : BitcoinCashNetworkParams()
            return BitcoinCashAddressService(networkParams: networkParams)
        case .binance:
            return BinanceAddressService(testnet: isTestnet)
        case .ducatus:
            return BitcoinLegacyAddressService(networkParams: DucatusNetworkParams())
        case .cardano(let shelley):
            return CardanoAddressService(shelley: shelley)
        case .xrp(let curve):
            return XRPAddressService(curve: curve)
        case .tezos(let curve):
            return TezosAddressService(curve: curve)
        case .dogecoin:
            return BitcoinLegacyAddressService(networkParams: DogecoinNetworkParams())
        case .solana:
            return SolanaAddressService()
        case .polkadot:
            return PolkadotAddressService(network: isTestnet ? .westend : .polkadot)
        case .kusama:
            return PolkadotAddressService(network: .kusama)
        case .tron:
            return TronAddressService()
        case .dash:
            return BitcoinLegacyAddressService(
                networkParams: isTestnet ?  DashTestNetworkParams() : DashMainNetworkParams()
            )
        case .kaspa:
            return KaspaAddressService()
        case .ravencoin:
            let networkParams: INetwork = isTestnet ? RavencoinTestNetworkParams() : RavencoinMainNetworkParams()
            return BitcoinLegacyAddressService(networkParams: networkParams)
        case .ton, .cosmos, .terraV1, .terraV2:
            return WalletCoreAddressService(blockchain: blockchain)
        }
    }
}
