import Foundation
import TangemSdk
import stellarsdk
import BitcoinCore

struct BitcoinWalletAssembly: WalletManagerAssembly {
    
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return try BitcoinWalletManager(wallet: input.wallet).then {
            let network: BitcoinNetwork = input.blockchain.isTestnet ? .testnet : .mainnet
            let bitcoinManager = BitcoinManager(
                networkParams: network.networkParams,
                walletPublicKey: input.wallet.publicKey.blockchainKey,
                compressedWalletPublicKey: try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress(),
                bip: input.pairPublicKey == nil ? .bip84 : .bip141
            )
            
            $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: input.wallet.addresses)
            
            let apiInfo = input.apiInfo
            var newProviders = [AnyBitcoinNetworkProvider]()
            apiInfo.forEach {
                guard
                    $0.type == .private,
                    let provider = $0.provider,
                    let api = API(rawValue: provider)
                else {
                    return
                }

                switch api {
                case .nownodes:
                    newProviders.append(networkProviderAssembly.makeBlockBookUtxoProvider(with: input, for: .nowNodes).eraseToAnyBitcoinNetworkProvider())
                case .getblock:
                    if input.blockchain.isTestnet {
                        break
                    }

                    newProviders.append(networkProviderAssembly.makeBlockBookUtxoProvider(with: input, for: .getBlock).eraseToAnyBitcoinNetworkProvider())
                case .blockchair:
                    newProviders.append(
                        contentsOf: networkProviderAssembly.makeBlockchairNetworkProviders(
                            endpoint: .bitcoin(testnet: input.blockchain.isTestnet),
                            with: input
                        )
                    )
                case .blockcypher:
                    newProviders.append(
                        networkProviderAssembly.makeBlockcypherNetworkProvider(
                            endpoint: .bitcoin(testnet: input.blockchain.isTestnet),
                            with: input
                        ).eraseToAnyBitcoinNetworkProvider()
                    )
                default:
                    break
                }
            }
            
            $0.networkService = BitcoinNetworkService(providers: newProviders)
        }
    }
    
}
