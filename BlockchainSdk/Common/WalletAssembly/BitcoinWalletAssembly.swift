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
            
            var providers = [AnyBitcoinNetworkProvider]()
            
            if !input.blockchain.isTestnet {
                providers.append(
                    networkProviderAssembly.makeBlockchainInfoNetworkProvider(with: input).eraseToAnyBitcoinNetworkProvider()
                )
            }
            
            providers.append(
                networkProviderAssembly.makeBlockBookUtxoProvider(with: input, for: .nowNodes).eraseToAnyBitcoinNetworkProvider()
            )
            
            if !input.blockchain.isTestnet {
                providers.append(
                    networkProviderAssembly.makeBlockBookUtxoProvider(with: input, for: .getBlock).eraseToAnyBitcoinNetworkProvider()
                )
            }
            
            providers.append(
                contentsOf: networkProviderAssembly.makeBlockchairNetworkProviders(
                    endpoint: .bitcoin(testnet: input.blockchain.isTestnet),
                    with: input
                )
            )
            
            providers.append(
                networkProviderAssembly.makeBlockcypherNetworkProvider(
                    endpoint: .bitcoin(testnet: input.blockchain.isTestnet),
                    with: input
                ).eraseToAnyBitcoinNetworkProvider()
            )
            
            $0.networkService = BitcoinNetworkService(providers: providers)
        }
    }
    
}
