//
//  WalletManagerFactory.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 06.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import stellarsdk
import BitcoinCore
import Solana_Swift

public typealias APIOrder = [String: [APIInfo]]

public struct APIInfo: Decodable {
    let type: APIType
    let provider: String?
    let url: String?

    var api: API? {
        API(rawValue: provider ?? "")
    }

    public init(type: APIInfo.APIType, provider: String? = nil, url: String? = nil) {
        self.type = type
        self.provider = provider
        self.url = url
    }
}

public extension APIInfo {
    enum APIType: String, Decodable {
        case `public` = "public"
        case `private` = "private"
    }
}

public enum API: String {
    case nownodes
    case quicknode
    case getblock
    case blockchair
    case blockcypher
    case ton
    case tron
    case hedera
    case infura
    case adalite
    case tangemRosetta
}

struct APILinkResolver {
    let blockchain: Blockchain
    let config: BlockchainSdkConfig

    func resolve(for apiInfo: APIInfo) -> String? {
        switch apiInfo.type {
        case .public:
            guard let url = apiInfo.url else {
                return nil
            }

            return url
        case .private:
            guard let api = apiInfo.api else {
                return nil
            }

            return PrivateAPILinkResolver(blockchain: blockchain, config: config)
                .resolve(for: api)
        }
    }
}

struct NodeInfo {
    let url: URL
    let keyInfo: APIKeyInfo?
    var link: String {
        url.absoluteString
    }

    init(url: URL, keyInfo: APIKeyInfo? = nil) {
        self.url = url
        self.keyInfo = keyInfo
    }
}
struct APIResolver {
    let blockchain: Blockchain
    let config: BlockchainSdkConfig

    func resolveProviders<T>(order: APIOrder, factory: (NodeInfo) -> T?) -> [T] {
        guard let infos = order[blockchain.codingKey] else {
            return []
        }

        let keyInfoProvider = APIKeysInfoProvider(blockchain: blockchain, config: config)
        let nodes: [NodeInfo]
        var urls: [URL]
        if blockchain.isTestnet {
//            nodes = TestnetAPIURLProvider(blockchain: blockchain).urls()?.map {
//
//            }
        } else {
            let linkResolver = APILinkResolver(blockchain: blockchain, config: config)
            infos.forEach {
                URL(string: linkResolver.resolve(for: $0) ?? "")
            }

        }

        return []
//        return urls.compactMap {
//            let nodeInfo = NodeInfo(
//                url: $0,
//                keyInfo: keyInfoProvider.apiKeys(for: $0))
//
//        }
//        let providers: [T] = infos.compactMap {
//            guard
//                let link = linkResolver.resolve(for: $0),
//                let url = URL(string: link)
//            else {
//                return nil
//            }
//
//            let nodeInfo = NodeInfo(
//                url: url,
//                keyInfo: keyInfoProvider.apiKeys(for: $0)
//            )
//            return factory(nodeInfo)
//        }
//        return providers

    }
}

struct TestnetAPIURLProvider {
    let blockchain: Blockchain

    func urls() -> [NodeInfo]? {
        guard blockchain.isTestnet else {
            return nil
        }

        switch blockchain {
        case .cosmos:
            return [ .init(url: URL(string: "https://rest.seed-01.theta-testnet.polypore.xyz")!) ]
        case .near:
            return [ .init(url: URL(string: "https://rpc.testnet.near.org")!) ]
        case .azero:
            return [
                .init(url: URL(string: "https://rpc.test.azero.dev")!),
                .init(url: URL(string: "aleph-zero-testnet-rpc.dwellir.com")!)
            ]
        case .ravencoin:
            return [
                .init(url: URL(string: "https://testnet.ravencoin.network/api")!)
            ]
        case .stellar:
            return [
                .init(url: URL(string: "https://horizon-testnet.stellar.org")!)
            ]
        case .tron:
            return [
                .init(url: URL(string: "https://nile.trongrid.io")!)
            ]
        case .algorand:
            return [ .init(url: URL(string: "https://testnet-api.algonode.cloud")!) ]
//        case .ton:
//            return [
//                .init(url: URL(string: "https://testnet.toncenter.com/api/v2")!,
//                      keyInfo: <#T##APIKeyInfo?#>)
//            ]
        default:
            return nil
        }
    }
}

