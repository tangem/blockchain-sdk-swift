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
    private var gasLimit: BigUInt? = nil
    private let l1FeeContractMethodName: String = "getL1Fee"
    private var lastL1FeeAmount: Amount?
    
    private var optimismFeeAddress: String {
        return EthereumAddress("0x420000000000000000000000000000000000000F")!.address
    }
    
    private var rpcURL: URL {
        return wallet.blockchain.getJsonRpcURLs(infuraProjectId: "613a0b14833145968b1f656240c7d245")![0]
    }
    
    override func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        lastL1FeeAmount = nil
        
        let l2Fee = super.getFee(amount: amount, destination: destination)
        let destinationInfo = formatDestinationInfo(for: destination, amount: amount)
        let tx = txBuilder.buildForSign(transaction: Transaction.dummyTx(blockchain: wallet.blockchain,
                                                                         type: amount.type,
                                                                         destinationAddress: destination), nonce: 1, gasLimit: BigUInt(1))
        
        guard let byteArray = tx?.transaction.encodeForSend() else {
            return Fail(error: BlockchainSdkError.failedToLoadFee).eraseToAnyPublisher()
        }
        
        let l1Fee = getL1Fee(amount: amount, destination: destinationInfo.to, transactionHash: byteArray.toHexString())
        
        return Publishers
            .CombineLatest(l2Fee, l1Fee)
            .tryMap { [weak self] (l2FeeAmounts, l1FeeAmount) in
                guard let self = self else {
                    throw BlockchainSdkError.failedToLoadFee
                }
                let minAmount = Amount(with: self.wallet.blockchain, value: l2FeeAmounts[0].value + l1FeeAmount.value)
                let normalAmount = Amount(with: self.wallet.blockchain, value: l2FeeAmounts[1].value + l1FeeAmount.value)
                let maxAmount = Amount(with: self.wallet.blockchain, value: l2FeeAmounts[2].value + l1FeeAmount.value)
                self.lastL1FeeAmount = l1FeeAmount
                
                return [minAmount, normalAmount, maxAmount]
        }.eraseToAnyPublisher()
    }
    
    override func sign(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<String, Error> {
        guard let transactionWithCorrectFee = try? createTransaction(amount: transaction.amount, fee: Amount(with: wallet.blockchain, value: transaction.fee.value - (lastL1FeeAmount?.value ?? 0)), destinationAddress: transaction.destinationAddress)
        else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
        
        return super.sign(transactionWithCorrectFee, signer: signer)
    }
}

//MARK: - Private

extension OptimismWalletManager {
    private func getL1Fee(amount: Amount, destination: String, transactionHash: String) -> AnyPublisher<Amount, Error> {
        return Deferred {
            Future { [weak self] promise in
                guard let self = self else { return }
                let contractInteractor = ContractInteractor(address: self.optimismFeeAddress, abi: OptimismL1GasFeeABI, rpcURL: self.rpcURL)
                let params = [transactionHash] as! [AnyObject]
                contractInteractor.read(method: self.l1FeeContractMethodName, parameters: params) { result in
                    switch result {
                    case .success(let response):
                        if let bigUIntFee = BigUInt("\(response)"),
                           let fee = Web3.Utils.formatToEthereumUnits(bigUIntFee, toUnits: .eth, decimals: 18, decimalSeparator: ".", fallbackToScientific: false),
                           let decimalFee = Decimal(fee) {
                            let amount = Amount(with: self.wallet.blockchain, value: decimalFee)
                            promise(.success(amount))
                        } else {
                            promise(.failure(BlockchainSdkError.failedToLoadFee))
                        }
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    private func formatDestinationInfo(for destination: String, amount: Amount) -> (to: String, value: String?, data: String?) {
        var to = destination
        var value: String? = nil
        var data: String? = nil
        
        if amount.type == .coin,
           let amountValue = Web3.Utils.parseToBigUInt("\(amount.value)", decimals: amount.decimals)
        {
            value = "0x" + String(amountValue, radix: 16)
        }
        
        if let token = amount.type.token, let erc20Data = txBuilder.getData(for: amount, targetAddress: destination) {
            to = token.contractAddress
            data = "0x" + erc20Data.hexString
        }
        
        return (to, value, data)
    }
}
