//
//  Blockchain.swift
//  blockchainSdk
//
//  Created by Alexander Osokin on 04.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

// MARK: - Base
@available(iOS 13.0, *)
public enum Blockchain: Equatable, Hashable {
    case bitcoin(testnet: Bool)
    case litecoin
    case stellar(testnet: Bool)
    case ethereum(testnet: Bool)
    case ethereumPoW(testnet: Bool)
    case ethereumFair
    case ethereumClassic(testnet: Bool)
    case rsk
    case bitcoinCash(testnet: Bool)
    case binance(testnet: Bool)
    case cardano(shelley: Bool)
    case xrp(curve: EllipticCurve)
    case ducatus
    case tezos(curve: EllipticCurve)
    case dogecoin
    case bsc(testnet: Bool)
    case polygon(testnet: Bool)
    case avalanche(testnet: Bool)
    case solana(testnet: Bool)
    case fantom(testnet: Bool)
    case polkadot(testnet: Bool)
    case kusama
    case tron(testnet: Bool)
    case arbitrum(testnet: Bool)
    case dash(testnet: Bool)
    case gnosis
    case optimism(testnet: Bool)
    case saltPay
    
    public var isTestnet: Bool {
        switch self {
        case .bitcoin(let testnet):
            return testnet
        case .litecoin, .ducatus, .cardano, .xrp, .rsk, .tezos, .dogecoin, .kusama:
            return false
        case .stellar(let testnet):
            return testnet
        case .ethereum(let testnet), .bsc(let testnet):
            return testnet
        case .ethereumClassic(let testnet):
            return testnet
        case .bitcoinCash(let testnet):
            return testnet
        case .binance(let testnet):
            return testnet
        case .polygon(let testnet):
            return testnet
        case .avalanche(let testnet):
            return testnet
        case .solana(let testnet):
            return testnet
        case .fantom(let testnet):
            return testnet
        case .polkadot(let testnet):
            return testnet
        case .tron(let testnet):
            return testnet
        case .arbitrum(let testnet):
            return testnet
        case .dash(let testnet):
            return testnet
        case .gnosis:
            return false
        case .optimism(let testnet):
            return testnet
        case .ethereumPoW(let testnet):
            return testnet
        case .ethereumFair:
            return false
        case .saltPay:
            return false
        }
    }
    
    public var curve: EllipticCurve {
        switch self {
        case .stellar, .cardano, .solana, .polkadot, .kusama:
            return .ed25519
        case .xrp(let curve):
            return curve
        case .tezos(let curve):
            return curve
        default:
            return .secp256k1
        }
    }
    
    public var shelly: Bool {
        switch self {
        case .cardano(let shelley):
            return shelley
        default:
            return false
        }
    }
    
    public var decimalCount: Int {
        switch self {
        case .bitcoin, .litecoin, .bitcoinCash, .ducatus, .binance, .dogecoin, .dash:
            return 8
        case .ethereum, .ethereumClassic, .ethereumPoW, .ethereumFair, .rsk, .bsc, .polygon, .avalanche, .fantom, .arbitrum, .gnosis, .optimism, .saltPay:
            return 18
        case  .cardano, .xrp, .tezos, .tron:
            return 6
        case .stellar:
            return 7
        case .solana:
            return 9
        case .polkadot(let testnet):
            return testnet ? 12 : 10
        case .kusama:
            return 12
        }
    }
    
    public var currencySymbol: String {
        switch self {
        case .bitcoin:
            return "BTC"
        case .litecoin:
            return "LTC"
        case .stellar:
            return "XLM"
        case .ethereum, .arbitrum, .optimism:
            return "ETH"
        case .ethereumClassic:
            return "ETC"
        case .rsk:
            return "RBTC"
        case .bitcoinCash:
            return "BCH"
        case .binance:
            return "BNB"
        case .ducatus:
            return "DUC"
        case .cardano:
            return "ADA"
        case .xrp:
            return "XRP"
        case .tezos:
            return "XTZ"
        case .dogecoin:
            return "DOGE"
        case .bsc:
            return "BNB"
        case .polygon:
            return "MATIC"
        case .avalanche:
            return "AVAX"
        case .solana:
            return "SOL"
        case .fantom:
            return "FTM"
        case .polkadot(let testnet):
            return testnet ? "WND" : "DOT"
        case .kusama:
            return "KSM"
        case .tron:
            return "TRX"
        case .dash(let testnet):
            return testnet ? "tDASH" : "DASH"
        case .gnosis, .saltPay:
            return "xDAI"
        case .ethereumPoW:
            return "ETHW"
        case .ethereumFair:
            return "ETF"
        }
    }
    
