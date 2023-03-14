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
    
    /// We are override this method to combine two fee layers in the `OptimisticEthereum` network.
    /// Read more: https://community.optimism.io/docs/developers/build/transaction-fees/#the-l1-data-fee
    override func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        lastLayer1Fee = nil

        
        let transaction = Transaction(
            amount: Amount(with: wallet.blockchain, type: amount.type, value: 0.1),
            fee: Amount(with: wallet.blockchain, type: amount.type, value: 0.1),
            sourceAddress: wallet.address,
            destinationAddress: destination,
            changeAddress: wallet.address,
            contractAddress: amount.type.token?.contractAddress
        )

        let tx = txBuilder.buildForSign(transaction: transaction, nonce: 1, gasLimit: BigUInt(1))
        
        // Think about this way of getting data, maybe it can work without a dummy tx
        guard let byteArray = tx?.transaction.encodeForSend() else {
            return Fail(error: BlockchainSdkError.failedToLoadFee).eraseToAnyPublisher()
        }
        
        let layer1FeePublisher = getLayer1Fee(data: byteArray.hexString.addHexPrefix())
        let layer2FeePublisher = super.getFee(amount: amount, destination: destination)
        
        return Publishers
            .CombineLatest(layer2FeePublisher, layer1FeePublisher)
            .tryMap { [weak self] (layer2FeeAmounts, layer1FeeAmount) in
                let fees = layer2FeeAmounts.map { amount in
                    Amount(type: amount.type, currencySymbol: amount.currencySymbol,
                           value: amount.value + layer1FeeAmount,
                           decimals: amount.decimals)
                }
                
                self?.lastLayer1Fee = layer1FeeAmount
                print("OptimismWalletManager calculated fees: ", fees)
                
                return fees
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
