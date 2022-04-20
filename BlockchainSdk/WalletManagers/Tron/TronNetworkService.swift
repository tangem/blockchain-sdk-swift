//
//  TronNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 24.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BigInt
import web3swift

class TronNetworkService {
    private let rpcProvider: TronJsonRpcProvider
    
    init(rpcProvider: TronJsonRpcProvider) {
        self.rpcProvider = rpcProvider
    }
    
    func getAccount(for address: String) -> AnyPublisher<TronGetAccountResponse, Error> {
        rpcProvider.getAccount(for: address)
    }
    
    func createTransaction(from source: String, to destination: String, amount: UInt64) -> AnyPublisher<TronTransactionRequest, Error> {
        rpcProvider.createTransaction(from: source, to: destination, amount: amount)
    }
    
    func broadcastTransaction(_ transaction: TronTransactionRequest) -> AnyPublisher<TronBroadcastResponse, Error> {
        rpcProvider.broadcastTransaction(transaction)
    }
    
    func tokenBalance(address: String, token: Token) -> AnyPublisher<Decimal, Error> {
        rpcProvider.tokenBalance(address: address, contractAddress: token.contractAddress)
            .tryMap { response in
                guard let hexValue = response.constant_result.first else {
                    throw WalletError.failedToParseNetworkResponse
                }
                
                let bigIntValue = BigUInt(Data(hex: hexValue))
                
                let formatted = Web3.Utils.formatToPrecision(
                    bigIntValue,
                    numberDecimals: token.decimalCount,
                    formattingDecimals: token.decimalCount,
                    decimalSeparator: ".",
                    fallbackToScientific: false
                )
                
                guard let decimalValue = Decimal(formatted) else {
                    throw WalletError.failedToParseNetworkResponse
                }

                return decimalValue
            }
            .eraseToAnyPublisher()
    }
}
