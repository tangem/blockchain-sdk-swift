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
    override func getFee(payload: EthereumDestinationPayload) -> AnyPublisher<FeeType, Error> {
        super.getFee(payload: payload)
            .tryMap { [weak self] layer2FeeType -> AnyPublisher<FeeType, Error> in
                guard let self,
                      let parameters = layer2FeeType.lowFeeModel?.parameters as? EthereumFeeParameters else {
                    return Fail(error: BlockchainSdkError.failedToLoadFee).eraseToAnyPublisher()
                }

                return self.getLayer1Fee(payload: payload, L2FeeParameters: parameters)
                    .tryMap { layer1Fee throws -> FeeType in
                        switch layer2FeeType {
                        case .multiple(let low, let normal, let priority):
                            let updatedModels: [FeeType.FeeModel] = [low, normal, priority]
                                .map { feeModel in
                                    let oldAmount = feeModel.fee
                                    let newAmount = Amount(with: oldAmount, value: oldAmount.value + layer1Fee)
                                    let newFeeModel = FeeType.FeeModel(
                                        newAmount,
                                        parameters: layer2FeeType.lowFeeModel?.parameters
                                    )
                                    return newFeeModel
                                }

                            return try FeeType(fees: updatedModels)

                        case .single:
                            assertionFailure("Not implement this case")
                            return layer2FeeType
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
    func getLayer1Fee(payload: EthereumDestinationPayload,
                      L2FeeParameters: EthereumFeeParameters) -> AnyPublisher<Decimal, Error> {
        assert(payload.value != nil)
        
        guard let address = EthereumAddress(payload.targetAddress),
              let value = payload.value,
              let encodedValue = BigUInt(value) else {
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
