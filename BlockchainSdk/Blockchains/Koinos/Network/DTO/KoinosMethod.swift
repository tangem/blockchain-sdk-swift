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
        static let method = "chain.read_contract"
        
        struct RequestParams: Codable {
            let contractId: String
            let entryPoint: Int
            let args: String
        }
        
        struct Response: Codable {
            let result: UInt64
            
            init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let stringResult: String = try container.decode(forKey: .result)
                guard let result = UInt64(stringResult) else {
                    throw WalletError.failedToParseNetworkResponse
                }
                self.result = result
            }
        }
    }
}

extension KoinosMethod {
    enum GetAccountRC {
        static let method = "chain.get_account_rc"
        
        struct RequestParams: Codable {
            let account: String
        }
        
        struct Response: Codable {
            let rc: UInt64
        }
    }
}

extension KoinosMethod {
    enum GetAccountNonce {
        static let method = "chain.get_account_nonce"
        
        struct RequestParams: Codable {
            let account: String
        }
        
        struct Response: Codable {
            let nonce: UInt64
            
            init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let stringNonce: String = try container.decode(forKey: .nonce)
                guard let data = Data(base64Encoded: stringNonce),
                      let nonce = UInt64(data: data)
                else {
                    throw WalletError.failedToParseNetworkResponse
                }
                self.nonce = nonce
            }
        }
    }
}

extension KoinosMethod {
    enum GetResourceLimits {
        static let method = "chain.get_resource_limits"
        
        struct Response: Codable {
            let resourceLimitData: KoinosChain.ResourceLimitData
        }
    }
}

extension KoinosMethod {
    enum SubmitTransaction {
        static let method = "chain.submit_transaction"
        
        struct RequestParams: Codable {
            let transaction: KoinosProtocol.Transaction
            let broadcast: Bool
        }
        
        struct Response: Codable {
            let receipt: KoinosProtocol.TransactionReceipt
        }
    }
    
}
