//
//  OptimismWalletManager.swift
//  Alamofire
//
//  Created by Pavel Grechikhin on 01.10.2022.
//

import Foundation
import BigInt
import Combine
import TangemSdk
import Moya
import web3swift

class OptimismWalletManager: EthereumWalletManager {
    private let contractInteractor: ContractInteractor<OptimismSmartContract>
    
    init(wallet: Wallet, rpcURL: URL) {
        let contract = OptimismSmartContract(rpcURL: rpcURL)
        self.contractInteractor = ContractInteractor(contract: contract)
        
        super.init(wallet: wallet)
    }
    
    /// We are override this method to combine the two fee's layers in the `Optimistic-Ethereum` network.
    /// Read more:
    /// https://community.optimism.io/docs/developers/build/transaction-fees/#the-l1-data-fee
    /// https://help.optimism.io/hc/en-us/articles/4411895794715-How-do-transaction-fees-on-Optimism-work
    /// Short information:
    /// `L2` - Used to provide this transaction in the `Optimistic-etherium` network like a usual tx.
    /// `L1` - Used to processing a transaction in the `Etherium` network  for "safety".
    /// This L1 fee will be added to the transaction fee automatically after it is sent to the network.
    /// This L1 fee calculated the Optimism smart-contract oracle.
    /// This L1 fee have to used ONLY for showing to a user.
    /// When we're building transaction we have to used `gasLimit` and `gasPrice` ONLY from `L2`
    override func getFee(destination: String, value: String?, data: Data?) -> AnyPublisher<[Fee], Error> {
        super.getFee(destination: destination, value: value, data: data)
            .flatMap { [weak self] layer2Fee -> AnyPublisher<([Fee], Decimal), Error> in
                guard let self,
                      // We use EthereumFeeParameters without increase
                      let parameters = layer2Fee.first?.parameters as? EthereumFeeParameters else {
                    return Fail(error: BlockchainSdkError.failedToLoadFee).eraseToAnyPublisher()
                }
                
                return self.getLayer1Fee(
                    destination: destination,
                    value: value,
                    data: data,
                    l2FeeParameters: parameters
                )
                .map { (layer2Fee, $0) }
                .eraseToAnyPublisher()
            }
            .map { layer2Fee, layer1Fee -> [Fee] in
                layer2Fee.map { $0.increased(by: layer1Fee) }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension OptimismWalletManager {
    func getLayer1Fee(
        destination: String,
        value: String?,
        data: Data?,
        l2FeeParameters: EthereumFeeParameters
    ) -> AnyPublisher<Decimal, Error> {
        guard let address = EthereumAddress(destination), let value = value else {
            return Fail(error: BlockchainSdkError.failedToLoadFee).eraseToAnyPublisher()
        }

        let transaction = EthereumTransaction(
            gasPrice: l2FeeParameters.gasPrice,
            gasLimit: l2FeeParameters.gasLimit,
            to: address,
            value: BigUInt(Data(hex: value)),
            data: data ?? Data()
        )
        
        // Just collect data to get estimated fee from contact address
        // https://github.com/ethereum/wiki/wiki/RLP
        guard let rplEncodedTransactionData = transaction.encodeForSend() else {
            return Fail(error: BlockchainSdkError.failedToLoadFee).eraseToAnyPublisher()
        }
        
        let data = rplEncodedTransactionData.hexString.addHexPrefix()
        return contractInteractor
            .read(method: .getL1Fee(data: data))
            .tryMap { [wallet] response in
                guard let decimalFee = Decimal(string: "\(response)") else {
                    throw BlockchainSdkError.failedToLoadFee
                }
                
                let blockchain = wallet.blockchain
                let fee = decimalFee / blockchain.decimalValue
                
                return fee
            }
            .eraseToAnyPublisher()
    }
}
