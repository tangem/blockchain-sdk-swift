//
//  CardanoNetworkService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 08.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import SwiftyJSON

class CardanoNetworkService {
    private var adaliteUrl: AdaliteUrl = .url1
    private let provider = MoyaProvider<AdaliteTarget>()
    
    @available(iOS 13.0, *)
    func send(base64EncodedTx: String) -> AnyPublisher<String, Error> {
        return provider
            .requestPublisher(.send(base64EncodedTx: base64EncodedTx, url: adaliteUrl))
            .filterSuccessfulStatusAndRedirectCodes()
            .mapNotEmptyString()
            .eraseError()
    }
    
    func getInfo(address: String) -> AnyPublisher<(AdaliteBalanceResponse,[AdaliteUnspentOutput]), Error> {
        return getUnspents(address: address)
            .flatMap { unspentsResponse -> AnyPublisher<(AdaliteBalanceResponse, [AdaliteUnspentOutput]), Error> in
                return self.getBalance(address: address)
                    .map { balanceResponse -> (AdaliteBalanceResponse,[AdaliteUnspentOutput]) in
                        return (balanceResponse, unspentsResponse)
                }
            .eraseToAnyPublisher()
        }
//        .catchError { error throws in
//            if case MoyaError.statusCode(let response) = error {
//                if self.adaliteUrl == .url1 {
//                    self.adaliteUrl = .url2
//                }
//            }
//            throw error
//        }
        .retry(2)
        .eraseToAnyPublisher()
    }
    
    private func getUnspents(address: String) -> AnyPublisher<[AdaliteUnspentOutput], Error> {
        return provider
            .requestPublisher(.unspents(address: address, url: adaliteUrl))
            .filterSuccessfulStatusAndRedirectCodes()
            .mapSwiftyJSON()
            .tryMap { json throws -> [AdaliteUnspentOutput] in
                let unspentOutputsJson = json["Right"].arrayValue
                let unspentOutputs = unspentOutputsJson.map{ json -> AdaliteUnspentOutput in
                    let output = AdaliteUnspentOutput(id: json["cuId"].stringValue, index: json["cuOutIndex"].intValue)
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
                guard let balanceString = json["Right"]["caBalance"]["getCoin"].string,
                    let balance = Decimal(balanceString) else {
                        throw json["Left"].stringValue
                }
                
                let convertedValue = balance/Decimal(1000000)
                
                var transactionList = [String]()
                if let transactionListJSON = json["Right"]["caTxList"].array {
                    transactionList = transactionListJSON.map({ return $0["ctbId"].stringValue })
                }
                
                let response = AdaliteBalanceResponse(balance: convertedValue, transactionList: transactionList)
                return response
        }
        .eraseToAnyPublisher()
    }
}
