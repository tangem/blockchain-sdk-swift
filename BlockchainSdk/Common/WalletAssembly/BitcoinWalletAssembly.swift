import Foundation
import TangemSdk
import stellarsdk
import BitcoinCore

struct BitcoinBlockchainAssembly: BlockchainAssemblyProtocol {
    
    func assembly(with input: BlockchainAssemblyInput) throws -> AssemblyWallet {
        return try BitcoinWalletManager(wallet: input.wallet).then {
            let network: BitcoinNetwork = input.blockchain.isTestnet ? .testnet : .mainnet
            let bitcoinManager = BitcoinManager(networkParams: network.networkParams,
                                                walletPublicKey: input.wallet.publicKey.blockchainKey,
                                                compressedWalletPublicKey: try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress(),
                                                bip: input.pairPublicKey == nil ? .bip84 : .bip141)
            
            $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: input.wallet.addresses)
            
            var providers = [AnyBitcoinNetworkProvider]()
            
            providers.append(BlockBookUtxoProvider(blockchain: input.blockchain,
                                                   blockBookConfig: NowNodesBlockBookConfig(apiKey: input.blockchainConfig.nowNodesApiKey),
                                                   networkConfiguration: input.networkConfig)
                .eraseToAnyBitcoinNetworkProvider())
            
            if !input.blockchain.isTestnet {
                providers.append(BlockBookUtxoProvider(blockchain: input.blockchain,
                                                       blockBookConfig: GetBlockBlockBookConfig(apiKey: input.blockchainConfig.getBlockApiKey),
                                                       networkConfiguration: input.networkConfig)
                    .eraseToAnyBitcoinNetworkProvider())
                
                providers.append(BlockchainInfoNetworkProvider(configuration: input.networkConfig)
                    .eraseToAnyBitcoinNetworkProvider())
            }
            
            providers.append(contentsOf: makeBlockchairNetworkProviders(for: .bitcoin(testnet: input.blockchain.isTestnet),
                                                                        configuration: input.networkConfig,
                                                                        apiKeys: input.blockchainConfig.blockchairApiKeys))
            
            providers.append(BlockcypherNetworkProvider(endpoint: .bitcoin(testnet: input.blockchain.isTestnet),
                                                        tokens: input.blockchainConfig.blockcypherTokens,
                                                        configuration: input.networkConfig)
                .eraseToAnyBitcoinNetworkProvider())
            
            $0.networkService = BitcoinNetworkService(providers: providers)
        }
    }
    
}