struct PrivateAPILinkResolver {
    let blockchain: Blockchain
    let config: BlockchainSdkConfig

    func resolve(for api: API) -> String? {
        switch api {
        case .nownodes:
            return NownodesLinkResolver(apiKey: config.nowNodesApiKey)
                .resolve(for: blockchain)
        case .quicknode:
            return QuickNodeLinkResolver()
                .resolve(for: blockchain)
        case .getblock:
            return GetBlockLinkProvider(credentials: config.getBlockCredentials)
                .resolve(for: blockchain)
        case .ton:
            return blockchain.isTestnet ?
            "https://testnet.toncenter.com/api/v2" :
            "https://toncenter.com/api/v2"
        case .tron:
            return "https://api.trongrid.io"
        case .adalite:
            return  "https://explorer2.adalite.io"
        case .tangemRosetta:
            return "https://ada.tangem.com"
        case .hedera, .blockchair, .blockcypher, .infura:
            return nil
        }
    }
}

struct NownodesLinkResolver {
    let apiKey: String

    func resolve(for blockchain: Blockchain) -> String? {
        if blockchain.isTestnet {
            if case .ethereum = blockchain { } else {
                return nil
            }
        }

        switch blockchain {
        case .ethereum(let isTestnet):
            return isTestnet ? "https://eth-goerli.nownodes.io/\(apiKey)" : "https://eth.nownodes.io/\(apiKey)"
        case .cosmos:
            return "https://atom.nownodes.io/\(apiKey)"
        case .terraV1:
            return "https://lunc.nownodes.io/\(apiKey)"
        case .terraV2:
            return "https://luna.nownodes.io/\(apiKey)"
        case .near:
            return "https://near.nownodes.io/\(apiKey)"
        case .stellar:
            return "https://xlm.nownodes.io/\(apiKey)"
        case .ton:
            return "https://ton.nownodes.io/\(apiKey)"
        case .tron:
            return "https://trx.nownodes.io"
        case .veChain:
            return "https://vet.nownodes.io/\(apiKey)"
        case .algorand:
            return "https://algo.nownodes.io"
        default:
            return nil
        }
    }
}

struct QuickNodeLinkResolver {
    func resolve(for blockchain: Blockchain) -> String? {
        return nil
    }
}

struct GetBlockLinkProvider {
    let credentials: BlockchainSdkConfig.GetBlockCredentials

    func resolve(for blockchain: Blockchain) -> String? {
        if blockchain.isTestnet {
            return nil
        }

        switch blockchain {
        case .cosmos, .tron, .algorand:
            return "https://go.getblock.io/\(credentials.credential(for: blockchain, type: .rest))"
        case .near, .ton:
            return "https://go.getblock.io/\(credentials.credential(for: blockchain, type: .jsonRpc))"
        case .cardano:
            return "https://go.getblock.io/\(credentials.credential(for: blockchain, type: .rosetta))"
        default:
            return nil
        }
    }
}

struct APIKeysInfoProvider {
    let blockchain: Blockchain
    let config: BlockchainSdkConfig

    func apiKeys(for api: API?) -> APIKeyInfo? {
        guard let api else { return nil }

        switch api {
        case .nownodes:
            return NownodesAPIKeysInfoProvider(apiKey: config.nowNodesApiKey)
                .apiKeys(for: blockchain)
        case .ton:
            return .init(
                headerName: Constants.xApiKeyHeaderName,
                headerValue: config.tonCenterApiKeys.getApiKey(for: blockchain.isTestnet)
            )
        case .tron:
            return .init(
                headerName: "TRON-PRO-API-KEY",
                headerValue: config.tronGridApiKey
            )
        default:
            return nil
        }
    }
}

struct NownodesAPIKeysInfoProvider {
    let apiKey: String
    func apiKeys(for blockchain: Blockchain) -> APIKeyInfo? {
        switch blockchain {
        case .xrp, .tron, .algorand:
            return .init(
                headerName: Constants.nowNodesApiKeyHeaderName,
                headerValue: apiKey
            )
        default: return nil
        }
    }
}

struct TransactionHistoryAPILinkProvider {
    let config: BlockchainSdkConfig

