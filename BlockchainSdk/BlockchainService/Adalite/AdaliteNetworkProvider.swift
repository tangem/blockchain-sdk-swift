//
//  AdaliteNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 08.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import SwiftyJSON

class AdaliteNetworkProvider: CardanoNetworkProvider {
    private let adaliteUrl: AdaliteUrl
    private let provider = MoyaProvider<AdaliteTarget>()
    
    init(baseUrl: AdaliteUrl) {
        adaliteUrl = baseUrl
    }
    
    @available(iOS 13.0, *)
    func send(transaction: Data) -> AnyPublisher<String, Error> {
        return provider
            .requestPublisher(.send(base64EncodedTx: transaction.base64EncodedString(), url: adaliteUrl))
            .filterSuccessfulStatusAndRedirectCodes()
            .mapNotEmptyString()
            .eraseError()
    }
    
    func getInfo(address: String) -> AnyPublisher<CardanoAddressResponse, Error> {
        getUnspents(address: address)
            .flatMap { unspents -> AnyPublisher<CardanoAddressResponse, Error> in
                self.getBalance(address: address)
                    .map { balanceResponse -> CardanoAddressResponse in
                        CardanoAddressResponse(balance: balanceResponse.balance, recentTransactionsHashes: balanceResponse.transactions, unspentOutputs: unspents)
                    }
                    .eraseToAnyPublisher()
            }
            .retry(2)
            .eraseToAnyPublisher()
    }
    
    private func getUnspents(address: String) -> AnyPublisher<[CardanoUnspentOutput], Error> {
        return provider
            .requestPublisher(.unspents(address: address, url: adaliteUrl))
            .filterSuccessfulStatusAndRedirectCodes()
            .mapSwiftyJSON()
            .tryMap { json throws -> [CardanoUnspentOutput] in
                let unspentOutputsJson = json["Right"].arrayValue
                let unspentOutputs = unspentOutputsJson.map{ json -> CardanoUnspentOutput in
                    let output = CardanoUnspentOutput(address: json["cuAddress"].stringValue, amount: Decimal(json["cuCoins"]["getCoin"].doubleValue), outputIndex: json["cuOutIndex"].intValue, transactionHash: json["cuId"].stringValue)
                    return output
                }
                return unspentOutputs
        }
    .eraseToAnyPublisher()
    }
    
    private func getBalance(address: String) -> AnyPublisher<AdaliteBalanceResponse, Error> {
        return provider
            .requestPublisher(.address(address: address, url: adaliteUrl))
            .filterSuccessfulStatusAndRedirectCodes()
            .mapSwiftyJSON()
            .tryMap {json throws -> AdaliteBalanceResponse in
                let addressData = json["Right"]
                guard let balanceString = addressData["caBalance"]["getCoin"].string,
                    let balance = Decimal(balanceString) else {
                        throw json["Left"].stringValue
                }
                
                let convertedValue = balance/Decimal(1000000)
                
                var transactionList = [String]()
                if let transactionListJSON = addressData["caTxList"].array {
                    transactionList = transactionListJSON.map({ return $0["ctbId"].stringValue })
                }
                
                let response = AdaliteBalanceResponse(balance: convertedValue, transactions: transactionList)
                return response
        }
        .eraseToAnyPublisher()
    }
}