    public var displayName: String {
        let testnetSuffix = isTestnet ? " Testnet" : ""
        
        switch self {
        case .bitcoinCash:
            return "Bitcoin Cash" + testnetSuffix
        case .ethereumClassic:
            return "Ethereum Classic" + testnetSuffix
        case .ethereumPoW:
            return "Ethereum PoW" + testnetSuffix
        case .ethereumFair:
            return "Ethereum Fair" + testnetSuffix
        case .xrp:
            return "XRP Ledger"
        case .rsk:
            return "\(self)".uppercased()
        case .bsc:
            return "BNB Smart Chain" + testnetSuffix
        case .binance:
            return "BNB Beacon Chain" + testnetSuffix
        case .avalanche:
            return "Avalanche C-Chain" + testnetSuffix
        case .fantom:
            return isTestnet ? "Fantom" + testnetSuffix : "Fantom Opera"
        case .polkadot:
            return "Polkadot" + testnetSuffix + (isTestnet ? " (Westend)" : "")
        case .gnosis:
            return "Gnosis Chain" + testnetSuffix
        case .optimism:
            return "Optimistic Ethereum" + testnetSuffix
        case .saltPay:
            return "Salt Pay"
        default:
            var name = "\(self)".capitalizingFirstLetter()
            if let index = name.firstIndex(of: "(") {
                name = String(name.prefix(upTo: index))
            }
            return name + testnetSuffix
        }
    }
    
    public var tokenTypeName: String? {
        switch self {
        case .ethereum: return "ERC20"
        case .binance: return "BEP2"
        case .bsc: return "BEP20"
        case .tron: return "TRC20"
        default:
            return nil
        }
    }
    
    public var canHandleTokens: Bool {
        if isEvm {
            return true
        }
        
        switch self {
        case .binance, .solana, .tron:
            return true
        default:
            return false
        }
    }
    
    public func isFeeApproximate(for amountType: Amount.AmountType) -> Bool {
        switch self {
        case .arbitrum, .stellar, .optimism, .ethereumPoW:
            return true
        case .fantom, .tron, .gnosis, .avalanche:
            if case .token = amountType {
                return true
            }
        default:
            break
        }
        
        return false
    }
}

// MARK: - Ethereum based blockchain definition
@available(iOS 13.0, *)
extension Blockchain {
    public var isEvm: Bool { chainId != nil }
    
    // Only fot Ethereum compatible blockchains
    // https://chainlist.org
    public var chainId: Int? {
        switch self {
        case .ethereum: return isTestnet ? 5 : 1
        case .ethereumClassic: return isTestnet ? 6 : 61 // https://besu.hyperledger.org/en/stable/Concepts/NetworkID-And-ChainID/
        case .ethereumPoW: return isTestnet ? 10002 : 10001
        case .ethereumFair: return 513100
        case .rsk: return 30
        case .bsc: return isTestnet ? 97 : 56
        case .polygon: return isTestnet ? 80001 : 137
        case .avalanche: return isTestnet ? 43113 : 43114
        case .fantom: return isTestnet ? 4002 : 250
        case .arbitrum: return isTestnet ? 421613 : 42161
        case .gnosis: return 100
        case .optimism: return isTestnet ? 420 : 10
        case .saltPay: return 29313331
        default: return nil
        }
    }
    
