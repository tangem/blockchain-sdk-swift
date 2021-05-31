//
//  BlockcypherNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 20.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import BitcoinCore

class BlockcypherNetworkProvider: BitcoinNetworkProvider {
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
    
    var canPushTransaction: Bool {
        false
    }
    
    var host: String {
        getTarget(for: .fee).baseURL.hostOrUnknown
    }
    
    init(endpoint: BlockcypherEndpoint, tokens: [String]) {
        self.endpoint = endpoint
        self.tokens = tokens
    }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        getFullInfo(address: address)
            .tryMap {[unowned self] (addressResponse: BlockcypherFullAddressResponse<BlockcypherBitcoinTx>) -> BitcoinResponse in
                guard let balance = addressResponse.balance,
                      let uncBalance = addressResponse.unconfirmedBalance
                else {
                    throw WalletError.failedToParseNetworkResponse
                }
                
                let satoshiBalance = Decimal(balance) / self.endpoint.blockchain.decimalValue
                
                var utxo: [BitcoinUnspentOutput] = []
                var pendingTxRefs: [PendingTransaction] = []
                
                addressResponse.txs?.forEach { tx in
                    if tx.blockIndex == -1 {
                        let pendingTx = tx.pendingTx(for: address, decimalValue: self.endpoint.blockchain.decimalValue)
                        pendingTxRefs.append(pendingTx)
                    } else {
                        guard let btcTx = tx.btcTx(for: address) else { return }

                        utxo.append(btcTx)
                    }
                }
                
                for (index, tx) in pendingTxRefs.enumerated() {
                    guard tx.sequence == SequenceValues.baseTx.rawValue else { continue }
                    
                    if tx.isAlreadyRbf { continue }
                    
                    pendingTxRefs[index].isAlreadyRbf = pendingTxRefs.contains(where: {
                        tx.source == $0.source &&
                            tx.destination == $0.destination &&
                            tx.value == $0.value &&
                            tx.fee ?? 0 < $0.fee ?? 0 &&
                            tx.sequence < $0.sequence
                    })
                }
                
                if Decimal(uncBalance) / self.endpoint.blockchain.decimalValue != pendingTxRefs.reduce(0, { $0 + $1.value }) {
                    print("Unconfirmed balance and pending tx refs sum is not equal")
                }
                let btcResponse = BitcoinResponse(balance: satoshiBalance, hasUnconfirmed: pendingTxRefs.count > 0, pendingTxRefs: pendingTxRefs, unspentOutputs: utxo)

                
//                let satoshiBalance = Decimal(balance)/self.endpoint.blockchain.decimalValue
//                let txs: [BitcoinUnspentOutput] = addressResponse.txrefs?.compactMap { utxo -> BitcoinUnspentOutput?  in
//                    guard let hash = utxo.tx_hash,
//                          let n = utxo.tx_output_n,
//                          let val = utxo.value,
//                          let script = utxo.script else {
//                        return nil
//                    }
//
//                    let btx = BitcoinUnspentOutput(transactionHash: hash, outputIndex: n, amount: UInt64(val), outputScript: script)
//                    return btx
//                } ?? []
//
//                let btcResponse = BitcoinResponse(balance: satoshiBalance, hasUnconfirmed:  uncBalance != 0, unspentOutputs: txs)
                return btcResponse
            }
            .eraseToAnyPublisher()
    }
    
    
    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        return Just(())
            .setFailureType(to: MoyaError.self)
            .flatMap { [unowned self] in
                self.provider
                    .requestPublisher(getTarget(for: .fee))
                    .filterSuccessfulStatusAndRedirectCodes()
            }
            .catch{[unowned self] error -> AnyPublisher<Response, MoyaError> in
                self.changeToken(error)
                return Fail(error: error).eraseToAnyPublisher()
            }
            .retry(1)
            .eraseToAnyPublisher()
            .map(BlockcypherFeeResponse.self)
            .tryMap { feeResponse -> BitcoinFee in
                guard let minKb = feeResponse.low_fee_per_kb,
                      let normalKb = feeResponse.medium_fee_per_kb,
                      let maxKb = feeResponse.high_fee_per_kb else {
                    throw "Can't load fee"
                }
                let kb = Decimal(1024)
                let min = (Decimal(minKb)/kb).rounded(roundingMode: .down)
                let normal = (Decimal(normalKb)/kb).rounded(roundingMode: .down)
                let max = (Decimal(maxKb)/kb).rounded(roundingMode: .down)
                let fee = BitcoinFee(minimalSatoshiPerByte: min, normalSatoshiPerByte: normal, prioritySatoshiPerByte: max)
                return fee
            }
            .eraseToAnyPublisher()
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        return Just(())
            .setFailureType(to: MoyaError.self)
            .flatMap { [unowned self] in
                self.provider.requestPublisher(getTarget(for: .send(txHex: transaction), withRandomToken: true))
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
    

    func push(transaction: String) -> AnyPublisher<String, Error> {
        Fail(error: NetworkServiceError.notAvailable)
            .eraseToAnyPublisher()
    }

//    func getTx(hash: String) -> AnyPublisher<BlockcypherTx, Error> {
//        publisher(for: getTarget(for: .txs(txHash: hash)))
//            .map(BlockcypherTx.self)
//            .eraseError()
//    }

    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        publisher(for: getTarget(for: .address(address: address, unspentsOnly: false, limit: 2000, isFull: false)))
            .map(BlockcypherAddressResponse.self)
            .map { addressResponse -> Int in
                var sigCount = addressResponse.txrefs?.filter { $0.tx_output_n == -1 }.count ?? 0
                sigCount += addressResponse.unconfirmed_txrefs?.filter { $0.tx_output_n == -1 }.count ?? 0
                return sigCount
            }
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    

    private func getFullInfo<Tx: Codable>(address: String) -> AnyPublisher<BlockcypherFullAddressResponse<Tx>, MoyaError> {
        publisher(for: BlockcypherTarget(endpoint: self.endpoint, token: self.token, targetType: .address(address: address, unspentsOnly: true, limit: 30, isFull: true)))
            .map(BlockcypherFullAddressResponse<Tx>.self, using: jsonDecoder)
    }

    private func getTarget(for type: BlockcypherTarget.BlockcypherTargetType, withRandomToken: Bool = false) -> BlockcypherTarget {
        .init(endpoint: endpoint, token: withRandomToken ? token ?? getRandomToken() : token, targetType: type)
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

extension BlockcypherNetworkProvider: EthereumAdditionalInfoProvider {
    func getEthTxsInfo(address: String) -> AnyPublisher<EthereumTransactionResponse, Error> {
        getFullInfo(address: address)
            .tryMap { [unowned self] (response: BlockcypherFullAddressResponse<BlockcypherEthereumTransaction>) -> EthereumTransactionResponse in
                guard let balance = response.balance else {
                    throw WalletError.failedToParseNetworkResponse
                }
                
                let ethBalance = Decimal(balance) / self.endpoint.blockchain.decimalValue
                var pendingTxs: [PendingTransaction] = []
                
                var croppedAddress = address
                if croppedAddress.starts(with: "0x") {
                    croppedAddress.removeFirst(2)
                }
                croppedAddress = croppedAddress.lowercased()
                
                response.txs?.forEach { tx in
                    guard tx.blockHeight == -1 else { return }
                    
                    var pendingTx = tx.pendingTx(for: croppedAddress, decimalValue: self.endpoint.blockchain.decimalValue)
                    if pendingTx.source == croppedAddress {
                        pendingTx.source = address
                        pendingTx.destination = "0x" + pendingTx.destination
                    } else if pendingTx.destination == croppedAddress {
                        pendingTx.destination = address
                        pendingTx.source = "0x" + pendingTx.source
                    }
                    pendingTxs.append(pendingTx)
               }
                
                let ethResp = EthereumTransactionResponse(balance: ethBalance, pendingTxs: pendingTxs)
                return ethResp
            }
            .eraseToAnyPublisher()
        
    }
}
