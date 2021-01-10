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
    private let apiKey: String
    
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(DateFormatter(withFormat: "YYYY-MM-dd HH:mm:ss", locale: "en_US"))
        return decoder
    }()
    
    init(endpoint: BlockchairEndpoint, apiKey: String) {
        self.endpoint = endpoint
        self.apiKey = apiKey
    }
    
	func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        publisher(for: .address(address: address, endpoint: endpoint, transactionDetails: true, apiKey: apiKey))
            .tryMap { [unowned self] json -> (BitcoinResponse, [BlockchairTransactionShort]) in //TODO: refactor to normal JSON
                let data = json["data"]
                let addr = data["\(address)"]
                let address = addr["address"]
                let balance = address["balance"].stringValue
                let script = address["script_hex"].stringValue
                
                guard let decimalSatoshiBalance = Decimal(string: balance) else {
                    throw WalletError.failedToParseNetworkResponse
                }
                
                guard let transactionsData = try? addr["transactions"].rawData(),
                      let transactions: [BlockchairTransactionShort] = try? self.jsonDecoder.decode([BlockchairTransactionShort].self, from: transactionsData) else {
                        throw WalletError.failedToParseNetworkResponse
                }
                
                guard let utxoData = try? addr["utxo"].rawData(),
                      let utxos: [BlockchairUtxo] = try? self.jsonDecoder.decode([BlockchairUtxo].self, from: utxoData) else {
                        throw WalletError.failedToParseNetworkResponse
                }
                
                let utxs: [BtcTx] = utxos.compactMap { utxo -> BtcTx?  in
                    guard let hash = utxo.transactionHash,
                        let n = utxo.index,
                        let val = utxo.value else {
                            return nil
                    }
                    
                    let btx = BtcTx(tx_hash: hash, tx_output_n: n, value: val, script: script)
                    return btx
                }
                
                let pendingTxs = transactions.filter { $0.blockId == -1 || $0.blockId == 1 }
                let hasUnconfirmed = pendingTxs.count != 0
                
                let decimalBtcBalance = decimalSatoshiBalance / self.endpoint.blockchain.decimalValue
                let bitcoinResponse = BitcoinResponse(balance: decimalBtcBalance, hasUnconfirmed: hasUnconfirmed, txrefs: utxs, pendingTxRefs: [])
                
                return (bitcoinResponse, pendingTxs)
            }
            .flatMap { [unowned self] (resp: (BitcoinResponse, [BlockchairTransactionShort])) -> AnyPublisher<BitcoinResponse, Error> in
                guard resp.1.count > 0 else {
                    return Just(resp.0)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                
                let hashes = resp.1.map { $0.hash }
                return publisher(for: .txsDetails(hashes: hashes, endpoint: self.endpoint, apiKey: self.apiKey))
                    .tryMap { [unowned self] json -> BitcoinResponse in
                        let data = json["data"]
                        let txsData = hashes.map {
                            data[$0]
                        }
                        
                        let txs = try txsData.map {
                            getTransactionDetails(from: $0)
                        }
                        
                        let pendingBtcTxs: [PendingBtcTx] = txs.compactMap {
                            guard let tx = $0 else { return nil }
                            
                            return tx.pendingBtxTx(sourceAddress: address, decimalValue: self.endpoint.blockchain.decimalValue)
                        }
                        
                        let oldResp = resp.0
                        return BitcoinResponse(balance: oldResp.balance, hasUnconfirmed: oldResp.hasUnconfirmed, txrefs: oldResp.txrefs, pendingTxRefs: pendingBtcTxs)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func getFee() -> AnyPublisher<BtcFee, Error> {
		publisher(for: .fee(endpoint: endpoint, apiKey: apiKey))
            .tryMap { json throws -> BtcFee in
                let data = json["data"]
                guard let feePerByteSatoshi = data["suggested_transaction_fee_per_byte_sat"].int  else {
                    throw WalletError.failedToGetFee
                }
                
                let normal = Decimal(feePerByteSatoshi)
                let min = (Decimal(0.8) * normal).rounded(roundingMode: .down)
                let max = (Decimal(1.2) * normal).rounded(roundingMode: .down)

                let fee = BtcFee(minimalSatoshiPerByte: min,
                                 normalSatoshiPerByte: normal,
                                 prioritySatoshiPerByte: max)
                return fee
        }
        .eraseToAnyPublisher()
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
		publisher(for: .send(txHex: transaction, endpoint: endpoint, apiKey: apiKey))
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
		publisher(for: .address(address: address, endpoint: endpoint, transactionDetails: false, apiKey: apiKey))
			.map { json -> Int in
				let addr = json["data"]["\(address)"]
				let address = addr["address"]
				
				guard
					let outputCount = address["output_count"].int,
					let unspentOutputCount = address["unspent_output_count"].int
				else { return 0 }
				
				return outputCount - unspentOutputCount
			}
			.mapError { $0 as Error }
			.eraseToAnyPublisher()
	}
    
    func getTransactionInfo(hash: String, address: String) -> AnyPublisher<PendingBtcTx, Error> {
        publisher(for: .txDetails(txHash: hash, endpoint: endpoint, apiKey: apiKey))
            .tryMap { [unowned self] json -> PendingBtcTx in
                let txJson = json["data"]["\(hash)"]
                
                guard let tx = self.getTransactionDetails(from: txJson) else {
                    throw WalletError.failedToParseNetworkResponse
                }
                
                return tx.pendingBtxTx(sourceAddress: address, decimalValue: self.endpoint.blockchain.decimalValue)
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
    
    private func getTransactionDetails(from json: JSON) -> BlockchairTransactionDetailed? {
        guard let txData = try? json.rawData(),
              let tx = try? self.jsonDecoder.decode(BlockchairTransactionDetailed.self, from: txData)
        else { return nil }
        
        return tx
    }
}
