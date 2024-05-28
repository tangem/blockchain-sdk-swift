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
            let result: String?
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
                let base64EncodedNonce: String = try container.decode(forKey: .nonce)
                guard let stringNonce = base64EncodedNonce.base64Decoded(),
                      let nonce = UInt64(stringNonce)
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