    //Only for Ethereum compatible blockchains
    public func getJsonRpcEndpoints(keys: EthereumApiKeys) -> [RPCEndpoint]? {
        let infuraProjectId = keys.infuraProjectId
        let nowNodesApiKey = keys.nowNodesApiKey
        let getBlockApiKey = keys.getBlockApiKey
        let quickNodeBscCredentials = keys.quickNodeBscCredentials
        
        switch self {
        case .ethereum:
            if isTestnet {
                return [
                    RPCEndpoint(url: URL(string: "https://eth-goerli.nownodes.io/\(nowNodesApiKey)")!),
                    RPCEndpoint(url: URL(string: "https://goerli.infura.io/v3/\(infuraProjectId)")!),
                ]
            } else {
                return [
                    RPCEndpoint(url: URL(string: "https://eth.nownodes.io/\(nowNodesApiKey)")!),
                    RPCEndpoint(url: URL(string: "https://eth.getblock.io/mainnet/")!, apiKeyHeaderName: Constants.getBlockApiKeyHeaderName, apiKeyHeaderValue: getBlockApiKey),
                    RPCEndpoint(url: URL(string: "https://mainnet.infura.io/v3/\(infuraProjectId)")!),
                ]
            }
        case .ethereumClassic:
            if isTestnet {
                return [
                    RPCEndpoint(url: URL(string: "https://www.ethercluster.com/kotti")!),
                ]
            } else {
                return [
                    RPCEndpoint(url: URL(string: "https://etc.getblock.io/mainnet/")!, apiKeyHeaderName: Constants.getBlockApiKeyHeaderName, apiKeyHeaderValue: getBlockApiKey),
                    RPCEndpoint(url: URL(string: "https://www.ethercluster.com/etc")!),
                    RPCEndpoint(url: URL(string: "https://etc.etcdesktop.com")!),
                    RPCEndpoint(url: URL(string: "https://blockscout.com/etc/mainnet/api/eth-rpc")!),
                    RPCEndpoint(url: URL(string: "https://etc.mytokenpocket.vip")!),
                    RPCEndpoint(url: URL(string: "https://besu.etc-network.info")!),
                    RPCEndpoint(url: URL(string: "https://geth.etc-network.info")!),
                ]
            }
        case .ethereumPoW:
            if isTestnet {
                return [
                    RPCEndpoint(url: URL(string: "https://iceberg.ethereumpow.org")!),
                ]
            } else {
                return [
                    RPCEndpoint(url: URL(string: "https://ethw.nownodes.io/\(nowNodesApiKey)")!),
                    RPCEndpoint(url: URL(string: "https://mainnet.ethereumpow.org")!),
                ]
            }
        case .ethereumFair:
            return [
                RPCEndpoint(url: URL(string: "https://rpc.etherfair.org")!),
            ]
        case .rsk:
            return [
                RPCEndpoint(url: URL(string: "https://rsk.getblock.io/mainnet/")!, apiKeyHeaderName: Constants.getBlockApiKeyHeaderName, apiKeyHeaderValue: getBlockApiKey),
                RPCEndpoint(url: URL(string: "https://public-node.rsk.co/")!),
            ]
        case .bsc:
            if isTestnet {
                return [
                    RPCEndpoint(url: URL(string: "https://data-seed-prebsc-1-s1.binance.org:8545/")!),
                ]
            } else {
                return [
                    RPCEndpoint(url: URL(string: "https://bsc.nownodes.io/\(nowNodesApiKey)")!),
                    RPCEndpoint(url: URL(string: "https://bsc.getblock.io/mainnet/")!, apiKeyHeaderName: Constants.getBlockApiKeyHeaderName, apiKeyHeaderValue: getBlockApiKey),
                    RPCEndpoint(url: URL(string: "https://bsc-dataseed.binance.org/")!),
                    RPCEndpoint(url: URL(string: "https://\(quickNodeBscCredentials.subdomain).bsc.discover.quiknode.pro/\(quickNodeBscCredentials.apiKey)/")!),
                ]
            }
        case .polygon:
            if isTestnet {
                return [
                    RPCEndpoint(url: URL(string: "https://rpc-mumbai.maticvigil.com/")!),
                ]
            } else {
                // https://docs.polygon.technology/docs/develop/network-details/network/
                return [
                    RPCEndpoint(url: URL(string: "https://matic.nownodes.io/\(nowNodesApiKey)")!),
                    RPCEndpoint(url: URL(string: "https://matic.getblock.io/mainnet/")!, apiKeyHeaderName: Constants.getBlockApiKeyHeaderName, apiKeyHeaderValue: getBlockApiKey),
                    RPCEndpoint(url: URL(string: "https://polygon-rpc.com")!),
                    RPCEndpoint(url: URL(string: "https://rpc-mainnet.matic.network")!),
                    RPCEndpoint(url: URL(string: "https://matic-mainnet.chainstacklabs.com")!),
                    RPCEndpoint(url: URL(string: "https://rpc-mainnet.maticvigil.com")!),
                    RPCEndpoint(url: URL(string: "https://rpc-mainnet.matic.quiknode.pro")!),
                    RPCEndpoint(url: URL(string: "https://matic-mainnet-full-rpc.bwarelabs.com")!),
                ]
            }
        case .avalanche:
            if isTestnet {
                return [
                    RPCEndpoint(url: URL(string: "https://api.avax-test.network/ext/bc/C/rpc")!),
                ]
            } else {
                return [
                    RPCEndpoint(url: URL(string: "https://avax.nownodes.io/\(nowNodesApiKey)")!),
                    RPCEndpoint(url: URL(string: "https://avax.getblock.io/mainnet/ext/bc/C/rpc")!, apiKeyHeaderName: Constants.getBlockApiKeyHeaderName, apiKeyHeaderValue: getBlockApiKey),
                    RPCEndpoint(url: URL(string: "https://api.avax.network/ext/bc/C/rpc")!),
                ]
            }
        case .fantom:
            if isTestnet {
                return [
                    RPCEndpoint(url: URL(string: "https://rpc.testnet.fantom.network/")!),
                ]
            } else {
                return [
                    RPCEndpoint(url: URL(string: "https://ftm.nownodes.io/\(nowNodesApiKey)")!),
                    RPCEndpoint(url: URL(string: "https://ftm.getblock.io/mainnet")!, apiKeyHeaderName: Constants.getBlockApiKeyHeaderName, apiKeyHeaderValue: getBlockApiKey),
                    RPCEndpoint(url: URL(string: "https://rpc.ftm.tools/")!),
                    RPCEndpoint(url: URL(string: "https://rpcapi.fantom.network/")!),
                    RPCEndpoint(url: URL(string: "http://rpc.ankr.tools/ftm")!),
                    RPCEndpoint(url: URL(string: "https://ftmrpc.ultimatenodes.io/")!),
                ]
            }
        case .arbitrum(let testnet):
            if testnet {
                return [
                    RPCEndpoint(url: URL(string: "https://goerli-rollup.arbitrum.io/rpc")!),
                ]
            } else {
                return [
                    // https://developer.offchainlabs.com/docs/mainnet#connect-your-wallet
                    RPCEndpoint(url: URL(string: "https://arb1.arbitrum.io/rpc")!),
                    RPCEndpoint(url: URL(string: "https://arbitrum-mainnet.infura.io/v3/\(infuraProjectId)")!),
                    
                    // from wallet-core's registry.json
                    RPCEndpoint(url: URL(string: "https://node.offchainlabs.com:8547")!),
                ]
            }
        case .gnosis:
            return [
                RPCEndpoint(url: URL(string: "https://gno.getblock.io/mainnet/")!, apiKeyHeaderName: Constants.getBlockApiKeyHeaderName, apiKeyHeaderValue: getBlockApiKey),
                
                // from registry.json
                RPCEndpoint(url: URL(string: "https://rpc.gnosischain.com")!),
                
                // from chainlist.org
                RPCEndpoint(url: URL(string: "https://gnosischain-rpc.gateway.pokt.network")!),
                RPCEndpoint(url: URL(string: "https://rpc.ankr.com/gnosis")!),
                RPCEndpoint(url: URL(string: "https://gnosis-mainnet.public.blastapi.io")!),
                RPCEndpoint(url: URL(string: "https://xdai-rpc.gateway.pokt.network")!),
                RPCEndpoint(url: URL(string: "https://xdai-archive.blockscout.com")!),
                RPCEndpoint(url: URL(string: "https://rpc.gnosischain.com")!),
            ]
        case .optimism(let testnet):
            if testnet {
                return [
                    RPCEndpoint(url: URL(string: "https://goerli.optimism.io")!),
                ]
            } else {
                return [
                    RPCEndpoint(url: URL(string: "https://optimism.nownodes.io/\(nowNodesApiKey)")!),
                    RPCEndpoint(url: URL(string: "https://optimism.getblock.io/mainnet/")!, apiKeyHeaderName: Constants.getBlockApiKeyHeaderName, apiKeyHeaderValue: getBlockApiKey),
                    RPCEndpoint(url: URL(string: "https://mainnet.optimism.io")!),
                    RPCEndpoint(url: URL(string: "https://optimism-mainnet.public.blastapi.io")!),
                    RPCEndpoint(url: URL(string: "https://rpc.ankr.com/optimism")!),
                ]
            }
        case .saltPay:
            return [
                RPCEndpoint(url: URL(string: "https://rpc.bicoccachain.net")!),
            ]
        default:
            return nil
        }
    }
}

