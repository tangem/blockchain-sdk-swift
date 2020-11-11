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
    let address: String
    let chain: BlockcypherChain
    let coin: BlockcypherCoin
    
    private var token: String? = nil
    
    init(address: String, coin: BlockcypherCoin, chain: BlockcypherChain) {
        self.address = address
        self.coin = coin
        self.chain = chain
    }
    
    
	func getInfo() -> AnyPublisher<BitcoinResponse, Error> {
		publisher(for: BlockcypherTarget(coin: self.coin, chain: self.chain, token: self.token, targetType: .address(address: self.address, limit: nil)))
			.map(BlockcypherAddressResponse.self)
			.tryMap {addressResponse -> BitcoinResponse in
				guard let balance = addressResponse.balance,
					  let uncBalance = addressResponse.unconfirmed_balance
				else {
					throw WalletError.failedToParseNetworkResponse
				}
				
				let satoshiBalance = Decimal(balance)/Decimal(100000000)
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
	
    func getFee() -> AnyPublisher<BtcFee, Error> {
		publisher(for: BlockcypherTarget(coin: self.coin, chain: self.chain, token: self.token, targetType: .fee))
			.map(BlockcypherFeeResponse.self)
			.tryMap { feeResponse -> BtcFee in
				guard let minKb = feeResponse.low_fee_per_kb,
					  let normalKb = feeResponse.medium_fee_per_kb,
					  let maxKb = feeResponse.high_fee_per_kb else {
					throw "Can't load fee"
				}
				
				let minKbValue = Decimal(minKb)/Decimal(100000000)
				let normalKbValue = Decimal(normalKb)/Decimal(100000000)
				let maxKbValue = Decimal(maxKb)/Decimal(100000000)
				let fee = BtcFee(minimalKb: minKbValue, normalKb: normalKbValue, priorityKb: maxKbValue)
				return fee
			}
			.eraseToAnyPublisher()
	}
	
	func send(transaction: String) -> AnyPublisher<String, Error> {
        publisher(for: BlockcypherTarget(coin: self.coin, chain: self.chain, token: self.token ?? self.getRandomToken(), targetType: .send(txHex: transaction)))
			.mapNotEmptyString()
			.eraseError()
			.eraseToAnyPublisher()
	}
    
    func getTx(hash: String) -> AnyPublisher<BlockcypherTx, Error> {
		publisher(for: BlockcypherTarget(coin: self.coin, chain: self.chain, token: self.token, targetType: .txs(txHash: hash)))
			.map(BlockcypherTx.self)
			.eraseError()
    }
	
	func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
		publisher(for: BlockcypherTarget(coin: self.coin, chain: self.chain, token: self.token, targetType: .address(address: self.address, limit: 2000)))
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
