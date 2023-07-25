//
//  EtheremJsonRpsProvider.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 25.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct EtheremJsonRpsProvider {
    // MARK: - Private Properties
    
    private let infuraProjectId: String
    private let nowNodesApiKey: String
    private let getBlockApiKey: String
    private let quickNodeBscCredentials: BlockchainSdkConfig.QuickNodeCredentials
    
    // MARK: - Init
    init(apiKeys: EthereumApiKeys) {
        self.infuraProjectId = apiKeys.infuraProjectId
        self.nowNodesApiKey = apiKeys.nowNodesApiKey
        self.getBlockApiKey = apiKeys.getBlockApiKey
        self.quickNodeBscCredentials = apiKeys.quickNodeBscCredentials
    }
    
    // MARK: - Implementation
    
    public func getJsonRpc(for blockchain: Blockchain) -> [URL]? {
        switch blockchain {
        case .ethereum:
            if blockchain.isTestnet {
                return [
                    URL(string: "https://eth-goerli.nownodes.io/\(nowNodesApiKey)")!,
                    URL(string: "https://goerli.infura.io/v3/\(infuraProjectId)")!,
                ]
            } else {
                return [
                    URL(string: "https://mainnet.infura.io/v3/\(infuraProjectId)")!,
                    URL(string: "https://eth.nownodes.io/\(nowNodesApiKey)")!,
                    URL(string: "https://eth.getblock.io/mainnet?api_key=\(getBlockApiKey)")!,
                ]
            }
        case .ethereumClassic:
            if blockchain.isTestnet {
                return [
                    URL(string: "https://www.ethercluster.com/kotti")!,
                ]
            } else {
                return [
                    URL(string: "https://etc.getblock.io/mainnet?api_key=\(getBlockApiKey)")!,
                    URL(string: "https://www.ethercluster.com/etc")!,
                    URL(string: "https://etc.etcdesktop.com")!,
                    URL(string: "https://blockscout.com/etc/mainnet/api/eth-rpc")!,
                    URL(string: "https://etc.mytokenpocket.vip")!,
                    URL(string: "https://besu-de.etc-network.info")!,
                    URL(string: "https://geth-at.etc-network.info")!,
                ]
            }
        case .ethereumPoW:
            if blockchain.isTestnet {
                return [
                    URL(string: "https://iceberg.ethereumpow.org")!,
                ]
            } else {
                return [
                    URL(string: "https://ethw.nownodes.io/\(nowNodesApiKey)")!,
                    URL(string: "https://mainnet.ethereumpow.org")!,
                ]
            }
        case .ethereumFair:
            return [
                URL(string: "https://rpc.etherfair.org")!,
            ]
        case .rsk:
            return [
                URL(string: "https://public-node.rsk.co/")!,
                URL(string: "https://rsk.nownodes.io/\(nowNodesApiKey)")!,
                URL(string: "https://rsk.getblock.io/mainnet?api_key=\(getBlockApiKey)")!,
            ]
        case .bsc:
            if blockchain.isTestnet {
                return [
                    URL(string: "https://data-seed-prebsc-1-s1.binance.org:8545/")!,
                ]
            } else {
                // https://docs.fantom.foundation/api/public-api-endpoints
                return [
                    URL(string: "https://bsc-dataseed.binance.org/")!,
                    URL(string: "https://bsc.nownodes.io/\(nowNodesApiKey)")!,
                    URL(string: "https://bsc.getblock.io/mainnet?api_key=\(getBlockApiKey)")!,
                    URL(string: "https://\(quickNodeBscCredentials.subdomain).bsc.discover.quiknode.pro/\(quickNodeBscCredentials.apiKey)/")!,
                ]
            }
        case .polygon:
            if blockchain.isTestnet {
                return [
                    URL(string: "https://rpc-mumbai.maticvigil.com/")!,
                ]
            } else {
                // https://wiki.polygon.technology/docs/operate/network-rpc-endpoints
                return [
                    URL(string: "https://polygon-rpc.com")!,
                    URL(string: "https://matic.nownodes.io/\(nowNodesApiKey)")!,
                    URL(string: "https://matic.getblock.io/mainnet?api_key=\(getBlockApiKey)")!,
                    URL(string: "https://matic-mainnet.chainstacklabs.com")!,
                    URL(string: "https://rpc-mainnet.maticvigil.com")!,
                    URL(string: "https://rpc-mainnet.matic.quiknode.pro")!,
                ]
            }
        case .avalanche:
            if blockchain.isTestnet {
                return [
                    URL(string: "https://api.avax-test.network/ext/bc/C/rpc")!,
                ]
            } else {
                return [
                    URL(string: "https://api.avax.network/ext/bc/C/rpc")!,
                    URL(string: "https://avax.nownodes.io/\(nowNodesApiKey)/ext/bc/C/rpc")!,
                    URL(string: "https://avax.getblock.io/mainnet/ext/bc/C/rpc?api_key=\(getBlockApiKey)")!,
                ]
            }
        case .fantom:
            if blockchain.isTestnet {
                return [
                    URL(string: "https://rpc.testnet.fantom.network/")!,
                ]
            } else {
                return [
                    URL(string: "https://ftm.nownodes.io/\(nowNodesApiKey)")!,
                    URL(string: "https://ftm.getblock.io/mainnet?api_key=\(getBlockApiKey)")!,
                    URL(string: "https://rpc.ftm.tools/")!,
                    URL(string: "https://rpcapi.fantom.network/")!,
                    URL(string: "https://fantom-mainnet.public.blastapi.io")!,
                    URL(string: "https://fantom-rpc.gateway.pokt.network")!,
                    URL(string: "https://rpc.ankr.com/fantom")!,
                ]
            }
        case .arbitrum(let testnet):
            if testnet {
                return [
                    URL(string: "https://goerli-rollup.arbitrum.io/rpc")!,
                ]
            } else {
                return [
                    // https://developer.offchainlabs.com/docs/mainnet#connect-your-wallet
                    URL(string: "https://arb1.arbitrum.io/rpc")!,
                    URL(string: "https://arbitrum-mainnet.infura.io/v3/\(infuraProjectId)")!,
                    URL(string: "https://arbitrum.nownodes.io/\(nowNodesApiKey)")!,
                ]
            }
        case .gnosis:
            return [
                URL(string: "https://gno.getblock.io/mainnet?api_key=\(getBlockApiKey)")!,
                
                // from registry.json
                URL(string: "https://rpc.gnosischain.com")!,
                
                // from chainlist.org
                URL(string: "https://gnosischain-rpc.gateway.pokt.network")!,
                URL(string: "https://gnosis-mainnet.public.blastapi.io")!,
                URL(string: "https://xdai-rpc.gateway.pokt.network")!,
                URL(string: "https://rpc.ankr.com/gnosis")!,
            ]
        case .optimism(let testnet):
            if testnet {
                return [
                    URL(string: "https://goerli.optimism.io")!,
                ]
            } else {
                return [
                    URL(string: "https://mainnet.optimism.io")!,
                    URL(string: "https://optimism.nownodes.io/\(nowNodesApiKey)")!,
                    URL(string: "https://optimism-mainnet.public.blastapi.io")!,
                    URL(string: "https://rpc.ankr.com/optimism")!,
                ]
            }
        case .saltPay:
            return [
                URL(string: "https://rpc.bicoccachain.net")!,
            ]
        case .kava:
            if blockchain.isTestnet {
                return [URL(string: "https://evm.testnet.kava.io")!]
            }
            
            return [URL(string: "https://evm.kava.io")!,
                    URL(string: "https://evm2.kava.io")!]
        case .cronos:
            return [
                URL(string: "https://evm.cronos.org")!,
                URL(string: "https://evm-cronos.crypto.org")!,
                URL(string: "https://cro.getblock.io/mainnet/\(getBlockApiKey)")!,
                URL(string: "https://node.croswap.com/rpc")!,
                URL(string: "https://cronos.blockpi.network/v1/rpc/public")!,
                URL(string: "https://cronos-evm.publicnode.com")!,
            ]
        case .telos:
            if blockchain.isTestnet {
                return [
                    URL(string: "https://telos-evm-testnet.rpc.thirdweb.com")!
                ]
            } else {
                return [
                    URL(string: "https://mainnet.telos.net/evm")!,
                    URL(string: "https://api.kainosbp.com/evm")!,
                    URL(string: "https://telos-evm.rpc.thirdweb.com")!
                ]
            }
        case .octa:
            return [
                URL(string: "https://rpc.octa.space")!,
                URL(string: "https://octaspace.rpc.thirdweb.com")!,
            ]
        default:
            return nil
        }
    }
}
