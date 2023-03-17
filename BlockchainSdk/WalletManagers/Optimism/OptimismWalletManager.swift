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

    /// We are override this method to combine the two fee layers in the `Optimistic-Ethereum` network.
    /// Read more:
    /// https://community.optimism.io/docs/developers/build/transaction-fees/#the-l1-data-fee
    /// https://help.optimism.io/hc/en-us/articles/4411895794715-How-do-transaction-fees-on-Optimism-work
    /// Short information:
    /// `L1` - Used to processing a transaction in the `optimistic-etherium` network.
    /// It will be added to fee in the transaction after sent it in the network. We don't have to use any sum `L1` and `L2` fees when we're building transaction.
    /// But it's important to show user information about a fee which will be charged
    /// `L2` - Used to provide this transaction in the `Etherium` network for "safety".
    /// When we are building transaction we have to use `gasLimit` and `gasPrice` ONLY from L2
    override func getFee(destination: String, value: String?, data: Data?) -> AnyPublisher<FeeType, Error> {
        super.getFee(destination: destination, value: value, data: data)
            .tryMap { [weak self] layer2FeeType -> AnyPublisher<(FeeType, Decimal), Error> in
                guard let self,
                      let parameters = layer2FeeType.lowFeeModel?.parameters as? EthereumFeeParameters else {
                    return Fail(error: BlockchainSdkError.failedToLoadFee).eraseToAnyPublisher()
                }

                return self.getLayer1Fee(destination: destination, value: value, data: data, l2FeeParameters: parameters)
                    .map { (layer2FeeType, $0) }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .tryMap { layer2FeeType, layer1Fee -> FeeType in
                switch layer2FeeType {
                case .multiple(let low, let normal, let priority):
                    let updatedModels: [FeeType.FeeModel] = [low, normal, priority].map { feeModel in
                        let newAmount = Amount(with: feeModel.fee, value: feeModel.fee.value + layer1Fee)
                        let newFeeModel = FeeType.FeeModel(newAmount, parameters: feeModel.parameters)
                        return newFeeModel
                    }
                    let feeType = try FeeType(fees: updatedModels)
                    print("OptimismWalletManager calculated fees: \(feeType)")
                    
                    return feeType
                case .single:
                    assertionFailure("Not implement this case")
                    return layer2FeeType
                }
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
        assert(value != nil)
        
        guard let address = EthereumAddress(destination), let value = value else {
            return Fail(error: BlockchainSdkError.failedToLoadFee).eraseToAnyPublisher()
        }

        let encodedValue = BigUInt(Data(hex: value))
        let transaction = EthereumTransaction(
            gasPrice: l2FeeParameters.gasPrice,
            gasLimit: l2FeeParameters.gasLimit,
            to: address,
            value: encodedValue,
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
