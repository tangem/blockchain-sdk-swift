//
//  TronJsonRpcProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 24.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya

class TronJsonRpcProvider: HostProvider {
    var host: String {
        network.url.hostOrUnknown
    }

    private let network: TronNetwork
    private let provider = MoyaProvider<TronTarget>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: [
        .requestMethod,
        .requestBody,
        .successResponseBody,
        .errorResponseBody
    ]))])
    
    init(network: TronNetwork) {
        self.network = network
    }

    func getAccount(for address: String) -> AnyPublisher<TronGetAccountResponse, Error> {
        requestPublisher(for: .getAccount(address: address, network: network))
    }
    
    func getAccountResource(for address: String) -> AnyPublisher<TronGetAccountResourceResponse, Error> {
        requestPublisher(for: .getAccountResource(address: address, network: network))
    }
    
    func getNowBlock() -> AnyPublisher<TronBlock, Error> {
        requestPublisher(for: .getNowBlock(network: network))
    }
    
    func createTransaction(from source: String, to destination: String, amount: UInt64) -> AnyPublisher<TronTransactionRequest<TrxTransferValue>, Error> {
        requestPublisher(for: .createTransaction(
            source: source,
            destination: destination,
            amount: amount,
            network: network
        ))
    }
    
    func createTrc20Transaction(from source: String, to destination: String, contractAddress: String, amount: UInt64) -> AnyPublisher<TronSmartContractTransactionRequest, Error> {
        requestPublisher(for: .createTrc20Transaction(
            source: source,
            destination: destination,
            contractAddress: contractAddress,
            amount: amount,
            feeLimit: 10_000_000,
            network: network
        ))
    }
    
    func broadcastHex(_ data: Data) -> AnyPublisher<TronBroadcastResponse, Error> {
        requestPublisher(for: .broadcastHex(data: data, network: network))
    }
    
    func broadcastTransaction<T: Codable>(_ transaction: TronTransactionRequest<T>) -> AnyPublisher<TronBroadcastResponse, Error> {
        let json = JSONEncoder()
        do {
            let transactionData = try json.encode(transaction)
            return requestPublisher(for: .broadcastTransaction(transactionData: transactionData, network: network))
        } catch {
            return .anyFail(error: WalletError.failedToBuildTx)
        }
    }
    
    func tokenBalance(address: String, contractAddress: String) -> AnyPublisher<TronTriggerSmartContractResponse, Error> {
        requestPublisher(for: .tokenBalance(address: address, contractAddress: contractAddress, network: network))
    }
    
    func tokenTransactionHistory(contractAddress: String) -> AnyPublisher<TronTokenHistoryResponse, Error> {
        requestPublisher(for: .tokenTransactionHistory(contractAddress: contractAddress, limit: 50, network: network))
    }
    
    func transactionInfo(id: String) -> AnyPublisher<TronTransactionInfo, Error> {
        requestPublisher(for: .getTransactionInfoById(transactionID: id, network: network))
    }
    
    private func requestPublisher<T: Codable>(for target: TronTarget) -> AnyPublisher<T, Error> {
        return provider.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(T.self)
            .catch { _ -> AnyPublisher<T, Error> in
                // TODO
                return .anyFail(error: WalletError.failedToParseNetworkResponse)
            }
            .eraseToAnyPublisher()
    }
}
