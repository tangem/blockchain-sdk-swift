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
    private let tokens: [String]
    
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .customISO8601
        return decoder
    }()
    
    init(endpoint: BlockcypherEndpoint, tokens: [String]) {
        self.endpoint = endpoint
        self.tokens = tokens
    }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        return Just(())
            .setFailureType(to: MoyaError.self)
            .flatMap {[unowned self] in
                self.provider
                    .requestPublisher(BlockcypherTarget(endpoint: self.endpoint, token: self.token, targetType: .address(address: address, unspentsOnly: true, limit: nil, isFull: true)))
                    .filterSuccessfulStatusAndRedirectCodes()
            }
            .catch{[unowned self] error -> AnyPublisher<Response, MoyaError> in
                self.changeToken(error)
                return Fail(error: error).eraseToAnyPublisher()
            }
            .retry(1)
            .eraseToAnyPublisher()
            .map(BlockcypherFullAddressResponse.self, using: jsonDecoder)
            .tryMap {[unowned self] addressResponse -> BitcoinResponse in
                guard let balance = addressResponse.balance,
                      let uncBalance = addressResponse.unconfirmedBalance
                else {
                    throw WalletError.failedToParseNetworkResponse
                }
                
                let satoshiBalance = Decimal(balance) / self.endpoint.blockchain.decimalValue
                
                var utxo: [BtcTx] = []
                var pendingTxRefs: [PendingBtcTx] = []
                
                addressResponse.txs?.forEach { tx in
                    if tx.blockIndex == -1 {
                        let pendingTx = tx.pendingBtxTx(sourceAddress: address, decimalValue: self.endpoint.blockchain.decimalValue)
                        pendingTxRefs.append(pendingTx)
                    } else {
                        var txOutputIndex: Int = -1
                        guard
                            tx.outputs.enumerated().contains(where: {
                                guard
                                    $0.element.addresses.contains(address),
                                    $0.element.spentBy == nil
                                else { return false }
                                
                                txOutputIndex = $0.offset
                                return true
                            }),
                            txOutputIndex >= 0
                        else {
                            return
                        }
                        
                        let hash = tx.hash
                        let script = tx.outputs[txOutputIndex].script
                        let value = tx.outputs[txOutputIndex].value
                        
                        let btx = BtcTx(tx_hash: hash, tx_output_n: txOutputIndex, value: value, script: script)
                        utxo.append(btx)
                    }
                }
                
                if Decimal(uncBalance) / self.endpoint.blockchain.decimalValue != pendingTxRefs.reduce(0, { $0 + $1.value }) {
                    print("Unconfirmed balance and pending tx refs sum is not equal")
                }
                let btcResponse = BitcoinResponse(balance: satoshiBalance, hasUnconfirmed: uncBalance != 0, txrefs: utxo, pendingTxRefs: pendingTxRefs)
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
            .tryMap { feeResponse -> BtcFee in
                guard let minKb = feeResponse.low_fee_per_kb,
                      let normalKb = feeResponse.medium_fee_per_kb,
                      let maxKb = feeResponse.high_fee_per_kb else {
                    throw "Can't load fee"
                }
                let kb = Decimal(1024)
                let min = (Decimal(minKb)/kb).rounded(roundingMode: .down)
                let normal = (Decimal(normalKb)/kb).rounded(roundingMode: .down)
                let max = (Decimal(maxKb)/kb).rounded(roundingMode: .down)
                let fee = BtcFee(minimalSatoshiPerByte: min, normalSatoshiPerByte: normal, prioritySatoshiPerByte: max)
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
    
//    func getTx(hash: String) -> AnyPublisher<BlockcypherTx, Error> {
//        publisher(for: BlockcypherTarget(endpoint: self.endpoint, token: self.token, targetType: .txs(txHash: hash)))
//            .map(BlockcypherTx.self)
//            .eraseError()
//    }

    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        publisher(for: BlockcypherTarget(endpoint: self.endpoint, token: self.token, targetType: .address(address: address, unspentsOnly: false, limit: 2000, isFull: false)))
            .map(BlockcypherAddressResponse.self)
            .map { addressResponse -> Int in
                var sigCount = addressResponse.txrefs?.filter { $0.tx_output_n == -1 }.count ?? 0
                sigCount += addressResponse.unconfirmed_txrefs?.filter { $0.tx_output_n == -1 }.count ?? 0
                return sigCount
            }
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    private func publisher(for target: BlockcypherTarget) -> AnyPublisher<Response, MoyaError> {
        Just(())
            .setFailureType(to: MoyaError.self)
            .flatMap { [unowned self] in
                self.provider
                    .requestPublisher(target)
                    .filterSuccessfulStatusAndRedirectCodes()
            }
            .catch { [unowned self] error -> AnyPublisher<Response, MoyaError> in
                self.changeToken(error)
                return Fail(error: error).eraseToAnyPublisher()
            }
            .retry(1)
            .eraseToAnyPublisher()
    }
    
    private func getRandomToken() -> String? {
        guard tokens.count > 0 else { return nil }
        
        let tokenIndex = Int.random(in: 0..<tokens.count)
        return tokens[tokenIndex]
    }
    
    private func changeToken(_ error: MoyaError) {
        if case let MoyaError.statusCode(response) = error, response.statusCode == 429 {
            token = getRandomToken()
        }
    }
}
