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
    private let contractInteractor: OptimismContractInteractor
    
    /// Tempopary store for fee which will be removed from fee to correct calculation in the transaction
    private var lastLayer1Fee: Decimal?
    
    init(wallet: Wallet, rpcURL: URL) {
        self.contractInteractor = OptimismContractInteractor(rpcURL: rpcURL)
        super.init(wallet: wallet)
    }
    
    override func getFee(to: String, value: String?, data: String?) -> AnyPublisher<[Amount], Error> {
        guard let data = data else {
            assertionFailure("Data is not found for fee")
            return super.getFee(to: to, value: value, data: data)
        }
        
        let layer1FeePublisher = getLayer1Fee(data: data)
        let layer2FeePublisher = super.getFee(to: to, value: value, data: data)
        
        return Publishers
            .CombineLatest(layer2FeePublisher, layer1FeePublisher)
            .tryMap { [weak self] (layer2FeeAmounts, layer1FeeAmount) in
                guard let self = self else {
                    throw BlockchainSdkError.failedToLoadFee
                }
                
                let blockchain = self.wallet.blockchain
                
                let minAmount = Amount(with: blockchain, value: layer2FeeAmounts[0].value + layer1FeeAmount)
                let normalAmount = Amount(with: blockchain, value: layer2FeeAmounts[1].value + layer1FeeAmount)
                let maxAmount = Amount(with: blockchain, value: layer2FeeAmounts[2].value + layer1FeeAmount)
                self.lastLayer1Fee = layer1FeeAmount
                
                return [minAmount, normalAmount, maxAmount]
        }.eraseToAnyPublisher()
    }

    /// For what override method from the protocol `EthereumTransactionSigner`
    /// We calculate the `gasPrice` for `tx` using the formula `fee / gasLimit`
    /// The `gasLimit` may set in txParams or stored in the `EthereumWalletManager` when we call the `getFee` method
    /// And here we have to remove the `lastLayer1Fee` for the correct calculation `gasPrice` in `txBuilder`
    override func sign(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<String, Error> {
        guard let lastLayer1Fee = lastLayer1Fee else {
            return super.sign(transaction, signer: signer)
        }

        let calculatedTransactionFee = transaction.fee.value - lastLayer1Fee
        
        do {
            var transactionWithCorrectFee = try createTransaction(
                amount: transaction.amount,
                fee: Amount(with: wallet.blockchain, value: calculatedTransactionFee),
                destinationAddress: transaction.destinationAddress
            )
            transactionWithCorrectFee.params = transaction.params
            return super.sign(transactionWithCorrectFee, signer: signer)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
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
                if let bigUIntPrice = BigUInt("\(response)") {
                    return bigUIntPrice
                }
                
                throw BlockchainSdkError.failedToLoadFee
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
