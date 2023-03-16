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
    private let contractInteractor: ContractInteractor<OptimismContract>
    
    init(wallet: Wallet, rpcURL: URL) {
        let contract = OptimismContract(rpcURL: rpcURL)
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
    override func getFee(payload: TransactionDestinationPayload) -> AnyPublisher<FeeDataModel, Error> {
        super.getFee(payload: payload)
            .tryMap { [weak self] layer2FeeDataModel -> AnyPublisher<FeeDataModel, Error> in
                guard let self, let parameters = layer2FeeDataModel.additionalParameters as? EthereumFeeParameters else {
                    return Fail(error: BlockchainSdkError.failedToLoadFee).eraseToAnyPublisher()
                }
                
                return self.getLayer1Fee(payload: payload, L2FeeParameters: parameters)
                    .tryMap { layer1Fee -> FeeDataModel in
                        switch layer2FeeDataModel.feeType {
                        case .multiple(let low, let normal, let priority):
                            var feeDataModel = FeeDataModel(
                                feeType: .multiple(
                                    low: Amount(with: low, value: low.value + layer1Fee),
                                    normal: Amount(with: normal, value: normal.value + layer1Fee),
                                    priority: Amount(with: priority, value: priority.value + layer1Fee)
                                )
                            )
                            feeDataModel.additionalParameters = layer2FeeDataModel.additionalParameters
                            return feeDataModel

                        case .single(let fee):
                            // Just for case. Usually we don't use it as single option fee
                            let feeAmount = Amount(with: fee, value: fee.value + layer1Fee)
                            var feeDataModel = FeeDataModel(feeType: .single(fee: feeAmount))
                            feeDataModel.additionalParameters = layer2FeeDataModel.additionalParameters
                            return feeDataModel
                        }
                    }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
}
    
// MARK: - Private
    
private extension OptimismWalletManager {
    func getLayer1Fee(payload: TransactionDestinationPayload,
                      L2FeeParameters: EthereumFeeParameters) -> AnyPublisher<Decimal, Error> {
        guard let address = EthereumAddress(payload.destination),
              let encodedValue = BigUInt(payload.value ?? "0x0") else {
            return Fail(error: BlockchainSdkError.failedToLoadFee).eraseToAnyPublisher()
        }
        
        
        let transaction = EthereumTransaction(gasPrice: L2FeeParameters.gasPrice,
                                              gasLimit: L2FeeParameters.gasLimit,
                                              to: address,
                                              value: encodedValue,
                                              data: payload.data ?? Data())
        
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

//MARK: - OptimismGasLoader

extension OptimismWalletManager: OptimismGasLoader {
    func getLayer1GasPrice() -> AnyPublisher<BigUInt, Error> {
        contractInteractor
            .read(method: .l1BaseFee)
            .tryMap { response in
                if let bigUIntPrice = BigUInt("\(response)") {
                    return bigUIntPrice
                }
                
                throw BlockchainSdkError.failedToLoadFee
            }
            .eraseToAnyPublisher()
    }
    
    func getLayer1GasLimit(data: String) -> AnyPublisher<BigUInt, Error> {
        contractInteractor
            .read(method: .getL1GasUsed(data: data))
            .tryMap { response in
                if let bigUIntLimit = BigUInt("\(response)") {
                    return bigUIntLimit
                }
                
                throw BlockchainSdkError.failedToLoadFee
            }
            .eraseToAnyPublisher()
    }
}