// MARK: - Address creation
@available(iOS 13.0, *)
extension Blockchain {
    public func derivationPath(for style: DerivationStyle = .legacy) -> DerivationPath? {
        guard curve == .secp256k1 || curve == .ed25519 else { return  nil }
        
        switch self {
        case .stellar, .solana:
            //Path according to sep-0005. https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md
            // Solana path consistent with TrustWallet:
            // https://github.com/trustwallet/wallet-core/blob/456f22d6a8ce8a66ccc73e3b42bcfec5a6afe53a/registry.json#L1013
            return DerivationPath(nodes: [.hardened(BIP44.purpose),
                                          .hardened(coinType(for: style)),
                                          .hardened(0)])
        case .cardano(let shelley):
            if !shelley { //We use shelley for all new cards with HD wallets feature
                return nil
            }
            
            //Path according to CIP-1852. https://cips.cardano.org/cips/cip1852/
            return DerivationPath(nodes: [.hardened(1852), //purpose
                                          .hardened(coinType(for: style)),
                                          .hardened(0),
                                          .nonHardened(0),
                                          .nonHardened(0)])
        default:
            //Standart bip44
            let bip44 = BIP44(coinType: coinType(for: style),
                              account: 0,
                              change: .external,
                              addressIndex: 0)
            
            return bip44.buildPath()
        }
    }
    
