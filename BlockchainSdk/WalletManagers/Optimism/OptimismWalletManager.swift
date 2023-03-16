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
    
    /// We are override this method to combine two fee layers in the `OptimisticEthereum` network.
    /// Read more: https://community.optimism.io/docs/developers/build/transaction-fees/#the-l1-data-fee
    override func getFee(amount: Amount, destination: String) -> AnyPublisher<FeeDataModel, Error> {
        var transaction = Transaction(
            amount: Amount(with: wallet.blockchain, type: amount.type, value: 0.1),
            fee: Amount(with: wallet.blockchain, type: amount.type, value: 0.1),
            sourceAddress: wallet.address,
            destinationAddress: destination,
            changeAddress: wallet.address,
            contractAddress: amount.type.token?.contractAddress
        )

        transaction.params = EthereumTransactionParams(gasLimit: BigUInt(1), gasPrice: BigUInt(1))
        let tx = txBuilder.buildForSign(transaction: transaction, nonce: 1)

        // Think about this way of getting data, maybe it can work without a dummy tx
        guard let byteArray = tx?.transaction.encodeForSend() else {
            return Fail(error: BlockchainSdkError.failedToLoadFee).eraseToAnyPublisher()
        }
        
        let layer1FeePublisher = getLayer1Fee(data: byteArray.hexString.addHexPrefix())
        let layer2FeePublisher = super.getFee(amount: amount, destination: destination)
        
        return Publishers
            .CombineLatest(layer2FeePublisher, layer1FeePublisher)
            .tryMap { layer2FeeDataModel, layer1Fee -> FeeDataModel in
                
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
                    let feeAmount = Amount(with: fee, value: fee.value + layer1Fee)
                    var feeDataModel = FeeDataModel(feeType: .single(fee: feeAmount))
                    feeDataModel.additionalParameters = layer2FeeDataModel.additionalParameters
                    return feeDataModel
                }
            }
            .eraseToAnyPublisher()
    }
}
    
// MARK: - Private
    
private extension OptimismWalletManager {
    func getLayer1Fee(data: String) -> AnyPublisher<Decimal, Error> {
        contractInteractor
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