    func link(for blockchain: Blockchain, api: API?) -> URL? {
        switch api {
        case .nownodes:
            return NownodesTransactionHistoryAPILinkProvider(apiKey: config.nowNodesApiKey)
                .link(for: blockchain)
        default:
            break
        }

        switch blockchain {
        case .algorand(_, let isTestnet):
            return isTestnet ?
            URL(string: "https://testnet-idx.algonode.cloud")! :
            URL(string: "https://mainnet-idx.algonode.cloud")!
        default:
            return nil
        }
    }
}

struct NownodesTransactionHistoryAPILinkProvider {
    let apiKey: String

    func link(for blockchain: Blockchain) -> URL? {
        switch blockchain {
        case .algorand:
            return URL(string: "https://algo-index.nownodes.io")!
        default:
            return nil
        }
    }
}

@available(iOS 13.0, *)
public class WalletManagerFactory {
    
    private let config: BlockchainSdkConfig
    private let dependencies: BlockchainSdkDependencies
    private let apiOrder: APIOrder

    // MARK: - Init

    public init(
        config: BlockchainSdkConfig,
        dependencies: BlockchainSdkDependencies,
        apiOrder: APIOrder
    ) {
        self.config = config
        self.dependencies = dependencies
        self.apiOrder = apiOrder
    }
    
    public func makeWalletManager(blockchain: Blockchain, publicKey: Wallet.PublicKey) throws -> WalletManager {
        let walletFactory = WalletFactory(blockchain: blockchain)
        let wallet = try walletFactory.makeWallet(publicKey: publicKey)
        return try makeWalletManager(wallet: wallet)
    }
    
    /// Only for Tangem Twin Cards
    /// - Parameters:
    ///   - walletPublicKey: First public key
    ///   - pairKey: Pair public key
    public func makeTwinWalletManager(walletPublicKey: Data, pairKey: Data, isTestnet: Bool) throws -> WalletManager {
        let blockchain: Blockchain = .bitcoin(testnet: isTestnet)
        let publicKey = Wallet.PublicKey(seedKey: walletPublicKey, derivationType: .none)
        let walletFactory = WalletFactory(blockchain: blockchain)
        let wallet = try walletFactory.makeWallet(publicKey: publicKey, pairPublicKey: pairKey)
        return try makeWalletManager(wallet: wallet, pairPublicKey: pairKey)
    }
}

// MARK: - Private Implementation

private extension WalletManagerFactory {
    func makeWalletManager(
        wallet: Wallet,
        pairPublicKey: Data? = nil
    ) throws -> WalletManager {
        let blockchain = wallet.blockchain
        let input = WalletManagerAssemblyInput(
            wallet: wallet,
            pairPublicKey: pairPublicKey,
            blockchainSdkConfig: config,
            blockchainSdkDependencies: dependencies,
            apiOrder: apiOrder
        )
        return try blockchain.assembly.make(with: input)
    }
}

// MARK: - Stub Implementation

extension WalletManagerFactory {
    
    /// Use this method only Test and Debug [Addresses, Fees, etc.]
    /// - Parameters:
    ///   - blockhain Card native blockchain will be used
    ///   - walletPublicKey: Wallet public key or dummy input
    ///   - addresses: Dummy input addresses
    /// - Returns: WalletManager model
    public func makeStubWalletManager(
        blockchain: Blockchain,
        dummyPublicKey: Data,
        dummyAddress: String
    ) throws -> WalletManager {let publicKey = Wallet.PublicKey(seedKey: dummyPublicKey, derivationType: .none)
        let address: Address

        if dummyAddress.isEmpty {
            let service = AddressServiceFactory(blockchain: blockchain).makeAddressService()
            address = try service.makeAddress(for: publicKey, with: .default)
        } else {
            address = PlainAddress(value: dummyAddress, publicKey: publicKey, type: .default)
        }
        
        let wallet = Wallet(blockchain: blockchain, addresses: [.default: address])
        let input = WalletManagerAssemblyInput(
            wallet: wallet,
            pairPublicKey: nil,
            blockchainSdkConfig: config, 
            blockchainSdkDependencies: dependencies, 
            apiOrder: apiOrder
        )
        return try blockchain.assembly.make(with: input)
    }
    
}
