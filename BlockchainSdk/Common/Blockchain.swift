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
import enum WalletCore.CoinType

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
    case cardano
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
    case azero(testnet: Bool)
    case tron(testnet: Bool)
    case arbitrum(testnet: Bool)
    case dash(testnet: Bool)
    case gnosis
    case optimism(testnet: Bool)
    case saltPay
    case ton(testnet: Bool)
    case kava(testnet: Bool)
    case kaspa
    case ravencoin(testnet: Bool)
    case cosmos(testnet: Bool)
    case terraV1
    case terraV2
    case cronos
    case telos(testnet: Bool)
    case octa
    case chia(testnet: Bool)
    
    public var isTestnet: Bool {
        switch self {
        case .bitcoin(let testnet):
            return testnet
        case .litecoin, .ducatus, .cardano, .xrp, .rsk, .tezos, .dogecoin, .kusama, .terraV1, .terraV2, .cronos, .octa:
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
        case .azero(let testnet):
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
        case .ton(let testnet):
            return testnet
        case .kava(let testnet):
            return testnet
        case .kaspa:
            return false
        case .ravencoin(let testnet):
            return testnet
        case .cosmos(let testnet):
            return testnet
        case .telos(let testnet):
            return testnet
        case .chia(let testnet):
            return testnet
        }
    }
    
    public var curve: EllipticCurve {
        switch self {
        case .stellar, .cardano, .solana, .polkadot, .kusama, .azero, .ton:
            return .ed25519
        case .xrp(let curve):
            return curve
        case .tezos(let curve):
            return curve
        case .chia:
            return .bls12381_G2_AUG
        default:
            return .secp256k1
        }
    }
    
    public var decimalCount: Int {
        switch self {
        case .bitcoin, .litecoin, .bitcoinCash, .ducatus, .binance, .dogecoin, .dash, .kaspa, .ravencoin:
            return 8
        case .ethereum, .ethereumClassic, .ethereumPoW, .ethereumFair, .rsk, .bsc, .polygon, .avalanche, .fantom, .arbitrum, .gnosis, .optimism, .saltPay, .kava, .cronos, .telos, .octa:
            return 18
        case  .cardano, .xrp, .tezos, .tron, .cosmos, .terraV1, .terraV2:
            return 6
        case .stellar:
            return 7
        case .solana, .ton:
            return 9
        case .polkadot(let testnet):
            return testnet ? 12 : 10
        case .kusama, .azero, .chia:
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
        case .azero:
            return "AZERO"
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
        case .ton:
            return "TON"
        case .kava:
            return "KAVA"
        case .kaspa:
            return "KAS"
        case .ravencoin:
            return "RVN"
        case .cosmos:
            return "ATOM"
        case .terraV1:
            return "LUNC"
        case .terraV2:
            return "LUNA"
        case .cronos:
            return "CRO"
        case .telos:
            return "TLOS"
        case .octa:
            return "OCTA"
        case .chia:
            return "XCH"
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
        case .azero:
            return "Aleph Zero" + testnetSuffix
        case .gnosis:
            return "Gnosis Chain" + testnetSuffix
        case .optimism:
            return "Optimistic Ethereum" + testnetSuffix
        case .saltPay:
            return "Salt Pay"
        case .kava:
            return "Kava EVM"
        case .terraV1:
            return "Terra Classic"
        case .terraV2:
            return "Terra"
        case .octa:
            return "OctaSpace"
        case .chia:
            return "Chia Network"
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
        case .ton: return "TON"
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
        case .arbitrum, .stellar, .optimism, .ton:
            return true
        case .fantom, .tron, .gnosis, .avalanche, .ethereumPoW, .cronos:
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
        case .kava: return isTestnet ? 2221 : 2222
        case .cronos: return 25
        case .telos: return isTestnet ? 41 : 40
        case .octa: return isTestnet ? 800002 : 800001
        default: return nil
        }
    }
    
    //Only for Ethereum compatible blockchains
    public func getJsonRpcEndpoints(keys: EthereumApiKeys) -> [URL]? {
        let infuraProjectId = keys.infuraProjectId
        let nowNodesApiKey = keys.nowNodesApiKey
        let getBlockApiKey = keys.getBlockApiKey
        let quickNodeBscCredentials = keys.quickNodeBscCredentials
        
        switch self {
        case .ethereum:
            if isTestnet {
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
            if isTestnet {
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
            if isTestnet {
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
            if isTestnet {
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
            if isTestnet {
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
            if isTestnet {
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
            if isTestnet {
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
            if isTestnet {
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
            if isTestnet {
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

// MARK: - Address creation
@available(iOS 13.0, *)
extension Blockchain {
    public func derivationPath(for style: DerivationStyle) -> DerivationPath? {
        guard curve == .secp256k1 || curve == .ed25519 else {
            Log.debug("Wrong attempt to get a `DerivationPath` for a unsupported derivation curve")
            return nil
        }
        
        if isTestnet {
            return BIP44(coinType: 1).buildPath()
        }

        return style.provider.derivationPath(for: self)
    }

    @available(*, deprecated, message: "Use AddressServiceFactory(blockchain:).validate(_:)")
    public func validate(address: String) -> Bool {
        AddressServiceFactory(blockchain: self).makeAddressService().validate(address)
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
        case .azero: return "aleph-zero"
        case .tron: return "tron"
        case .arbitrum: return "arbitrum"
        case .dash: return "dash"
        case .gnosis: return "xdai"
        case .optimism: return "optimism"
        case .ethereumPoW: return "ethereum-pow-iou"
        case .ethereumFair: return "ethereumfair"
        case .saltPay: return "sxdai"
        case .ton: return "ton"
        case .kava: return "kava"
        case .kaspa: return "kaspa"
        case .ravencoin: return "ravencoin"
        case .cosmos: return "cosmos-hub"
        case .terraV1: return "terra"
        case .terraV2: return "terra-2"
        case .cronos: return "cronos"
        case .telos: return "telos"
        case .octa: return "octaspace"
        case .chia: return "chia"
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
        case "cardano": self = .cardano
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
        case "aleph-zero": self = .azero(testnet: isTestnet)
        case "tron": self = .tron(testnet: isTestnet)
        case "arbitrum": self = .arbitrum(testnet: isTestnet)
        case "dash": self = .dash(testnet: isTestnet)
        case "xdai": self = .gnosis
        case "optimism": self = .optimism(testnet: isTestnet)
        case "ethereum-pow-iou": self = .ethereumPoW(testnet: isTestnet)
        case "ethereumfair": self = .ethereumFair
        case "sxdai": self = .saltPay
        case "ton": self = .ton(testnet: isTestnet)
        case "kava": self = .kava(testnet: isTestnet)
        case "kaspa": self = .kaspa
        case "ravencoin": self = .ravencoin(testnet: isTestnet)
        case "cosmos-hub": self = .cosmos(testnet: isTestnet)
        case "terra": self = .terraV1
        case "terra-2": self = .terraV2
        case "cronos": self = .cronos
        case "telos": self = .telos(testnet: isTestnet)
        case "octaspace": self = .octa
        case "chia": self = .chia(testnet: isTestnet)
        default:
            throw BlockchainSdkError.decodingFailed
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(codingKey, forKey: Keys.key)
        try container.encode(curve.rawValue, forKey: Keys.curve)
        try container.encode(isTestnet, forKey: Keys.testnet)
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
        case .azero:
            return URL(string: "https://faucet.test.azero.dev")
        case .tron:
            return URL(string: "https://nileex.io/join/getJoinPage")!
        case .dash:
            return URL(string: "http://faucet.test.dash.crowdnode.io/")!
            // Or another one https://testnet-faucet.dash.org/ - by Dash Core Group
        case .optimism:
            return URL(string: "https://optimismfaucet.xyz")! //another one https://faucet.paradigm.xyz
        case .kava:
            return URL(string: "https://faucet.kava.io")!
        case .kaspa:
            return URL(string: "https://faucet.kaspanet.io")!
        case .cosmos:
            return URL(string: "https://discord.com/channels/669268347736686612/953697793476821092")!
        case .telos:
            return URL(string: "https://app.telos.net/testnet/developers")
        case .chia:
            return URL(string: "https://xchdev.com/#!faucet.md")!
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
            let baseUrl = isTestnet ? "https://goerli.etherscan.io/" : "https://etherscan.io/"
            let exploreLink = tokenContractAddress == nil ?
                baseUrl + "address/" + address :
                baseUrl + "token/" + "\(tokenContractAddress!)?a=\(address)"
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
            let baseUrl = isTestnet ? "https://testnet.bscscan.com/" : "https://bscscan.com/"
            let exploreLink = tokenContractAddress == nil ?
                baseUrl + "address/" + address :
                baseUrl + "token/" + "\(tokenContractAddress!)?a=\(address)"
            return URL(string: exploreLink)
        case .polygon:
            let baseUrl = isTestnet ? "https://explorer-mumbai.maticvigil.com/" : "https://polygonscan.com/"
            let exploreLink = tokenContractAddress == nil ?
                baseUrl + "address/" + address :
                baseUrl + "token/" + "\(tokenContractAddress!)?a=\(address)"
            return URL(string: exploreLink)
        case .avalanche:
            let baseUrl = isTestnet ? "https://testnet.snowtrace.io/" : "https://snowtrace.io/"
            let exploreLink = tokenContractAddress == nil ?
                baseUrl + "address/" + address :
                baseUrl + "token/" + "\(tokenContractAddress!)?a=\(address)"
            return URL(string: exploreLink)
        case .solana:
            let baseUrl = "https://explorer.solana.com/address/"
            let cluster = isTestnet ? "?cluster=devnet" : ""
            
            var exploreLink = baseUrl + address + cluster
            
            if tokenContractAddress != nil {
                exploreLink += "/tokens"
            }
            
            return URL(string: exploreLink)
        case .fantom:
            let baseUrl = isTestnet ? "https://testnet.ftmscan.com/" : "https://ftmscan.com/"
            let exploreLink = tokenContractAddress == nil ?
                baseUrl + "address/" + address :
                baseUrl + "token/" + "\(tokenContractAddress!)?a=\(address)"
            return URL(string: exploreLink)
        case .polkadot:
            let subdomain = isTestnet ? "westend" : "polkadot"
            return URL(string: "https://\(subdomain).subscan.io/account/\(address)")
        case .kusama:
            return URL(string: "https://kusama.subscan.io/account/\(address)")
        case .azero:
            guard !isTestnet else { return nil } // So far only available for mainnet
            return URL(string: "https://alephzero.subscan.io/account/\(address)")
        case .tron:
            let subdomain = isTestnet ? "nile." : ""
            return URL(string: "https://\(subdomain)tronscan.org/#/address/\(address)")!
        case .arbitrum:
            let baseUrl: String
            
            if isTestnet {
                baseUrl = "https://goerli-rollup-explorer.arbitrum.io/"
            } else {
                baseUrl = "https://arbiscan.io/"
            }
            
            let exploreLink = tokenContractAddress == nil ?
                baseUrl + "address/" + address :
                baseUrl + "token/" + "\(tokenContractAddress!)?a=\(address)"
            
            return URL(string: exploreLink)
        case .dash:
            let network = isTestnet ? "testnet" : "mainnet"
            return URL(string: "https://blockexplorer.one/dash/\(network)/address/\(address)")
        case .gnosis:
            return URL(string: "https://blockscout.com/xdai/mainnet/address/\(address)")!
        case .optimism:
            let baseUrl: String
            
            if isTestnet {
                baseUrl = "https://blockscout.com/optimism/goerli/"
            } else {
                baseUrl = "https://optimistic.etherscan.io/"
            }
            
            let exploreLink = tokenContractAddress == nil ?
                baseUrl + "address/" + address :
                baseUrl + "token/" + "\(tokenContractAddress!)?a=\(address)"
            
            return URL(string: exploreLink)
        case .saltPay:
            return URL(string: "https://blockscout.bicoccachain.net/address/\(address)")!
        case .ton:
            let subdomain = isTestnet ? "testnet." : ""
            return URL(string: "https://\(subdomain)tonscan.org/address/\(address)")
        case .kava:
            if isTestnet {
                return URL(string: "https://explorer.testnet.kava.io/address/\(address)")
            }

            return URL(string: "https://explorer.kava.io/address/\(address)")
        case .kaspa:
            return URL(string: "https://explorer.kaspa.org/addresses/\(address)")!
        case .ravencoin:
              if isTestnet {
                  return URL(string: "https://testnet.ravencoin.network/address/\(address)")
              }

              return URL(string: "https://api.ravencoin.org/address/\(address)")
        case .cosmos(let testnet):
            if testnet {
                return URL(string: "https://explorer.theta-testnet.polypore.xyz/accounts/\(address)")!
            } else {
                return URL(string: "https://www.mintscan.io/cosmos/account/\(address)")!
            }
        case .terraV1:
            return URL(string: "https://finder.terra.money/classic/address/\(address)")!
        case .terraV2:
            return URL(string: "https://terrasco.pe/mainnet/address/\(address)")!
        case .cronos:
            return URL(string: "https://cronoscan.com/address/\(address)")!
        case .telos:
            if isTestnet {
                return URL(string: "https://testnet.teloscan.io/address/\(address)")!
            } else {
                return URL(string: "https://teloscan.io/address/\(address)")!
            }
        case .octa:
            return URL(string: "https://explorer.octa.space/address/\(address)")!
        case .chia(let testnet):
            if testnet {
                return URL(string: "https://testnet10.spacescan.io/")!
            } else {
                return URL(string: "https://xchscan.com/")!
            }
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
        case "cardano", "cardano-s": return .cardano
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
        case "aleph-zero": return .azero(testnet: isTestnet)
        case "tron": return .tron(testnet: isTestnet)
        case "arbitrum": return .arbitrum(testnet: isTestnet)
        case "dash": return .dash(testnet: isTestnet)
        case "xdai": return .gnosis
        case "ethereum-pow-iou": return .ethereumPoW(testnet: isTestnet)
        case "ethereumfair": return .ethereumFair
        case "sxdai": return .saltPay
        case "ton": return .ton(testnet: isTestnet)
        case "terra": return .terraV1
        case "terra-2": return .terraV2
        case "cronos": return .cronos
        case "octaspace": return .octa
        default: return nil
        }
    }
}

// MARK: - Transaction history

extension Blockchain {
    public var canLoadTransactionHistory: Bool {
        switch self {
        case .saltPay:
            return true
        default:
            return false
        }
    }
}

// MARK: - Token transaction fee currency

extension Blockchain {
    // Some networks (Terra specifically) allow the fees to be paid in tokens themselves when transacting tokens
    public var tokenTransactionFeePaidInNetworkCurrency: Bool {
        switch self {
        case .terraV1:
            return false
        default:
            return true
        }
    }
}

// MARK: - Assembly type

@available(iOS 13.0, *)
extension Blockchain {
    
    var assembly: WalletManagerAssembly {
        switch self {
        case .bitcoin:
            return BitcoinWalletAssembly()
        case .litecoin:
            return LitecoinWalletAssembly()
        case .dogecoin:
            return DogecoinWalletAssembly()
        case .ducatus:
            return DucatusWalletAssembly()
        case .stellar:
            return StellarWalletAssembly()
        case .ethereum, .ethereumClassic, .rsk, .bsc, .polygon, .avalanche, .fantom, .arbitrum, .gnosis, .ethereumPoW, .ethereumFair, .saltPay, .kava, .cronos, .telos, .octa:
            return EthereumWalletAssembly()
        case .optimism:
            return OptimismWalletAssembly()
        case .bitcoinCash:
            return BitcoinCashWalletAssembly()
        case .binance:
            return BinanceWalletAssembly()
        case .cardano:
            return CardanoWalletAssembly()
        case .xrp:
            return XRPWalletAssembly()
        case .tezos:
            return TezosWalletAssembly()
        case .solana:
            return SolanaWalletAssembly()
        case .polkadot, .kusama, .azero:
            return SubstrateWalletAssembly()
        case .tron:
            return TronWalletAssembly()
        case .dash:
            return DashWalletAssembly()
        case .ton:
            return TONWalletAssembly()
        case .kaspa:
            return KaspaWalletAssembly()
        case .ravencoin:
            return RavencoinWalletAssembly()
        case .cosmos, .terraV1, .terraV2:
            return CosmosWalletAssembly()
        case .chia:
            return ChiaWalletAssembly()
        }
    }
    
}
