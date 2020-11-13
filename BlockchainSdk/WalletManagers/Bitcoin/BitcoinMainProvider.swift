//
//  BitcoinMainProvider.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 20.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine

class BitcoinMainProvider: BitcoinNetworkProvider {
    let blockchainInfoProvider = MoyaProvider<BlockchainInfoTarget>(plugins: [NetworkLoggerPlugin()])
    //let estimateFeeProvider = MoyaProvider<EstimateFeeTarget>(plugins: [NetworkLoggerPlugin()])
    //let bitcoinfeesProvider = MoyaProvider<BitcoinfeesTarget>(plugins: [NetworkLoggerPlugin()])
    let feeProvider = MoyaProvider<BlockchainInfoApiTarget>(plugins: [NetworkLoggerPlugin()])
    
    let address: String
    
    init(address: String) {
        self.address = address
    }
    
    func getInfo() -> AnyPublisher<BitcoinResponse, Error> {
        return addressData(address)
            .tryMap {(addressResponse, unspentsResponse) throws -> BitcoinResponse in
                guard let balance = addressResponse.final_balance,
                    let txs = addressResponse.txs else {
                        throw WalletError.failedToGetFee
                }
                
                let utxs: [BtcTx] = unspentsResponse.unspent_outputs?.compactMap { utxo -> BtcTx?  in
                    guard let hash = utxo.tx_hash_big_endian,
                        let n = utxo.tx_output_n,
                        let val = utxo.value else {
                            return nil
                    }
                    
                    let btx = BtcTx(tx_hash: hash, tx_output_n: n, value: val)
                    return btx
                    } ?? []
                
                let satoshiBalance = Decimal(balance)/Decimal(100000000)
                let hasUnconfirmed = txs.first(where: {$0.block_height == nil}) != nil
                return BitcoinResponse(balance: satoshiBalance, hasUnconfirmed: hasUnconfirmed, txrefs: utxs)
        }
           .eraseToAnyPublisher()
    }
    
//    func getFee() -> AnyPublisher<BtcFee, Error> {
//        return bitcoinfeesProvider.requestPublisher(.fees)
//            .filterSuccessfulStatusAndRedirectCodes()
//            .map(BitcoinfeesResponse.self)
//            .tryMap { response throws -> BtcFee in
//                let min = Decimal(response.hourFee)
//                let normal = Decimal(response.halfHourFee)
//                let priority = Decimal(response.fastestFee)
//
//                let kb = Decimal(1024)
//                let btcSatoshi = Decimal(100000000)
//                let minKbValue = min * kb / btcSatoshi
//                let normalKbValue = normal * kb / btcSatoshi
//                let maxKbValue = priority * kb / btcSatoshi
//
//                return BtcFee(minimalKb: minKbValue, normalKb: normalKbValue, priorityKb: maxKbValue)
//        }
//        .eraseToAnyPublisher()
//    }
    
    func getFee() -> AnyPublisher<BtcFee, Error> {
        return feeProvider.requestPublisher(.fees)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(BlockchainInfoApiResponse.self)
            .tryMap { response throws -> BtcFee in
                let min = Decimal(response.regular)
                let normal = Decimal(response.regular) * Decimal(1.2)
                let priority = Decimal(response.priority)
                
                let kb = Decimal(1024)
                let btcSatoshi = Decimal(100000000)
                let convertValue = kb / btcSatoshi
                
                let minKbValue = min * convertValue
                let normalKbValue = normal * convertValue
                let maxKbValue = priority * convertValue
                
                return BtcFee(minimalKb: minKbValue, normalKb: normalKbValue, priorityKb: maxKbValue)
        }
        .eraseToAnyPublisher()
    }
    
//    @available(iOS 13.0, *)
//    func getFee() -> AnyPublisher<BtcFee, Error> {
//        return Publishers.Zip3(estimateFeeProvider.requestPublisher(.minimal).filterSuccessfulStatusAndRedirectCodes().mapString(),
//                               estimateFeeProvider.requestPublisher(.normal).filterSuccessfulStatusAndRedirectCodes().mapString(),
//                               estimateFeeProvider.requestPublisher(.priority).filterSuccessfulStatusAndRedirectCodes().mapString())
//            .tryMap { response throws -> BtcFee in
//                guard let min = Decimal(response.0),
//                    let normal = Decimal(response.1),
//                    let priority = Decimal(response.2) else {
//                        throw "Fee request error"
//                }
//
//                return BtcFee(minimalKb: min, normalKb: normal, priorityKb: priority)
//        }
//        .eraseToAnyPublisher()
//    }
    
    @available(iOS 13.0, *)
    func send(transaction: String) -> AnyPublisher<String, Error> {
        return blockchainInfoProvider.requestPublisher(.send(txHex: transaction))
        .filterSuccessfulStatusAndRedirectCodes()
        .mapNotEmptyString()
        .eraseError()
        .eraseToAnyPublisher()
    }
    
    private func addressData(_ address: String) -> AnyPublisher<(BlockchainInfoAddressResponse, BlockchainInfoUnspentResponse), Error> {
        return Publishers.Zip(
            blockchainInfoProvider
                .requestPublisher(.address(address: address))
                .filterSuccessfulStatusAndRedirectCodes()
                .map(BlockchainInfoAddressResponse.self)
                .eraseError(),
        
            blockchainInfoProvider
                .requestPublisher(.unspents(address: address))
                .filterSuccessfulStatusAndRedirectCodes()
                .map(BlockchainInfoUnspentResponse.self)
                .tryCatch { error -> AnyPublisher<BlockchainInfoUnspentResponse, Error> in
                    if case let MoyaError.statusCode (response) = error {
                        let stringError = try response.mapString()
                        if stringError == "No free outputs to spend" {
                            return Just(BlockchainInfoUnspentResponse(unspent_outputs: []))
                                .setFailureType(to: Error.self)
                                .eraseToAnyPublisher()
                        } else {
                            throw stringError
                        }
                    } else {
                       throw error
                    }
            })
                .eraseToAnyPublisher()
    }
}