    public func coinType(for style: DerivationStyle = .legacy) -> UInt32 {
        if isTestnet {
            return 1
        }
        
        let ethCoinType: UInt32 = 60
        
        if style == .new, isEvm {
            return ethCoinType
        }
        
        // https://github.com/satoshilabs/slips/blob/master/slip-0044.md
        switch self {
        case .bitcoin, .ducatus: return 0
        case .litecoin: return 2
        case .dogecoin: return 3
        case .ethereum, .ethereumPoW, .ethereumFair, .saltPay: return ethCoinType
        case .ethereumClassic: return 61
        case .bsc: return 9006
        case .bitcoinCash: return 145
        case .binance: return 714
        case .xrp: return 144
        case .tezos: return 1729
        case .stellar: return 148
        case .cardano: return 1815
        case .rsk: return 137
        case .polygon: return 966
        case .avalanche: return 9000
        case .solana: return 501
        case .fantom: return 1007
        case .polkadot: return 354
        case .kusama: return 434
        case .tron: return 195
        case .arbitrum: return 9001
        case .dash: return 5
        case .gnosis: return 700
        case .optimism: return 614
        }
    }
    
    public func makeAddresses(from walletPublicKey: Data, with pairPublicKey: Data?) throws -> [Address] {
        let addressService = getAddressService()
        if let multiSigAddressProvider = addressService as? MultisigAddressProvider,
           let pairKey = pairPublicKey {
            return try multiSigAddressProvider.makeAddresses(from: walletPublicKey, with: pairKey)
        }
        
        return try addressService.makeAddresses(from: walletPublicKey)
    }
    
    public func validate(address: String) -> Bool {
        getAddressService().validate(address)
    }
    
    func getAddressService() -> AddressService {
        switch self {
        case .bitcoin:
            let network: BitcoinNetwork = isTestnet ? .testnet : .mainnet
            let networkParams = network.networkParams
            return BitcoinAddressService(networkParams: networkParams)
        case .litecoin:
            return BitcoinAddressService(networkParams: LitecoinNetworkParams())
        case .stellar:
            return StellarAddressService()
        case .ethereum, .ethereumClassic, .ethereumPoW, .ethereumFair,
                .bsc, .polygon, .avalanche, .fantom, .arbitrum, .gnosis, .optimism, .saltPay:
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
        }
    }
}

// MARK: - Sharing options
@available(iOS 13.0, *)
extension Blockchain {
    public var qrPrefixes: [String] {
        switch self {
        case .bitcoin:
            return ["bitcoin:"]
        case .ethereum:
            return [isTestnet ? "" : "ethereum:"]
        case .litecoin:
            return ["litecoin:"]
        case .xrp:
            return ["xrpl:", "ripple:", "xrp:"]
        case .binance:
            return ["bnb:"]
        case .dogecoin:
            return ["doge:", "dogecoin:"]
        default:
            return [""]
        }
    }
    
    public func getShareString(from address: String) -> String {
        switch self {
        case .bitcoin, .ethereum, .litecoin, .binance:
            return "\(qrPrefixes.first ?? "")\(address)"
        default:
            return "\(address)"
        }
    }
}

