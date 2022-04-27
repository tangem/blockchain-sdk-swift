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
    private let provider = MoyaProvider<TronTarget>(plugins: [NetworkLoggerPlugin()])
    
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
    
    func broadcastHex(_ data: Data) -> AnyPublisher<TronBroadcastResponse, Error> {
        requestPublisher(for: .broadcastHex(data: data, network: network))
    }
    
    func tokenBalance(address: String, contractAddress: String) -> AnyPublisher<TronTriggerSmartContractResponse, Error> {
        requestPublisher(for: .tokenBalance(address: address, contractAddress: contractAddress, network: network))
    }
    
    func tokenTransactionHistory(contractAddress: String) -> AnyPublisher<TronTokenHistoryResponse, Error> {
        requestPublisher(for: .tokenTransactionHistory(contractAddress: contractAddress, limit: 50, network: network))
    }
    
    func transactionInfo(id: String) -> AnyPublisher<TronTransactionInfoResponse, Error> {
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
