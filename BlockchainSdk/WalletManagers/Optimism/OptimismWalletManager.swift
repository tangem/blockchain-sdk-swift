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
    let rpcURL: URL
    
    private var gasLimit: BigUInt? = nil
    private let layer1FeeContractMethodName: String = "getL1Fee"
    private var lastLayer1FeeAmount: Amount?
    
    private var optimismFeeAddress: String {
        return EthereumAddress("0x420000000000000000000000000000000000000F")!.address
    }
    
    init(wallet: Wallet, rpcURL: URL) {
        self.rpcURL = rpcURL
        super.init(wallet: wallet)
    }
    
    override func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        lastLayer1FeeAmount = nil
        
        let layer2FeePublisher = super.getFee(amount: amount, destination: destination)
        let transaction = Transaction.dummyTx(blockchain: wallet.blockchain, type: amount.type, destinationAddress: destination)
        
        let tx = txBuilder.buildForSign(transaction: transaction,
                                        nonce: 1,
                                        gasLimit: BigUInt(1))
        
        guard let byteArray = tx?.transaction.encodeForSend() else {
            return Fail(error: BlockchainSdkError.failedToLoadFee).eraseToAnyPublisher()
        }
        
        let layer1FeePublisher = getLayer1Fee(amount: amount,
                                              destination: destination,
                                              transactionHash: byteArray.toHexString())
        
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
        guard let transactionWithCorrectFee = try? createTransaction(amount: transaction.amount,
                                                                     fee: Amount(with: wallet.blockchain, value: calculatedTransactionFee),
                                                                     destinationAddress: transaction.destinationAddress)
        else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
        
        return super.sign(transactionWithCorrectFee, signer: signer)
    }
}

//MARK: - Private

extension OptimismWalletManager {
    private func getLayer1Fee(amount: Amount, destination: String, transactionHash: String) -> AnyPublisher<Amount, Error> {
        let contractInteractor = ContractInteractor(address: self.optimismFeeAddress, abi: ContractABI().optimismLayer1GasFeeABI, rpcURL: self.rpcURL)
        let params = [transactionHash] as! [AnyObject]
        
        return contractInteractor
            .read(method: self.layer1FeeContractMethodName, parameters: params)
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
