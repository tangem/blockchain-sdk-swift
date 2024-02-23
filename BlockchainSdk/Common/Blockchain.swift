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
// This enum should be indirect because of memory issues on iOS15
public indirect enum Blockchain: Equatable, Hashable {
    case bitcoin(testnet: Bool)
    case litecoin
    case stellar(curve: EllipticCurve, testnet: Bool)
    case ethereum(testnet: Bool)
    case ethereumPoW(testnet: Bool)
    case disChain // ex-EthereumFair
    case ethereumClassic(testnet: Bool)
    case rsk
    case bitcoinCash
    case binance(testnet: Bool)
    case cardano(extended: Bool)
    case xrp(curve: EllipticCurve)
    case ducatus
    case tezos(curve: EllipticCurve)
    case dogecoin
    case bsc(testnet: Bool)
    case polygon(testnet: Bool)
    case avalanche(testnet: Bool)
    case solana(curve: EllipticCurve, testnet: Bool)
    case fantom(testnet: Bool)
    case polkadot(curve: EllipticCurve, testnet: Bool)
    case kusama(curve: EllipticCurve)
    case azero(curve: EllipticCurve, testnet: Bool)
    case tron(testnet: Bool)
    case arbitrum(testnet: Bool)
    case dash(testnet: Bool)
    case gnosis
    case optimism(testnet: Bool)
    case ton(curve: EllipticCurve, testnet: Bool)
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
    case near(curve: EllipticCurve, testnet: Bool)
    case decimal(testnet: Bool)
    case veChain(testnet: Bool)
    case xdc(testnet: Bool)
    case algorand(curve: EllipticCurve, testnet: Bool)
    case shibarium(testnet: Bool)
    case aptos(curve: EllipticCurve, testnet: Bool)
    case hedera(curve: EllipticCurve, testnet: Bool)
    case areon(testnet: Bool)
    case playa3ullGames(testnet: Bool)
    case pulsechain(testnet: Bool)
    case aurora(testnet: Bool)


    public var isTestnet: Bool {
        switch self {
        case .bitcoin(let testnet),
                .ethereum(let testnet),
                .bsc(let testnet),
                .ethereumClassic(let testnet),
                .binance(let testnet),
                .polygon(let testnet),
                .avalanche(let testnet),
                .fantom(let testnet),
                .tron(let testnet),
                .arbitrum(let testnet),
                .dash(let testnet),
                .optimism(let testnet),
                .ethereumPoW(let testnet),
                .kava(let testnet),
                .ravencoin(let testnet),
                .cosmos(let testnet),
                .telos(let testnet),
                .chia(let testnet),
                .decimal(let testnet),
                .veChain(let testnet),
                .xdc(let testnet),
                .areon(let testnet),
                .playa3ullGames(let testnet),
                .pulsechain(let testnet),
                .aurora(let testnet):
            return testnet
        case .litecoin,
                .ducatus,
                .cardano,
                .xrp,
                .rsk,
                .tezos,
                .dogecoin,
                .kusama,
                .terraV1,
                .terraV2,
                .cronos,
                .octa,
                .bitcoinCash,
                .gnosis,
                .disChain,
                .kaspa:
            return false
        case .stellar(_, let testnet),
                .hedera(_, let testnet),
                .solana(_, let testnet),
                .polkadot(_, let testnet),
                .azero(_, let testnet),
                .ton(_, let testnet),
                .near(_, let testnet),
                .algorand(_, let testnet),
                .aptos(_, let testnet),
                .shibarium(let testnet):
            return testnet
        }
    }

    public var curve: EllipticCurve {
        switch self {
        case .cardano:
            return .ed25519
        case .stellar(let curve, _),
                .solana(let curve, _),
                .polkadot(let curve, _),
                .kusama(let curve),
                .azero(let curve, _),
                .ton(let curve, _),
                .xrp(let curve),
                .tezos(let curve),
                .near(let curve, _),
                .algorand(let curve, _),
                .aptos(let curve, _),
                .hedera(let curve, _):
            return curve
        case .chia:
            return .bls12381_G2_AUG
        default:
            return .secp256k1
        }
    }

    public var decimalCount: Int {
        switch self {
        case .bitcoin,
                .litecoin,
                .bitcoinCash,
                .ducatus,
                .binance,
                .dogecoin,
                .dash,
                .kaspa,
                .ravencoin,
                .hedera:
            return 8
        case .ethereum,
                .ethereumClassic,
                .ethereumPoW,
                .disChain,
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
                .veChain,
                .xdc,
                .shibarium,
                .areon,
                .playa3ullGames,
                .pulsechain,
                .aurora:
            return 18
        case .cardano,
                .xrp,
                .tezos,
                .tron,
                .cosmos,
                .terraV1,
                .terraV2:
            return 6
        case .stellar:
            return 7
        case .solana, .ton:
            return 9
        case .polkadot(_, let testnet):
            return testnet ? 12 : 10
        case .kusama,
                .azero,
                .chia:
            return 12
        case .near:
            return 24
        case .algorand:
            return 6
        case .aptos:
            return 8
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
        case .polkadot(_, let testnet):
            return testnet ? "WND" : "DOT"
        case .kusama:
            return "KSM"
        case .azero:
            return "AZERO"
        case .tron:
            return "TRX"
        case .dash(let testnet):
            return testnet ? "tDASH" : "DASH"
        case .gnosis:
            return "xDAI"
        case .ethereumPoW:
            return "ETHW"
        case .disChain:
            return "DIS"
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
        case .chia(let testnet):
            return testnet ? "TXCH" : "XCH"
        case .near:
            return "NEAR"
        case .decimal:
            return "DEL"
        case .veChain:
            return "VET"
        case .xdc:
            return "XDC"
        case .algorand:
            return "ALGO"
        case .shibarium:
            return "BONE"
        case .aptos:
            return "APT"
        case .hedera:
            return "HBAR"
        case .areon:
            return "AREA"
        case .playa3ullGames:
            return "3ULL"
        case .pulsechain:
            return "PLS"
        case .aurora:
            return "ETH"
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
        case .disChain:
            return "DisChain (ETHF)" + testnetSuffix
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
        case .near:
            return "NEAR Protocol" + testnetSuffix
        case .decimal:
            return "Decimal Smart Chain" + testnetSuffix
        case .veChain:
            return "VeChain" + testnetSuffix
        case .xdc:
            return "XDC Network"
        case .shibarium:
            return "Shibarium" + testnetSuffix
        case .aptos:
            return "Aptos"
        case .areon:
            return "Areon Network"
        case .playa3ullGames:
            return "PLAYA3ULL GAMES"
        case .pulsechain:
            return "Pulsechain"
        case .aurora:
            return "Aurora"
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
        case .veChain: return "VIP180"
        case .xdc: return "XRC20"
        default:
            return nil
        }
    }

    public var canHandleTokens: Bool {
        switch self {
        case _ where isEvm:
            return true
        case .binance,
                .solana,
                .tron,
                .terraV1,
                .veChain:
            return true
        default:
            return false
        }
    }
    
    public var feePaidCurrency: FeePaidCurrency {
        switch self {
        case .terraV1:
            return .sameCurrency
        case .veChain:
            return .token(value: VeChainWalletManager.Constants.energyToken)
        default:
            return .coin
        }
    }

    public func isFeeApproximate(for amountType: Amount.AmountType) -> Bool {
        switch self {
        case .arbitrum,
                .stellar,
                .optimism,
                .ton,
                .near,
                .aptos,
                .hedera:
            return true
        case .fantom,
                .tron,
                .gnosis,
                .avalanche,
                .ethereumPoW,
                .cronos,
                .veChain,
                .xdc:
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

    // Only for Ethereum compatible blockchains
    // https://chainlist.org
    public var chainId: Int? {
        switch self {
        case .ethereum: return isTestnet ? 5 : 1
        case .ethereumClassic: return isTestnet ? 6 : 61 // https://besu.hyperledger.org/en/stable/Concepts/NetworkID-And-ChainID/
        case .ethereumPoW: return isTestnet ? 10002 : 10001
        case .disChain: return 513100
        case .rsk: return 30
        case .bsc: return isTestnet ? 97 : 56
        case .polygon: return isTestnet ? 80001 : 137
        case .avalanche: return isTestnet ? 43113 : 43114
        case .fantom: return isTestnet ? 4002 : 250
        case .arbitrum: return isTestnet ? 421613 : 42161
        case .gnosis: return 100
        case .optimism: return isTestnet ? 420 : 10
        case .kava: return isTestnet ? 2221 : 2222
        case .cronos: return 25
        case .telos: return isTestnet ? 41 : 40
        case .octa: return isTestnet ? 800002 : 800001
        case .decimal: return isTestnet ? 202020 : 75
        case .xdc: return isTestnet ? 51 : 50
        case .shibarium: return isTestnet ? 157 : 109
        case .areon: return isTestnet ? 463 : 462
        case .playa3ullGames: return 3011
        case .pulsechain: return isTestnet ? 943 : 369
        case .aurora: return isTestnet ? 1313161555 : 1313161554
        default: return nil
        }
    }

    //Only for Ethereum compatible blockchains
    public func getJsonRpcEndpoints(keys: EthereumApiKeys) -> [URL]? {
        let infuraProjectId = keys.infuraProjectId
        let nowNodesApiKey = keys.nowNodesApiKey
        let getBlockApiKeys = keys.getBlockApiKeys
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
                    URL(string: "https://eth.nownodes.io/\(nowNodesApiKey)")!,
                    makeGetBlockJsonRpcProvider(),
                    URL(string: "https://mainnet.infura.io/v3/\(infuraProjectId)")!,
                ]
            }
        case .ethereumClassic:
            if isTestnet {
                return [
                    URL(string: "https://rpc.mordor.etccooperative.org")!,
                ]
            } else {
                return [
                    makeGetBlockJsonRpcProvider(),
                    URL(string: "https://etc.etcdesktop.com")!,
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
        case .disChain:
            return [
                URL(string: "https://rpc.dischain.xyz")!,
            ]
        case .rsk:
            return [
                URL(string: "https://public-node.rsk.co/")!,
                URL(string: "https://rsk.nownodes.io/\(nowNodesApiKey)")!,
                makeGetBlockJsonRpcProvider(),
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
                    makeGetBlockJsonRpcProvider(),
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
                    makeGetBlockJsonRpcProvider(),
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
                var rpcEndpoits: [URL] = [
                    URL(string: "https://api.avax.network/ext/bc/C/rpc")!,
                    URL(string: "https://avax.nownodes.io/\(nowNodesApiKey)/ext/bc/C/rpc")!,
                ]

                if let jsonRpcKey = getBlockApiKeys[self] {
                    rpcEndpoits.append(URL(string: "https://go.getblock.io/\(jsonRpcKey)/ext/bc/C/rpc")!)
                }

                return rpcEndpoits
            }
        case .fantom:
            if isTestnet {
                return [
                    URL(string: "https://rpc.testnet.fantom.network/")!,
                ]
            } else {
                return [
                    URL(string: "https://ftm.nownodes.io/\(nowNodesApiKey)")!,
                    makeGetBlockJsonRpcProvider(),
                    URL(string: "https://rpc.ftm.tools/")!,
                    URL(string: "https://rpcapi.fantom.network/")!,
                    URL(string: "https://fantom-mainnet.public.blastapi.io")!,
                    URL(string: "https://fantom-pokt.nodies.app")!,
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
                    URL(string: "https://arbitrum.nownodes.io/\(nowNodesApiKey)")!,
                    URL(string: "https://arbitrum-mainnet.infura.io/v3/\(infuraProjectId)")!,
                ]
            }
        case .gnosis:
            return [
                makeGetBlockJsonRpcProvider(),

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
                makeGetBlockJsonRpcProvider(),
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
        case .decimal(let isTestnet):
            if isTestnet {
                return [
                    URL(string: "https://testnet-val.decimalchain.com/web3/")!
                ]
            } else {
                return [
                    URL(string: "https://node.decimalchain.com/web3/")!,
                    URL(string: "https://node1-mainnet.decimalchain.com/web3/")!,
                    URL(string: "https://node2-mainnet.decimalchain.com/web3/")!,
                    URL(string: "https://node3-mainnet.decimalchain.com/web3/")!,
                    URL(string: "https://node4-mainnet.decimalchain.com/web3/")!,
                ]
            }
        case .xdc(let isTestnet):
            if isTestnet {
                return [
                    URL(string: "https://rpc.apothem.network/")!
                ]
            } else {
                return [
                    URL(string: "https://xdc.nownodes.io/\(nowNodesApiKey)")!,
                    URL(string: "https://rpc.xdcrpc.com")!,
                    URL(string: "https://erpc.xdcrpc.com")!,
                    URL(string: "https://rpc.xinfin.network")!,
                    URL(string: "https://erpc.xinfin.network")!,
                    URL(string: "https://rpc.xdc.org")!,
                    URL(string: "https://rpc.ankr.com/xdc")!,
                    URL(string: "https://rpc1.xinfin.network")!,
                ]
            }
        case .shibarium(let isTestnet):
            if isTestnet {
                return [
                    URL(string: "https://puppynet.shibrpc.com/")!
                ]
            } else {
                return [
                    URL(string: "https://www.shibrpc.com/")!,
                    URL(string: "https://shib.nownodes.io/\(nowNodesApiKey)")!
                ]
            }
        case .areon:
            if isTestnet {
                return [
                    URL(string: "https://testnet-rpc.areon.network/")!,
                    URL(string: "https://testnet-rpc2.areon.network/")!,
                    URL(string: "https://testnet-rpc3.areon.network/")!,
                    URL(string: "https://testnet-rpc4.areon.network/")!,
                    URL(string: "https://testnet-rpc5.areon.network/")!,
                ]
            } else {
                return [
                    URL(string: "https://mainnet-rpc.areon.network/")!,
                    URL(string: "https://mainnet-rpc2.areon.network/")!,
                    URL(string: "https://mainnet-rpc3.areon.network/")!,
                    URL(string: "https://mainnet-rpc4.areon.network/")!,
                    URL(string: "https://mainnet-rpc5.areon.network/")!,
                ]
            }
        case .playa3ullGames:
            return [
                URL(string: "https://api.mainnet.playa3ull.games/")!,
            ]
        case .pulsechain:
            if isTestnet {
                return [
                    URL(string: "https://rpc.v4.testnet.pulsechain.com/")!,
                    URL(string: "https://pulsechain-testnet.publicnode.com/")!,
                    URL(string: "https://rpc-testnet-pulsechain.g4mm4.io/")!,
                ]
            } else {
                return [
                    URL(string: "https://rpc.pulsechain.com/")!,
                    URL(string: "https://pulsechain.publicnode.com/")!,
                    URL(string: "https://rpc-pulsechain.g4mm4.io/")!,
                ]
            }
        case .aurora:
            if isTestnet {
                return [
                    URL(string: "https://testnet.aurora.dev/")!,
                ]
            } else {
                return [
                    URL(string: "https://mainnet.aurora.dev/")!,
                    URL(string: "https://aurora.drpc.org/")!,
                    URL(string: "https://1rpc.io/aurora/")!,
                ]
            }
        default:
            return nil
        }

        // MARK: - Private Implementation

        func makeGetBlockJsonRpcProvider() -> URL {
            if let jsonRpcKey = getBlockApiKeys[self] {
                return URL(string: "https://go.getblock.io/\(jsonRpcKey)")!
            } else {
                assertionFailure("getJsonRpcEndpoints -> Not found GetBlock jsonRpc key for blockchain \(displayName)")
                Log.network("Not found jsonRpc key GetBlock API for blockchaib \(displayName)")
                return URL(string: "https://go.getblock.io/")!
            }
        }
    }
}

// MARK: - Address creation
@available(iOS 13.0, *)
extension Blockchain {
    public func derivationPath(for style: DerivationStyle) -> DerivationPath? {
        guard curve.supportsDerivation else {
            Log.debug("Wrong attempt to get a `DerivationPath` for a unsupported derivation curve")
            return nil
        }

        if isTestnet {
            return BIP44(coinType: 1).buildPath()
        }

        return style.provider.derivationPath(for: self)
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
        case .disChain: return "ethereumfair" // keep existing key for compatibility
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
        case .near: return "near"
        case .decimal: return "decimal"
        case .veChain: return "vechain"
        case .xdc: return "xdc"
        case .algorand: return "algorand"
        case .shibarium: return "shibarium"
        case .aptos: return "aptos"
        case .hedera: return "hedera"
        case .areon: return "areon"
        case .playa3ullGames: return "playa3ull"
        case .pulsechain: return "pls"
        case .aurora: return "aurora"
        }
    }

    enum Keys: CodingKey {
        case key
        case testnet
        case curve
        case extended
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
        case "stellar": self = .stellar(curve: curve, testnet: isTestnet)
        case "ethereum": self = .ethereum(testnet: isTestnet)
        case "ethereumClassic": self = .ethereumClassic(testnet: isTestnet)
        case "litecoin": self = .litecoin
        case "rsk": self = .rsk
        case "bitcoinCash": self = .bitcoinCash
        case "binance": self = .binance(testnet: isTestnet)
        case "cardano":
            let extended = try container.decodeIfPresent(Bool.self, forKey: Keys.extended)
            self = .cardano(extended: extended ?? false)
        case "xrp": self = .xrp(curve: curve)
        case "ducatus": self = .ducatus
        case "tezos": self = .tezos(curve: curve)
        case "dogecoin": self = .dogecoin
        case "bsc": self = .bsc(testnet: isTestnet)
        case "polygon", "matic": self = .polygon(testnet: isTestnet)
        case "avalanche": self = .avalanche(testnet: isTestnet)
        case "solana": self = .solana(curve: curve, testnet: isTestnet)
        case "fantom": self = .fantom(testnet: isTestnet)
        case "polkadot": self = .polkadot(curve: curve, testnet: isTestnet)
        case "kusama": self = .kusama(curve: curve)
        case "aleph-zero": self = .azero(curve: curve, testnet: isTestnet)
        case "tron": self = .tron(testnet: isTestnet)
        case "arbitrum": self = .arbitrum(testnet: isTestnet)
        case "dash": self = .dash(testnet: isTestnet)
        case "xdai": self = .gnosis
        case "optimism": self = .optimism(testnet: isTestnet)
        case "ethereum-pow-iou": self = .ethereumPoW(testnet: isTestnet)
        case "ethereumfair", "dischain": self = .disChain
        case "ton": self = .ton(curve: curve, testnet: isTestnet)
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
        case "near": self = .near(curve: curve, testnet: isTestnet)
        case "decimal": self = .decimal(testnet: isTestnet)
        case "vechain": self = .veChain(testnet: isTestnet)
        case "xdc": self = .xdc(testnet: isTestnet)
        case "algorand": self = .algorand(curve: curve, testnet: isTestnet)
        case "shibarium": self = .shibarium(testnet: isTestnet)
        case "aptos": self = .aptos(curve: curve, testnet: isTestnet)
        case "hedera": self = .hedera(curve: curve, testnet: isTestnet)
        case "areon": self = .areon(testnet: isTestnet)
        case "playa3ull": self = .playa3ullGames(testnet: isTestnet)
        case "pls": self = .pulsechain(testnet: isTestnet)
        case "aurora": self = .aurora(testnet: isTestnet)
        default:
            throw BlockchainSdkError.decodingFailed
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(codingKey, forKey: Keys.key)
        try container.encode(curve.rawValue, forKey: Keys.curve)
        try container.encode(isTestnet, forKey: Keys.testnet)

        if case .cardano(let extended) = self {
            try container.encode(extended, forKey: Keys.extended)
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
        case "xlm", "asset", "xlm-tag": return .stellar(curve: curve, testnet: isTestnet)
        case "eth", "token", "nfttoken": return .ethereum(testnet: isTestnet)
        case "ltc": return .litecoin
        case "rsk", "rsktoken": return .rsk
        case "bch": return .bitcoinCash
        case "binance", "binanceasset": return .binance(testnet: isTestnet)
            // For old cards cardano will work like ed25519_slip0010
        case "cardano", "cardano-s": return .cardano(extended: false)
        case "xrp": return .xrp(curve: curve)
        case "duc": return .ducatus
        case "xtz": return .tezos(curve: curve)
        case "doge": return .dogecoin
        case "bsc": return .bsc(testnet: isTestnet)
        case "polygon": return .polygon(testnet: isTestnet)
        case "avalanche": return .avalanche(testnet: isTestnet)
        case "solana": return .solana(curve: curve, testnet: isTestnet)
        case "fantom": return .fantom(testnet: isTestnet)
        case "polkadot": return .polkadot(curve: curve, testnet: isTestnet)
        case "kusama": return .kusama(curve: curve)
        case "aleph-zero": return .azero(curve: curve, testnet: isTestnet)
        case "tron": return .tron(testnet: isTestnet)
        case "arbitrum": return .arbitrum(testnet: isTestnet)
        case "dash": return .dash(testnet: isTestnet)
        case "xdai": return .gnosis
        case "ethereum-pow-iou": return .ethereumPoW(testnet: isTestnet)
        case "ethereumfair", "dischain": return .disChain
        case "ton": return .ton(curve: curve, testnet: isTestnet)
        case "terra": return .terraV1
        case "terra-2": return .terraV2
        case "cronos": return .cronos
        case "octaspace": return .octa
        case "chia": return .chia(testnet: isTestnet)
        case "near": return .near(curve: curve, testnet: isTestnet)
        case "decimal": return .decimal(testnet: isTestnet)
        case "vechain": return .veChain(testnet: isTestnet)
        case "xdc": return .xdc(testnet: isTestnet)
        case "algorand": return .algorand(curve: curve, testnet: isTestnet)
        case "shibarium": return .shibarium(testnet: isTestnet)
        case "aptos": return .aptos(curve: curve, testnet: isTestnet)
        case "hedera": return .hedera(curve: curve, testnet: isTestnet)
        default: return nil
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
        case .ethereum,
                .ethereumClassic,
                .rsk,
                .bsc,
                .polygon,
                .avalanche,
                .fantom,
                .arbitrum,
                .gnosis,
                .ethereumPoW,
                .disChain,
                .kava,
                .cronos,
                .octa,
                .shibarium,
                .areon,
                .playa3ullGames,
                .pulsechain,
                .aurora:
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
        case .near:
            return NEARWalletAssembly()
        case .telos:
            return TelosWalletAssembly()
        case .decimal:
            return DecimalWalletAssembly()
        case .veChain:
            return VeChainWalletAssembly()
        case .xdc:
            return XDCWalletAssembly()
        case .algorand:
            return AlgorandWalletAssembly()
        case .aptos:
            return AptosWalletAssembly()
        case .hedera:
            return HederaWalletAssembly()
        }
    }
}
