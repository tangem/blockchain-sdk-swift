//
//  NearNetworkService.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 04.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import BigInt

class NearNetworkService {
    let provider: MoyaProvider = MoyaProvider<NearTarget>()
    let blockchain: Blockchain
    
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
    
    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }
    
    func accountInfo(publicKey: Data) -> AnyPublisher<NearAccountInfoResponse, Error> {
        let key = NearPublicKey(from: publicKey)
        return provider
            .requestPublisher(.init(endpoint: .accountInfo(accountID: key.address(), isTestnet: blockchain.isTestnet)))
            .tryMap({ [weak self] response -> NearAccountInfoResponse in
                guard let self = self else {
                    throw WalletError.empty
                }
                if let error = try? self.checkError(data: response.data) {
                    if error.error.cause.name == NearNetworkError.unknownAccount.rawValue {
                        throw WalletError.noAccount(message: error.error.message)
                    } else {
                        throw WalletError.empty
                    }
                }
                guard let nearResponse = try? self.decoder.decode(NearAccountInfoResponse.self, from: response.data) else {
                    throw WalletError.empty
                }
                return nearResponse
            })
            .eraseToAnyPublisher()
    }
    
    func accountHistory(publicKey: Data) -> AnyPublisher<NearAccountHistoryResponse, Error> {
        let key = NearPublicKey(from: publicKey)
        return provider
            .requestPublisher(.init(endpoint: .accountHistory(accountID: key.address(), isTestnet: blockchain.isTestnet)))
            .tryMap { [weak self] response -> NearAccountHistoryResponse in
                guard let self = self else {
                    throw WalletError.empty
                }
                if let error = try? self.checkError(data: response.data) {
                    if error.error.cause.name == NearNetworkError.unknownAccount.rawValue {
                        throw WalletError.noAccount(message: error.error.message)
                    } else {
                        throw WalletError.empty
                    }
                }
                guard let nearResponse = try? self.decoder.decode(NearAccountHistoryResponse.self, from: response.data) else {
                    throw WalletError.empty
                }
                return nearResponse
            }
            .eraseToAnyPublisher()
    }
    
    func gasPrice() -> AnyPublisher<Int, Error> {
        provider
            .requestPublisher(.init(endpoint: .gasPrice(isTestnet: blockchain.isTestnet)))
            .map(NearGasPriceResponse.self, using: decoder)
            .tryMap({ response in
                guard let price = Int(response.result.gasPrice) else {
                    throw WalletError.failedToGetFee
                }
                return price
            })
            .eraseToAnyPublisher()
    }
    
    func accessKeyList(publicKey: Data) {
        let key = NearPublicKey(from: publicKey)
        provider
            .requestPublisher(.init(endpoint: .accessKeyList(accountID: key.address(), isTestnet: blockchain.isTestnet)))
            .tryMap { [weak self] response -> NearAccessKeyListResponse in
                guard let self = self else {
                    throw WalletError.empty
                }
                if let error = try? self.checkError(data: response.data) {
                    if error.error.cause.name == NearNetworkError.unknownAccount.rawValue {
                        throw WalletError.noAccount(message: error.error.message)
                    } else {
                        throw WalletError.empty
                    }
                }
                guard let nearResponse = try? self.decoder.decode(NearAccessKeyListResponse.self, from: response.data) else {
                    throw WalletError.empty
                }
                return nearResponse
            }
            .eraseToAnyPublisher()
    }
    
    private func checkError(data: Data) throws -> NearErrorResponse {
        return try decoder.decode(NearErrorResponse.self, from: data)
    }
}
