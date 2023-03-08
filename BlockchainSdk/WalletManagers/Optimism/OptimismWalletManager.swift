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
    private var lastLayer1FeeAmount: Amount?
    private let contractInteractor: OptimismContractInteractor
    
    init(wallet: Wallet, rpcURL: URL) {
        self.contractInteractor = OptimismContractInteractor(rpcURL: rpcURL)
        super.init(wallet: wallet)
    }
    
    override func getGasPrice() -> AnyPublisher<BigUInt, Error> {
        Publishers.CombineLatest(super.getGasPrice(), getLayer1GasPrice())
            .map(+)
            .eraseToAnyPublisher()
    }
    
    override func getGasLimit(to: String, from: String, value: String?, data: String?) -> AnyPublisher<BigUInt, Error> {
        guard let data = data else {
            return Fail(error: BlockchainSdkError.failedToLoadFee).eraseToAnyPublisher()
        }
        
        return contractInteractor
            .read(method: .getL1GasUsed(data: data))
            .tryMap { response in
                if let bigUIntPrice = BigUInt("\(response)") {
                    return bigUIntPrice + 2100
                }
                
                throw BlockchainSdkError.failedToLoadFee
            }
            .eraseToAnyPublisher()
    }
    
    override func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        lastLayer1FeeAmount = nil
        
        let layer2FeePublisher = super.getFee(amount: amount, destination: destination)
        let transaction = Transaction(amount: Amount(with: wallet.blockchain, type: amount.type, value: 0.1),
                                      fee: Amount(with: wallet.blockchain, type: amount.type, value: 0.1),
                                      sourceAddress: wallet.address,
                                      destinationAddress: destination,
                                      changeAddress: wallet.address,
                                      contractAddress: amount.type.token?.contractAddress)

        let tx = txBuilder.buildForSign(transaction: transaction,
                                        nonce: 1,
                                        gasLimit: BigUInt(1))
        
        guard let byteArray = tx?.transaction.encodeForSend() else {
            return Fail(error: BlockchainSdkError.failedToLoadFee).eraseToAnyPublisher()
        }
        
        let layer1FeePublisher = getLayer1Fee(amount: amount,
                                              destination: destination,
                                              transactionHash: byteArray.toHexString().addHexPrefix())
        
        return Publishers
            .CombineLatest(layer2FeePublisher, layer1FeePublisher)
            .tryMap { [weak self] (layer2FeeAmounts, layer1FeeAmount) in
                guard let self = self else {
                    throw BlockchainSdkError.failedToLoadFee
                }
                
                let minAmount = Amount(with: self.wallet.blockchain, value: layer2FeeAmounts[0].value + layer1FeeAmount.value)
                let normalAmount = Amount(with: self.wallet.blockchain, value: layer2FeeAmounts[1].value + layer1FeeAmount.value)
                let maxAmount = Amount(with: self.wallet.blockchain, value: layer2FeeAmounts[2].value + layer1FeeAmount.value)
                self.lastLayer1FeeAmount = layer1FeeAmount
                
                return [minAmount, normalAmount, maxAmount]
        }.eraseToAnyPublisher()
    }
    
    override func sign(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<String, Error> {
        let calculatedTransactionFee = transaction.fee.value - (lastLayer1FeeAmount?.value ?? 0)
        guard var transactionWithCorrectFee = try? createTransaction(amount: transaction.amount,
                                                                     fee: Amount(with: wallet.blockchain, value: calculatedTransactionFee),
                                                                     destinationAddress: transaction.destinationAddress)
        else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
        
        transactionWithCorrectFee.params = transaction.params
        return super.sign(transactionWithCorrectFee, signer: signer)
    }
}

//MARK: - Private

extension OptimismWalletManager {
    private func getLayer1GasPrice() -> AnyPublisher<BigUInt, Error> {
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
    
    private func getLayer1Fee(amount: Amount, destination: String, transactionHash: String) -> AnyPublisher<Amount, Error> {
        contractInteractor
            .read(method: .getL1Fee(data: transactionHash))
            .tryMap { response in
                if let bigUIntFee = BigUInt("\(response)"),
                   let fee = Web3.Utils.formatToEthereumUnits(bigUIntFee, toUnits: .eth, decimals: 18, decimalSeparator: ".", fallbackToScientific: false),
                   let decimalFee = Decimal(fee) {
                    return Amount(with: self.wallet.blockchain, value: decimalFee)
                } else {
                    throw BlockchainSdkError.failedToLoadFee
                }
            }.eraseToAnyPublisher()
    }
}