// MARK: - Codable
@available(iOS 13.0, *)
extension Blockchain: Codable {
    public var codingKey: String {
        switch self {
        case .binance: return "binance"
        case .bitcoin: return "bitcoin"
        case .bitcoinCash: return "bitcoinCash"
        case .cardano: return "cardano"
        case .ducatus: return "ducatus"
        case .ethereum: return "ethereum"
        case .ethereumClassic: return "ethereumClassic"
        case .litecoin: return "litecoin"
        case .rsk: return "rsk"
        case .stellar: return "stellar"
        case .tezos: return "tezos"
        case .xrp: return "xrp"
        case .dogecoin: return "dogecoin"
        case .bsc: return "bsc"
        case .polygon: return "polygon"
        case .avalanche: return "avalanche"
        case .solana: return "solana"
        case .fantom: return "fantom"
        case .polkadot: return "polkadot"
        case .kusama: return "kusama"
        case .tron: return "tron"
        case .arbitrum: return "arbitrum"
        case .dash: return "dash"
        case .gnosis: return "xdai"
        case .optimism: return "optimism"
        case .ethereumPoW: return "ethereum-pow-iou"
        case .ethereumFair: return "ethereumfair"
        case .saltPay: return "sxdai"
        }
    }
    
    enum Keys: CodingKey {
        case key
        case testnet
        case curve
        case shelley
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let key = try container.decode(String.self, forKey: Keys.key)
        let curveString = try container.decode(String.self, forKey: Keys.curve)
        let isTestnet = try container.decode(Bool.self, forKey: Keys.testnet)
        let shelley = try? container.decode(Bool.self, forKey: Keys.shelley)
        
        guard let curve = EllipticCurve(rawValue: curveString) else {
            throw BlockchainSdkError.decodingFailed
        }
        
        switch key {
        case "bitcoin": self = .bitcoin(testnet: isTestnet)
        case "stellar": self = .stellar(testnet: isTestnet)
        case "ethereum": self = .ethereum(testnet: isTestnet)
        case "ethereumClassic": self = .ethereumClassic(testnet: isTestnet)
        case "litecoin": self = .litecoin
        case "rsk": self = .rsk
        case "bitcoinCash": self = .bitcoinCash(testnet: isTestnet)
        case "binance": self = .binance(testnet: isTestnet)
        case "cardano": self =  .cardano(shelley: shelley!)
        case "xrp": self = .xrp(curve: curve)
        case "ducatus": self = .ducatus
        case "tezos": self = .tezos(curve: curve)
        case "dogecoin": self = .dogecoin
        case "bsc": self = .bsc(testnet: isTestnet)
        case "polygon", "matic": self = .polygon(testnet: isTestnet)
        case "avalanche": self = .avalanche(testnet: isTestnet)
        case "solana": self = .solana(testnet: isTestnet)
        case "fantom": self = .fantom(testnet: isTestnet)
        case "polkadot": self = .polkadot(testnet: isTestnet)
        case "kusama": self = .kusama
        case "tron": self = .tron(testnet: isTestnet)
        case "arbitrum": self = .arbitrum(testnet: isTestnet)
        case "dash": self = .dash(testnet: isTestnet)
        case "xdai": self = .gnosis
        case "optimism": self = .optimism(testnet: isTestnet)
        case "ethereum-pow-iou": self = .ethereumPoW(testnet: isTestnet)
        case "ethereumfair": self = .ethereumFair
        case "sxdai": self = .saltPay
        default: throw BlockchainSdkError.decodingFailed
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(codingKey, forKey: Keys.key)
        try container.encode(curve.rawValue, forKey: Keys.curve)
        try container.encode(isTestnet, forKey: Keys.testnet)
        
        if case let .cardano(shelley) = self {
            try container.encode(shelley, forKey: Keys.shelley)
        }
    }
}

// MARK: - URLs
@available(iOS 13.0, *)
extension Blockchain {
    public var testnetFaucetURL: URL? {
        guard isTestnet else { return nil }
        
        switch self {
        case .bitcoin:
            return URL(string: "https://coinfaucet.eu/en/btc-testnet/")
        case .ethereum:
            return URL(string: "https://goerlifaucet.com")
        case .ethereumClassic:
            return URL(string: "https://kottifaucet.me")
        case .ethereumPoW:
            return URL(string: "https://faucet.ethwscan.com")
        case .bitcoinCash:
            // alt
            // return URL(string: "https://faucet.fullstack.cash")
            return URL(string: "https://coinfaucet.eu/en/bch-testnet/")
        case .bsc:
            return URL(string: "https://testnet.binance.org/faucet-smart")
        case .binance:
            return URL(string: "https://docs.binance.org/smart-chain/wallet/binance.html")
//            return URL(string: "https://docs.binance.org/guides/testnet.html")
        case .polygon:
            return URL(string: "https://faucet.matic.network")
        case .stellar:
            return URL(string: "https://laboratory.stellar.org/#account-creator?network=test")
        case .solana:
            return URL(string: "https://solfaucet.com")
        case .avalanche:
            return URL(string: "https://faucet.avax-test.network/")
        case .fantom:
            return URL(string: "https://faucet.fantom.network")
        case .polkadot:
            return URL(string: "https://matrix.to/#/!cJFtAIkwxuofiSYkPN:matrix.org?via=matrix.org&via=matrix.parity.io&via=web3.foundation")
        case .tron:
            return URL(string: "https://nileex.io/join/getJoinPage")!
        case .dash:
            return URL(string: "http://faucet.test.dash.crowdnode.io/")!
            // Or another one https://testnet-faucet.dash.org/ - by Dash Core Group
        case .optimism:
            return URL(string: "https://optimismfaucet.xyz")! //another one https://faucet.paradigm.xyz
        default:
            return nil
        }
    }
    
