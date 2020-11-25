//
//  Blockcypher.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 20.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine

class BlockcypherProvider: BitcoinNetworkProvider {
    let provider = MoyaProvider<BlockcypherTarget> ()
    let endpoint: BlockcypherEndpoint
    
    private var token: String? = nil
    
    init(endpoint: BlockcypherEndpoint) {
        self.endpoint = endpoint
    }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        return Just(())
            .setFailureType(to: MoyaError.self)
            .flatMap {[unowned self] in
                self.provider
                    .requestPublisher(BlockcypherTarget(endpoint: self.endpoint, token: self.token, targetType: .address(address: address)))
                    .filterSuccessfulStatusAndRedirectCodes()
        }
        .catch{[unowned self] error -> AnyPublisher<Response, MoyaError> in
            self.changeToken(error)
            return Fail(error: error).eraseToAnyPublisher()
        }
        .retry(1)
        .eraseToAnyPublisher()
        .map(BlockcypherAddressResponse.self)
        .tryMap {[unowned self] addressResponse -> BitcoinResponse in
            guard let balance = addressResponse.balance,
                let uncBalance = addressResponse.unconfirmed_balance
                else {
                    throw WalletError.failedToParseNetworkResponse
            }
            
            let satoshiBalance = Decimal(balance)/self.endpoint.blockchain.decimalValue
            let txs: [BtcTx] = addressResponse.txrefs?.compactMap { utxo -> BtcTx?  in
                guard let hash = utxo.tx_hash,
                    let n = utxo.tx_output_n,
                    let val = utxo.value else {
                        return nil
                }
                
                let btx = BtcTx(tx_hash: hash, tx_output_n: n, value: UInt64(val))
                return btx
                } ?? []
            
            let btcResponse = BitcoinResponse(balance: satoshiBalance, hasUnconfirmed:  uncBalance != 0, txrefs: txs)
            return btcResponse
        }
        .eraseToAnyPublisher()
    }
    
    
    @available(iOS 13.0, *)
    func getFee() -> AnyPublisher<BtcFee, Error> {
        return Just(())
            .setFailureType(to: MoyaError.self)
            .flatMap { [unowned self] in
                self.provider
                    .requestPublisher(BlockcypherTarget(endpoint: self.endpoint, token: self.token, targetType: .fee))
                    .filterSuccessfulStatusAndRedirectCodes()
        }
        .catch{[unowned self] error -> AnyPublisher<Response, MoyaError> in
            self.changeToken(error)
            return Fail(error: error).eraseToAnyPublisher()
        }
        .retry(1)
        .eraseToAnyPublisher()
        .map(BlockcypherFeeResponse.self)
        .tryMap {[unowned self] feeResponse -> BtcFee in
            guard let minKb = feeResponse.low_fee_per_kb,
                let normalKb = feeResponse.medium_fee_per_kb,
                let maxKb = feeResponse.high_fee_per_kb else {
                    throw "Can't load fee"
            }
            
            let minKbValue = Decimal(minKb)/self.endpoint.blockchain.decimalValue
            let normalKbValue = Decimal(normalKb)/self.endpoint.blockchain.decimalValue
            let maxKbValue = Decimal(maxKb)/self.endpoint.blockchain.decimalValue
            let fee = BtcFee(minimalKb: minKbValue, normalKb: normalKbValue, priorityKb: maxKbValue)
            return fee
        }
        .eraseToAnyPublisher()
    }
    
    @available(iOS 13.0, *)
    func send(transaction: String) -> AnyPublisher<String, Error> {
        return Just(())
            .setFailureType(to: MoyaError.self)
            .flatMap { [unowned self] in
                self.provider.requestPublisher(BlockcypherTarget(endpoint: self.endpoint, token: self.token ?? self.getRandomToken(), targetType: .send(txHex: transaction)))
                    .filterSuccessfulStatusAndRedirectCodes()
        }
        .catch{ [unowned self] error -> AnyPublisher<Response, MoyaError> in
            self.changeToken(error)
            return Fail(error: error).eraseToAnyPublisher()
        }
        .retry(1)
        .eraseToAnyPublisher()
        .mapNotEmptyString()
        .eraseError()
        .eraseToAnyPublisher()
    }
    
    @available(iOS 13.0, *)
    func getTx(hash: String) -> AnyPublisher<BlockcypherTx, Error> {
        return Just(())
            .setFailureType(to: MoyaError.self)
            .flatMap {[unowned self] in
                self.provider.requestPublisher(BlockcypherTarget(endpoint: self.endpoint, token: self.token, targetType: .txs(txHash: hash)))
                    .filterSuccessfulStatusAndRedirectCodes()
        }
        .catch{[unowned self]  error -> AnyPublisher<Response, MoyaError> in
            self.changeToken(error)
            return Fail(error: error).eraseToAnyPublisher()
        }
        .retry(1)
        .eraseToAnyPublisher()
        .map(BlockcypherTx.self)
        .eraseError()
    }
    
    private func getRandomToken() -> String {
        let tokens: [String] = ["aa8184b0e0894b88a5688e01b3dc1e82",
                                "56c4ca23c6484c8f8864c32fde4def8d",
                                "66a8a37c5e9d4d2c9bb191acfe7f93aa"]
        
        let tokenIndex = Int.random(in: 0...2)
        return tokens[tokenIndex]
    }
    
    private func changeToken(_ error: MoyaError) {
        if case let MoyaError.statusCode(response) = error, response.statusCode == 429 {
            self.token = self.getRandomToken()
        }
    }
}
