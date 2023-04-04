//
//  RavencoinNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 03.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine

//  https://api.ravencoin.org/api/tx/send
// {"rawtx":"01000000012b603f806074f8cf8099e5edf0fa2a5f9eb1fccfc817d480477219f6caf33090020000006b483045022100d7a4901f7becdf84651aae71f3ba5c22b022128b52f7fa41dab37b531fd838f402200864add69f0fe851102f06640debb3dd31a78f8cae565f4e773854ccdd5b8c07012102677dd71d01665229de974005670618568b83f6b1e0809aabb99b1646bdc660bb000000000210270000000000001976a914041c20c9f7d7e16cb2813da977bc9901a8e7d0d688ac2acff105000000001976a9147775253a54f9873fe3065877a423e4191057d8b988ac00000000"}

/*
 // https://api.ravencoin.org/api/addrs/RLAppkUmJsgdQ7Khb7ZfL8JG14kaWzjFhK/utxo
 // https://ravencoin.network/api/addrs/RLAppkUmJsgdQ7Khb7ZfL8JG14kaWzjFhK/utxo
 [
    {
       "address":"RLAppkUmJsgdQ7Khb7ZfL8JG14kaWzjFhK",
       "txid":"9030f3caf619724780d417c8cffcb19e5f2afaf0ede59980cff87460803f602b",
       "vout":2,
       "scriptPubKey":"76a9147775253a54f9873fe3065877a423e4191057d8b988ac",
       "assetName":"RVN",
       "amount":1,
       "satoshis":100000000,
       "height":2497664,
       "confirmations":243161
    }
 ]
 
 // https://blockbook.ravencoin.org/api/address/RLAppkUmJsgdQ7Khb7ZfL8JG14kaWzjFhK
 {
    "page":1,
    "totalPages":1,
    "itemsOnPage":1000,
    "addrStr":"RLAppkUmJsgdQ7Khb7ZfL8JG14kaWzjFhK",
    "balance":"0.9973329",
    "totalReceived":"1.9973329",
    "totalSent":"1",
    "unconfirmedBalance":"0",
    "unconfirmedTxApperances":0,
    "txApperances":2,
    "transactions":[
       "ab785ff58d813a0e1c3a19727c6b00b6773c3bcc6e3561c0da313ebdfa3e4a0a",
       "9030f3caf619724780d417c8cffcb19e5f2afaf0ede59980cff87460803f602b"
    ]
 }
 
 // https://blockbook.ravencoin.org/api/address/RLAppkUmJsgdQ7Khb7ZfL8JG14kaWzjFhK/utxo
 
 // https://blockbook.ravencoin.org/api/address/RLAppkUmJsgdQ7Khb7ZfL8JG14kaWzjFhK
 {
    "blockbook":{
       "coin":"Ravencoin",
       "host":"ravencoin",
       "version":"0.3.6",
       "gitCommit":"f9d5cd3",
       "buildTime":"2023-01-14T20:57:40+00:00",
       "syncMode":true,
       "initialSync":false,
       "inSync":true,
       "bestHeight":2740873,
       "lastBlockTime":"2023-04-04T06:25:27.479735269-06:00",
       "inSyncMempool":true,
       "lastMempoolTime":"2023-04-04T06:25:44.372612292-06:00",
       "mempoolSize":1,
       "decimals":8,
       "dbSize":29842696418,
       "about":"Blockbook - blockchain indexer for Trezor wallet https://trezor.io/. Do not use for any other purpose."
    },
    "backend":{
       "chain":"main",
       "blocks":2740873,
       "headers":2740873,
       "bestBlockHash":"000000000000374e99a1235da53f957b111231911ac072d81c988b55ab0eee7c",
       "difficulty":"105916.1963008631",
       "sizeOnDisk":33559104633,
       "version":"4020100",
       "subversion":"/Ravencoin:4.2.1/",
       "protocolVersion":"70028",
       "warnings":"Warning: unknown new rules activated (versionbit 10) "
    }
 }
 
curl 'https://ravencoin.network/v1/raven/address/R9evUf3dCSfzdjuRJgvBxAnjA7TPjDYjPo/utxo' \
 -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15'
-X 'GET' \
-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15'
{"apiVersion":"1","status":{"code":200,"message":"OK"},"data":{"items":[{"rvnAddress":"R9evUf3dCSfzdjuRJgvBxAnjA7TPjDYjPo","totalReceived":900000000,"totalReceivedDisplayValue":"9","totalSent":0,"totalSentDisplayValue":"0","finalBalance":900000000,"finalBalanceDisplayValue":"9","txCount":1,"blockHash":"00000000000015ca462a0bc9b53a7e5e1fe81ef3e03987096445f26f040497af","blockHeight":2500370}]}}%
*/

