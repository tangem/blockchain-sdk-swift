//
//  KoinosMethod.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 27.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum KoinosMethod {}

extension KoinosMethod {
    enum ReadContract {
        struct RequestParams: Encodable {
            let contractId: String
            let entryPoint: Int
            let args: String
        }
        
        struct Response: Decodable {
            let result: String?
        }
    }
}

extension KoinosMethod {
    enum GetAccountRC {
        struct RequestParams: Encodable {
            let account: String
        }
        
        struct Response: Decodable {
            let rc: UInt64
        }
    }
}

extension KoinosMethod {
    enum GetAccountNonce {
        struct RequestParams: Encodable {
            let account: String
        }
        
        struct Response: Decodable {
            let nonce: UInt64
            
            init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let base64EncodedNonce: String = try container.decode(forKey: .nonce)
                guard let stringNonce = base64EncodedNonce.base64Decoded(),
                      let nonce = UInt64(stringNonce)
                else {
                    throw WalletError.failedToParseNetworkResponse
                }
                self.nonce = nonce
            }
            
            enum CodingKeys: String, CodingKey {
                case nonce
            }
        }
    }
}

extension KoinosMethod {
    enum GetResourceLimits {
        struct Response: Decodable {
            let resourceLimitData: KoinosChain.ResourceLimitData
        }
    }
}

extension KoinosMethod {
    enum SubmitTransaction {
        struct RequestParams: Encodable {
            let transaction: KoinosProtocol.Transaction
            let broadcast: Bool
        }
        
        struct Response: Decodable {
            let receipt: KoinosProtocol.TransactionReceipt
        }
    }
    
}
