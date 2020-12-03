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
    
    private let endpoint: BlockchairEndpoint
    
    init(endpoint: BlockchairEndpoint) {
        self.endpoint = endpoint
    }
    
	func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
		publisher(for: .address(address: address, endpoint: endpoint, transactionDetails: true))
            .tryMap { [unowned self] json -> BitcoinResponse in
                let data = json["data"]
                let addr = data["\(address)"]
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
                
                
                let decimalBtcBalance = decimalSatoshiBalance / self.endpoint.blockchain.decimalValue
                let bitcoinResponse = BitcoinResponse(balance: decimalBtcBalance, hasUnconfirmed: hasUnconfirmed, txrefs: utxs)
                
                return bitcoinResponse
        }
        .eraseToAnyPublisher()
    }
    
    func getFee() -> AnyPublisher<BtcFee, Error> {
		publisher(for: .fee(endpoint: endpoint))
            .tryMap { [unowned self] json throws -> BtcFee in
                let data = json["data"]
                guard let feePerByteSatoshi = data["suggested_transaction_fee_per_byte_sat"].int  else {
                    throw WalletError.failedToGetFee
                }
                
                let normal = (Decimal(1024) * Decimal(feePerByteSatoshi) / self.endpoint.blockchain.decimalValue)
                let min = (Decimal(0.8) * normal).rounded(blockchain: self.endpoint.blockchain)
                let max = (Decimal(1.2) * normal).rounded(blockchain: self.endpoint.blockchain)
                
                let fee = BtcFee(minimalKb: min,
                                 normalKb: normal.rounded(blockchain: self.endpoint.blockchain),
                                 priorityKb: max)
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
				let addr = json["data"]["\(address)"]
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
			.requestPublisher(target)
			.filterSuccessfulStatusAndRedirectCodes()
			.mapSwiftyJSON()
	}
}