class RavencoinNetworkProvider {
    let provider: NetworkProvider<RavencoinTarget>
    
    init(configuration: NetworkProviderConfiguration) {
        provider = NetworkProvider<RavencoinTarget>(configuration: configuration)
    }
}

// MARK: - BitcoinNetworkProvider

extension RavencoinNetworkProvider: BitcoinNetworkProvider {
    var host: String {
        RavencoinTarget.wallet(address: "").baseURL.absoluteString
    }
    
    var supportsTransactionPush: Bool { false }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        Publishers.CombineLatest(
            getWalletInfo(address: address),
            getUTXO(address: address)
        ).map { rvnWalletModel, rvnUTXO -> BitcoinResponse in
            let unspentOutputs = rvnUTXO.map { utxo in
                BitcoinUnspentOutput(transactionHash: utxo.txid,
                                     outputIndex: utxo.vout,
                                     amount: UInt64(utxo.satoshis),
                                     outputScript: utxo.scriptPubKey)
            }
            
            return BitcoinResponse(
                    balance: rvnWalletModel.balance ?? 0,
                    hasUnconfirmed: rvnWalletModel.unconfirmedTxApperances != 0,
                    pendingTxRefs: [],
                    unspentOutputs: unspentOutputs
                )
            }
        .eraseToAnyPublisher()
    }
    
    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        let perKilobyte: Decimal = 1018385
        let perByte = perKilobyte / 1024
        return .justWithError(output: BitcoinFee(minimalSatoshiPerByte: perByte, normalSatoshiPerByte: perByte, prioritySatoshiPerByte: perByte))
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        sendTransaction(raw: RavencoinRawTransactionRequestModel(rawtx: transaction))
            .map { transaction }
            .eraseToAnyPublisher()
    }
    
    func push(transaction: String) -> AnyPublisher<String, Error> {
        .anyFail(error: BlockchainSdkError.networkProvidersNotSupportsRbf)
    }
    
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        .anyFail(error: BlockchainSdkError.notImplemented)
    }
}


// MARK: - RavencoinNetworkProvider

private extension RavencoinNetworkProvider {
    func getWalletInfo(address: String) -> AnyPublisher<RavencoinWalletInfo, Error> {
        provider
            .requestPublisher(.wallet(address: address))
            .map(RavencoinWalletInfo.self)
            .eraseError()
    }
    
    func getUTXO(address: String) -> AnyPublisher<[RavencoinWalletUTXO], Error> {
        provider
            .requestPublisher(.utxo(address: address))
            .map([RavencoinWalletUTXO].self)
            .eraseError()
    }
    
    func getTxInfo(transactionId: String) -> AnyPublisher<RavencoinTransactionInfo, Error> {
        provider
            .requestPublisher(.transaction(id: transactionId))
            .map(RavencoinTransactionInfo.self)
            .eraseError()
    }
    
    func sendTransaction(raw: RavencoinRawTransactionRequestModel) -> AnyPublisher<Void, Error> {
        provider
            .requestPublisher(.sendTransaction(raw: raw))
            .map { _ in Void() }
            .eraseToAnyPublisher()
            .eraseError()
    }
}
