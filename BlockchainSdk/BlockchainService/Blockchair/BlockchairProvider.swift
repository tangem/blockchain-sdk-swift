//
//  BlockchairProvider.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 14.02.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import TangemSdk
import Alamofire
import SwiftyJSON

class BlockchairProvider: BitcoinNetworkProvider {
    let provider = MoyaProvider<BlockchairTarget>()
    
    let address: String
    let endpoint: BlockchairEndpoint
    
    init(address: String, endpoint: BlockchairEndpoint) {
        self.address = address
        self.endpoint = endpoint
    }
    
    func getInfo() -> AnyPublisher<BitcoinResponse, Error> {
		publisher(for: .address(address: address, endpoint: endpoint, transactionDetails: true))
            .tryMap { [unowned self] json -> BitcoinResponse in
                let data = json["data"]
                let addr = data["\(self.address)"]
                let address = addr["address"]
                let balance = address["balance"].stringValue
                
                guard let decimalSatoshiBalance = Decimal(string: balance) else {
                    throw WalletError.failedToParseNetworkResponse
                }
                
                guard let transactionsData = try? addr["transactions"].rawData(),
                    let transactions: [BlockchairTransaction] = try? JSONDecoder().decode([BlockchairTransaction].self, from: transactionsData) else {
                        throw WalletError.failedToParseNetworkResponse
                }
                
                guard let utxoData = try? addr["utxo"].rawData(),
                    let utxos: [BlockchairUtxo] = try? JSONDecoder().decode([BlockchairUtxo].self, from: utxoData) else {
                        throw WalletError.failedToParseNetworkResponse
                }
                
                let utxs: [BtcTx] = utxos.compactMap { utxo -> BtcTx?  in
                    guard let hash = utxo.transaction_hash,
                        let n = utxo.index,
                        let val = utxo.value else {
                            return nil
                    }
                    
                    let btx = BtcTx(tx_hash: hash, tx_output_n: n, value: val)
                    return btx
                }
                
                let hasUnconfirmed = transactions.first(where: {$0.block_id == -1 || $0.block_id == 1 }) != nil
                
                
                let decimalBtcBalance = decimalSatoshiBalance/Decimal(100000000)
                let bitcoinResponse = BitcoinResponse(balance: decimalBtcBalance, hasUnconfirmed: hasUnconfirmed, txrefs: utxs)
                
                return bitcoinResponse
        }
        .eraseToAnyPublisher()
    }
    
    func getFee() -> AnyPublisher<BtcFee, Error> {
		publisher(for: .fee(endpoint: endpoint))
            .tryMap { json throws -> BtcFee in
                let data = json["data"]
                guard let feePerByteSatoshi = data["suggested_transaction_fee_per_byte_sat"].int  else {
                    throw WalletError.failedToGetFee
                }
                
                let feeKbValue = Decimal(1024) * Decimal(feePerByteSatoshi) / Decimal(100000000)
                let fee = BtcFee(minimalKb: feeKbValue, normalKb: feeKbValue, priorityKb: feeKbValue)
                return fee
        }
        .eraseToAnyPublisher()
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
		publisher(for: .send(txHex: transaction, endpoint: endpoint))
            .tryMap { json throws -> String in
                let data = json["data"]
                
                guard let hash = data["transaction_hash"].string else {
                    throw WalletError.failedToParseNetworkResponse
                }
                
               return hash
        }
        .eraseToAnyPublisher()
    }
	
	func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
		publisher(for: .address(address: address, endpoint: endpoint, transactionDetails: false))
			.map { json -> Int in
				let addr = json["\(address)"]
				let address = addr["address"]
				
				guard
					let outputCount = address["output_count"].int,
					let unspentOutputCounr = address["unspent_output_count"].int
				else { return 0 }
				
				return outputCount - unspentOutputCounr
			}
			.mapError { $0 as Error }
			.eraseToAnyPublisher()
	}
	
	private func publisher(for target: BlockchairTarget) -> AnyPublisher<JSON, MoyaError> {
		provider
			.requestPublisher(.address(address: address, endpoint: endpoint, transactionDetails: true))
			.filterSuccessfulStatusAndRedirectCodes()
			.mapSwiftyJSON()
	}
}