    public func getExploreURL(from address: String, tokenContractAddress: String? = nil) -> URL? {
        switch self {
        case .binance:
            let baseUrl = isTestnet ? "https://testnet-explorer.binance.org/address/" : "https://explorer.binance.org/address/"
            return URL(string: baseUrl + address)
        case .bitcoin:
            let baseUrl = isTestnet ? "https://www.blockchair.com/bitcoin/testnet/address/" : "https://www.blockchair.com/bitcoin/address/"
            return URL(string: baseUrl + address)
        case .bitcoinCash:
            let baseUrl = isTestnet ? "https://www.blockchain.com/bch-testnet/address/" : "https://www.blockchair.com/bitcoin-cash/address/"
            return URL(string: baseUrl + address)
        case .cardano:
            let baseUrl = "https://www.blockchair.com/cardano/address/"
            return URL(string: baseUrl + address)
        case .ducatus:
            return URL(string: "https://insight.ducatus.io/#/DUC/mainnet/address/\(address)")
        case .ethereum:
            let baseUrl = isTestnet ? "https://goerli.etherscan.io/address/" : "https://etherscan.io/address/"
            let exploreLink = tokenContractAddress == nil ? baseUrl + address :
            "https://etherscan.io/token/\(tokenContractAddress!)?a=\(address)"
            return URL(string: exploreLink)
        case .ethereumClassic(let testnet):
            let network = testnet ? "kotti" : "mainnet"
            return URL(string: "https://blockscout.com/etc/\(network)/address/\(address)/transactions")!
        case .ethereumPoW(let testnet):
            if testnet {
                return URL(string: "http://iceberg.ethwscan.com/address/\(address)")
            } else {
                return URL(string: "https://mainnet.ethwscan.com/address/\(address)")
            }
        case .ethereumFair:
            return URL(string: "https://explorer.etherfair.org/address/\(address)")
        case .litecoin:
            return URL(string: "https://blockchair.com/litecoin/address/\(address)")
        case .rsk:
            var exploreLink = "https://explorer.rsk.co/address/\(address)"
            if tokenContractAddress != nil {
                exploreLink += "?__tab=tokens"
            }
            return URL(string: exploreLink)
        case .stellar:
            let baseUrl = isTestnet ? "https://stellar.expert/explorer/testnet/account/" : "https://stellar.expert/explorer/public/account/"
            let exploreLink =  baseUrl + address
            return URL(string: exploreLink)
        case .xrp:
            return URL(string: "https://xrpscan.com/account/\(address)")
        case .tezos:
            return URL(string: "https://tezblock.io/account/\(address)")
        case .dogecoin:
            return URL(string: "https://blockchair.com/dogecoin/address/\(address)")
        case .bsc:
            let baseUrl = isTestnet ? "https://testnet.bscscan.com/address/" : "https://bscscan.com/address/"
            let link = baseUrl + address
            return URL(string: link)
        case .polygon:
            let baseUrl = isTestnet ? "https://explorer-mumbai.maticvigil.com/address/" : "https://polygonscan.com/address/"
            let link = baseUrl + address
            return URL(string: link)
        case .avalanche:
            let baseUrl = isTestnet ? "https://testnet.snowtrace.io/address/" : "https://snowtrace.io/address/"
            let link = baseUrl + address
            return URL(string: link)
        case .solana:
            let baseUrl = "https://explorer.solana.com/address/"
            let cluster = isTestnet ? "?cluster=devnet" : ""
            return URL(string: baseUrl + address + cluster)
        case .fantom:
            let baseUrl = isTestnet ? "https://testnet.ftmscan.com/address/" : "https://ftmscan.com/address/"
            let link = baseUrl + address
            return URL(string: link)
        case .polkadot:
            let subdomain = isTestnet ? "westend" : "polkadot"
            return URL(string: "https://\(subdomain).subscan.io/account/\(address)")
        case .kusama:
            return URL(string: "https://kusama.subscan.io/account/\(address)")
        case .tron:
            let subdomain = isTestnet ? "nile." : ""
            return URL(string: "https://\(subdomain)tronscan.org/#/address/\(address)")!
        case .arbitrum:
            if isTestnet {
                return URL(string: "https://goerli-rollup-explorer.arbitrum.io/address/\(address)")!
            }
            return URL(string: "https://arbiscan.io/address/\(address)")!
        case .dash:
            let network = isTestnet ? "testnet" : "mainnet"
            return URL(string: "https://blockexplorer.one/dash/\(network)/address/\(address)")
        case .gnosis:
            return URL(string: "https://blockscout.com/xdai/mainnet/address/\(address)")!
        case .optimism:
            if isTestnet {
                return URL(string: "https://blockscout.com/optimism/goerli/address/\(address)")!
            }
            return URL(string: "https://optimistic.etherscan.io/address/\(address)")!
        case .saltPay:
            return URL(string: "https://blockscout.bicoccachain.net/address/\(address)")!
        }
    }
}

// MARK: - Helpers
@available(iOS 13.0, *)
extension Blockchain {
    public var decimalValue: Decimal {
        return pow(Decimal(10), decimalCount)
    }
}

// MARK: - Card's factory
@available(iOS 13.0, *)
extension Blockchain {
    public static func from(blockchainName: String, curve: EllipticCurve) -> Blockchain? {
        let testnetAttribute = "/test"
        let isTestnet = blockchainName.contains(testnetAttribute)
        let cleanName = blockchainName.remove(testnetAttribute).lowercased()
        switch cleanName {
        case "btc": return .bitcoin(testnet: isTestnet)
        case "xlm", "asset", "xlm-tag": return .stellar(testnet: isTestnet)
        case "eth", "token", "nfttoken": return .ethereum(testnet: isTestnet)
        case "ltc": return .litecoin
        case "rsk", "rsktoken": return .rsk
        case "bch": return .bitcoinCash(testnet: isTestnet)
        case "binance", "binanceasset": return .binance(testnet: isTestnet)
        case "cardano": return .cardano(shelley: false)
        case "cardano-s": return .cardano(shelley: true)
        case "xrp": return .xrp(curve: curve)
        case "duc": return .ducatus
        case "xtz": return .tezos(curve: curve)
        case "doge": return .dogecoin
        case "bsc": return .bsc(testnet: isTestnet)
        case "polygon": return .polygon(testnet: isTestnet)
        case "avalanche": return .avalanche(testnet: isTestnet)
        case "solana": return .solana(testnet: isTestnet)
        case "fantom": return .fantom(testnet: isTestnet)
        case "polkadot": return .polkadot(testnet: isTestnet)
        case "kusama": return .kusama
        case "tron": return .tron(testnet: isTestnet)
        case "arbitrum": return .arbitrum(testnet: isTestnet)
        case "dash": return .dash(testnet: isTestnet)
        case "xdai": return .gnosis
        case "ethereum-pow-iou": return .ethereumPoW(testnet: isTestnet)
        case "ethereumfair": return .ethereumFair
        case "sxdai": return .saltPay
        default: return nil
        }
    }
}

extension Blockchain {
    
    var assembly: WalletAssemblyProtocol.Type {
        switch self {
        case .bitcoin:
            return BitcoinWalletAssembly.self
        case .litecoin:
            return LitecoinWalletAssembly.self
        case .dogecoin:
            return DogecoinWalletAssembly.self
        case .ducatus:
            return DucatusWalletAssembly.self
        case .stellar:
            return StellarWalletAssembly.self
        case .ethereum, .ethereumClassic, .rsk, .bsc, .polygon, .avalanche, .fantom, .arbitrum, .gnosis, .ethereumPoW, .optimism, .ethereumFair, .saltPay:
            return EthereumWalletAssembly.self
        case .bitcoinCash:
            return BitcoinCashWalletAssembly.self
        case .binance:
            return BinanceWalletAssembly.self
        case .cardano:
            return CardanoWalletAssembly.self
        case .xrp:
            return XRPWalletAssembly.self
        case .tezos:
            return TezosWalletAssembly.self
        case .solana:
            return SolanaWalletAssembly.self
        case .polkadot:
            return PolkadotWalletAssembly.self
        case .kusama:
            return KusumaWalletAssembly.self
        case .tron:
            return TronWalletAssembly.self
        case .dash:
            return DashWalletAssembly.self
        }
    }
    
}
